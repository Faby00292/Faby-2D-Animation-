import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../models/brush.dart';
import '../../../models/stroke.dart';
import '../../../state/editor_controller.dart';
import '../../../state/settings_controller.dart';
import 'stroke_painter.dart';

/// The interactive drawing surface.
///
/// Rolls its own pan/zoom (rather than [InteractiveViewer]) so a single pointer
/// draws while two pointers pinch-zoom/pan — the split gesture handling a paint
/// app needs. Zoom ranges 10%–6400%; a reset chip appears whenever zoom ≠ 100%.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.settings,
  });

  final EditorController controller;
  final SettingsController settings;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  static const double _minScale = 0.1;
  static const double _maxScale = 64.0; // 6400%

  Matrix4 _transform = Matrix4.identity();
  bool _initialized = false;

  final Map<int, Offset> _pointers = <int, Offset>{};
  List<Offset>? _livePoints;
  Stroke? _liveStroke;

  Offset? _prevFocal;
  double? _prevDist;

  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  Size get _canvasSize => widget.controller.project.format.size;
  double get _scale => _transform.getMaxScaleOnAxis();

  @override
  void dispose() {
    _repaint.dispose();
    super.dispose();
  }

  void _fit(Size viewport) {
    final Size canvas = _canvasSize;
    final double scale = (viewport.width / canvas.width)
        .clamp(_minScale, _maxScale)
        .toDouble();
    final double fitScale = (viewport.height / canvas.height) < scale
        ? viewport.height / canvas.height
        : scale;
    final double s = (fitScale * 0.92).clamp(_minScale, _maxScale).toDouble();
    final double tx = (viewport.width - canvas.width * s) / 2;
    final double ty = (viewport.height - canvas.height * s) / 2;
    _transform = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(s, s);
  }

  void _resetTo100(Size viewport) {
    final Size canvas = _canvasSize;
    final double tx = (viewport.width - canvas.width) / 2;
    final double ty = (viewport.height - canvas.height) / 2;
    setState(() {
      _transform = Matrix4.identity()..translate(tx, ty);
    });
  }

  Offset _toScene(Offset viewportPoint) {
    final Matrix4 inverse = Matrix4.inverted(_transform);
    final Vector3 v =
        inverse.transform3(Vector3(viewportPoint.dx, viewportPoint.dy, 0));
    return Offset(v.x, v.y);
  }

  bool _canDraw(PointerDeviceKind kind) {
    switch (widget.settings.inputMethod) {
      case InputMethod.finger:
        return kind == PointerDeviceKind.touch ||
            kind == PointerDeviceKind.mouse;
      case InputMethod.stylus:
        return kind == PointerDeviceKind.stylus ||
            kind == PointerDeviceKind.invertedStylus;
      case InputMethod.both:
        return true;
    }
  }

  // ---- Pointer handling ------------------------------------------------------

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;

    if (_pointers.length >= 2) {
      // Switched to transform gesture: abandon any single-finger stroke.
      _cancelLiveStroke();
      _prevFocal = _focalPoint();
      _prevDist = _pointerDistance();
      return;
    }

    final EditorController c = widget.controller;
    if (!_canDraw(e.kind)) return;

    final Offset scene = _toScene(e.localPosition);

    if (c.eyedropperActive) {
      _sampleColor(scene);
      return;
    }
    if (c.tool == ToolType.fill) {
      c.fillActiveLayer(_canvasSize);
      return;
    }
    if (c.tool == ToolType.text || c.tool == ToolType.lasso) {
      _showComingSoon(c.tool.label);
      return;
    }
    _startStroke(scene);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;

    if (_pointers.length >= 2) {
      _handleTransform();
      return;
    }
    if (_livePoints == null) return;
    final Offset scene = _toScene(e.localPosition);
    _livePoints!.add(scene);
    _repaint.value++;
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    _endTransformIfNeeded();
    if (_pointers.isEmpty) _commitLiveStroke();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _endTransformIfNeeded();
    if (_pointers.isEmpty) _commitLiveStroke();
  }

  void _endTransformIfNeeded() {
    if (_pointers.length < 2) {
      _prevFocal = null;
      _prevDist = null;
    }
  }

  Offset _focalPoint() {
    final List<Offset> pts = _pointers.values.toList();
    return (pts[0] + pts[1]) / 2;
  }

  double _pointerDistance() {
    final List<Offset> pts = _pointers.values.toList();
    return (pts[0] - pts[1]).distance;
  }

  void _handleTransform() {
    final Offset focal = _focalPoint();
    final double dist = _pointerDistance();
    if (_prevFocal == null || _prevDist == null || _prevDist == 0) {
      _prevFocal = focal;
      _prevDist = dist;
      return;
    }
    double factor = dist / _prevDist!;
    final double newScale = (_scale * factor).clamp(_minScale, _maxScale);
    factor = newScale / _scale;

    final Offset translation = focal - _prevFocal!;

    final Matrix4 next = Matrix4.identity()
      ..translate(focal.dx, focal.dy)
      ..scale(factor, factor)
      ..translate(-focal.dx, -focal.dy)
      ..translate(translation.dx, translation.dy);

    setState(() {
      _transform = next * _transform;
    });

    _prevFocal = focal;
    _prevDist = dist;
  }

  // ---- Stroke lifecycle ------------------------------------------------------

  void _startStroke(Offset scene) {
    final EditorController c = widget.controller;
    if (!c.activeLayer.isEditable) return;
    final bool erase = c.tool == ToolType.eraser;
    _livePoints = <Offset>[scene];
    _liveStroke = Stroke(
      points: _livePoints!,
      color: c.color,
      brush: c.brush.copyWith(),
      erase: erase,
    );
    _repaint.value++;
  }

  void _cancelLiveStroke() {
    _livePoints = null;
    _liveStroke = null;
    _repaint.value++;
  }

  void _commitLiveStroke() {
    final Stroke? s = _liveStroke;
    final List<Offset>? pts = _livePoints;
    _liveStroke = null;
    _livePoints = null;
    if (s == null || pts == null || pts.isEmpty) return;
    widget.controller.commitStroke(
      Stroke(
        points: List<Offset>.from(pts),
        color: s.color,
        brush: s.brush,
        erase: s.erase,
      ),
    );
    _repaint.value++;
  }

  Future<void> _sampleColor(Offset scene) async {
    final EditorController c = widget.controller;
    try {
      final ui.Image image = await rasterizeFrame(
        c.currentFrame,
        _canvasSize,
        Colors.white,
      );
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return;
      final int x = scene.dx.round().clamp(0, image.width - 1);
      final int y = scene.dy.round().clamp(0, image.height - 1);
      final int offset = (y * image.width + x) * 4;
      final int r = data.getUint8(offset);
      final int g = data.getUint8(offset + 1);
      final int b = data.getUint8(offset + 2);
      c.setColor(Color.fromARGB(255, r, g, b));
    } finally {
      c.setEyedropper(false);
    }
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label tool is coming in a later update.')),
    );
  }

  // ---- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewport =
            Size(constraints.maxWidth, constraints.maxHeight);
        if (!_initialized) {
          _fit(viewport);
          _initialized = true;
        }

        final bool notAt100 = (_scale - 1).abs() > 0.001;

        return ClipRect(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: Transform(
                    transform: _transform,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: _canvasSize.width,
                      maxHeight: _canvasSize.height,
                      child: SizedBox(
                        width: _canvasSize.width,
                        height: _canvasSize.height,
                        child: _CanvasSurface(
                          controller: widget.controller,
                          liveStrokeGetter: () => _liveStroke,
                          repaint: _repaint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: notAt100 ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !notAt100,
                    child: _ZoomChip(
                      scale: _scale,
                      onReset: () => _resetTo100(viewport),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Paints the current frame + onion skin + live stroke, repainting on either
/// the editor controller (committed changes) or the live-stroke notifier.
class _CanvasSurface extends StatelessWidget {
  const _CanvasSurface({
    required this.controller,
    required this.liveStrokeGetter,
    required this.repaint,
  });

  final EditorController controller;
  final Stroke? Function() liveStrokeGetter;
  final Listenable repaint;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[controller, repaint]),
      builder: (BuildContext context, _) {
        return CustomPaint(
          isComplex: true,
          size: controller.project.format.size,
          painter: StrokePainter(
            frame: controller.currentFrame,
            onion: _buildOnion(controller),
            liveStroke: liveStrokeGetter(),
            background: Colors.white,
            repaint: repaint,
          ),
        );
      },
    );
  }

  List<OnionLayerSpec> _buildOnion(EditorController c) {
    if (!c.onionSkin.enabled) return const <OnionLayerSpec>[];
    final OnionSkinSettings s = c.onionSkin;
    final List<OnionLayerSpec> specs = <OnionLayerSpec>[];
    for (int i = s.prevFrames; i >= 1; i--) {
      final int idx = c.frameIndex - i;
      if (idx < 0) continue;
      final double fade = s.opacity * (1 - (i - 1) / (s.prevFrames + 1));
      specs.add(OnionLayerSpec(c.project.frames[idx], s.prevColor, fade));
    }
    for (int i = 1; i <= s.nextFrames; i++) {
      final int idx = c.frameIndex + i;
      if (idx >= c.project.frames.length) break;
      final double fade = s.opacity * (1 - (i - 1) / (s.nextFrames + 1));
      specs.add(OnionLayerSpec(c.project.frames[idx], s.nextColor, fade));
    }
    return specs;
  }
}

class _ZoomChip extends StatelessWidget {
  const _ZoomChip({required this.scale, required this.onReset});

  final double scale;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onReset,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.center_focus_strong,
                  size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${(scale * 100).round()}% · Reset',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
