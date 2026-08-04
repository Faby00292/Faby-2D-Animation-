import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/editor_controller.dart';
import '../state/settings_store.dart';
import 'drawing_painter.dart';
import 'frame_sampler.dart';

/// The zoomable drawing surface.
///
/// Wraps the painted page in an [InteractiveViewer] for pinch-zoom (up to
/// 6400%) and pan. Single-finger input draws via a raw [Listener] (which sees
/// pointer events regardless of the viewer's gesture recognizers); a second
/// finger cancels the in-progress stroke and hands off to pinch-zoom. When the
/// controller is in eyedropper mode, a tap samples a color instead.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.transformationController,
  });

  final EditorController controller;
  final TransformationController transformationController;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

/// Builds the tinted onion-skin ghosts for the current editor state, ordered
/// farthest-first so nearer neighbours render on top.
List<OnionSkinFrame> _buildOnionFrames(EditorController controller) {
  if (!controller.onionEnabled) return const [];
  final frames = controller.project.frames;
  final current = controller.currentFrameIndex;
  final count = controller.onionFrameCount;
  final specs = <OnionSkinFrame>[];

  double opacityFor(int distance) =>
      (controller.onionOpacity * (count - distance + 1) / count)
          .clamp(0.0, 1.0);

  if (controller.onionShowPrevious) {
    for (var d = count; d >= 1; d--) {
      final idx = current - d;
      if (idx < 0) continue;
      specs.add(OnionSkinFrame(
        frame: frames[idx],
        color: controller.onionPrevColor,
        opacity: opacityFor(d),
      ));
    }
  }
  if (controller.onionShowNext) {
    for (var d = count; d >= 1; d--) {
      final idx = current + d;
      if (idx >= frames.length) continue;
      specs.add(OnionSkinFrame(
        frame: frames[idx],
        color: controller.onionNextColor,
        opacity: opacityFor(d),
      ));
    }
  }
  return specs;
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  int _pointers = 0;
  bool _drawing = false;

  Size _fit(Size available, double aspect) {
    final w = available.width;
    final h = available.height;
    if (w <= 0 || h <= 0) return const Size(1, 1);
    if (w / h > aspect) {
      return Size(h * aspect, h);
    }
    return Size(w, w / aspect);
  }

  Future<void> _pickColor(Offset canvasPoint) async {
    final controller = widget.controller;
    final settings = context.read<SettingsStore>();
    final color = await sampleFrameColor(
      frame: controller.currentFrame,
      formatSize: Size(
        controller.project.format.width.toDouble(),
        controller.project.format.height.toDouble(),
      ),
      canvasPoint: canvasPoint,
    );
    controller.setColor(color);
    controller.setEyedropperMode(false);
    settings.addColorToHistory(color);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final format = controller.project.format;
    final formatSize = Size(format.width.toDouble(), format.height.toDouble());

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = Size(constraints.maxWidth, constraints.maxHeight);
        final display = _fit(
          Size(available.width - 32, available.height - 32),
          format.aspectRatio,
        );
        final scale = display.width / formatSize.width;

        Offset toCanvas(Offset local) => local / scale;

        return InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: 0.25,
          maxScale: 64,
          panEnabled: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Center(
            child: Listener(
              onPointerDown: (event) {
                if (controller.eyedropperMode) {
                  _pickColor(toCanvas(event.localPosition));
                  return;
                }
                _pointers++;
                if (_pointers == 1) {
                  _drawing = true;
                  controller.startStroke(toCanvas(event.localPosition));
                } else if (_drawing) {
                  _drawing = false;
                  controller.cancelStroke();
                }
              },
              onPointerMove: (event) {
                if (_pointers == 1 && _drawing) {
                  controller.extendStroke(toCanvas(event.localPosition));
                }
              },
              onPointerUp: (event) {
                if (_pointers > 0) _pointers--;
                if (_pointers == 0 && _drawing) {
                  _drawing = false;
                  controller.endStroke();
                }
              },
              onPointerCancel: (event) {
                if (_pointers > 0) _pointers--;
                if (_pointers == 0 && _drawing) {
                  _drawing = false;
                  controller.endStroke();
                }
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: display.width,
                  height: display.height,
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => CustomPaint(
                      size: display,
                      painter: DrawingPainter(
                        frame: controller.currentFrame,
                        formatSize: formatSize,
                        onionFrames: _buildOnionFrames(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
