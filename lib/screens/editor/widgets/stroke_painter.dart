import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../models/brush.dart';
import '../../../models/frame.dart';
import '../../../models/layer.dart';
import '../../../models/stroke.dart';

/// One adjacent frame to render as onion skin, with the tint + opacity to use.
class OnionLayerSpec {
  const OnionLayerSpec(this.frame, this.tint, this.opacity);
  final Frame frame;
  final Color tint;
  final double opacity;
}

/// Renders the drawing surface: a white paper background, any onion-skin
/// frames, the current frame's layers, and the in-progress live stroke.
///
/// Brush character comes from [_configureBrush], which maps each [BrushType] to
/// stroke width, alpha build-up and edge softness.
class StrokePainter extends CustomPainter {
  StrokePainter({
    required this.frame,
    required this.onion,
    required this.liveStroke,
    required this.background,
    required this.repaint,
  }) : super(repaint: repaint);

  final Frame frame;
  final List<OnionLayerSpec> onion;
  final Stroke? liveStroke;
  final Color background;
  final Listenable repaint;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    // Paper.
    canvas.drawRect(bounds, Paint()..color = background);

    // Onion skin (behind current frame).
    for (final OnionLayerSpec spec in onion) {
      _paintFrame(
        canvas,
        bounds,
        spec.frame,
        tint: spec.tint,
        extraOpacity: spec.opacity,
      );
    }

    // Current frame.
    _paintFrame(canvas, bounds, frame);

    // Live stroke on top of the active content.
    if (liveStroke != null && liveStroke!.points.isNotEmpty) {
      _paintStroke(canvas, bounds, liveStroke!);
    }
  }

  void _paintFrame(
    Canvas canvas,
    Rect bounds,
    Frame frame, {
    Color? tint,
    double extraOpacity = 1,
  }) {
    for (final Layer layer in frame.layers) {
      if (layer.hidden) continue;
      final double opacity = (layer.opacity * extraOpacity).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final Paint layerPaint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity);
      if (tint != null) {
        layerPaint.colorFilter = ColorFilter.mode(tint, BlendMode.srcATop);
      }
      // Each layer gets its own compositing group so eraser strokes only clear
      // within the layer and layer opacity/tint apply uniformly.
      canvas.saveLayer(bounds, layerPaint);
      for (final Stroke stroke in layer.strokes) {
        _paintStroke(canvas, bounds, stroke);
      }
      canvas.restore();
    }
  }

  void _paintStroke(Canvas canvas, Rect bounds, Stroke stroke) {
    if (stroke.fill) {
      final Paint p = Paint()..color = stroke.color;
      canvas.drawRect(bounds, p);
      return;
    }
    if (stroke.points.isEmpty) return;

    final BrushSettings b = stroke.brush;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    _configureBrush(paint, b, stroke.color, stroke.erase);

    if (b.type == BrushType.pixel) {
      _paintPixel(canvas, stroke);
      return;
    }

    if (stroke.points.length == 1) {
      // A dot.
      final Paint dot = Paint()
        ..color = paint.color
        ..maskFilter = paint.maskFilter
        ..blendMode = paint.blendMode;
      canvas.drawCircle(stroke.points.first, b.size / 2, dot);
      return;
    }

    final Path path = _buildPath(stroke.points, b.smoothing);
    canvas.drawPath(path, paint);
  }

  void _paintPixel(Canvas canvas, Stroke stroke) {
    final double grid = stroke.brush.size.clamp(1, 256);
    final Paint paint = Paint()
      ..isAntiAlias = false
      ..color = stroke.color.withValues(alpha: stroke.brush.opacity);
    if (stroke.erase) paint.blendMode = BlendMode.clear;
    final Set<int> seen = <int>{};
    for (final Offset p in stroke.points) {
      final double gx = (p.dx / grid).floorToDouble() * grid;
      final double gy = (p.dy / grid).floorToDouble() * grid;
      final int key = (gx.toInt() * 100003) ^ gy.toInt();
      if (!seen.add(key)) continue;
      canvas.drawRect(Rect.fromLTWH(gx, gy, grid, grid), paint);
    }
  }

  /// Applies the per-brush-type paint character.
  void _configureBrush(Paint paint, BrushSettings b, Color color, bool erase) {
    paint.strokeWidth = b.size;
    double alpha = b.opacity;
    double softness = (1 - b.hardness); // 0 = crisp, 1 = very soft.

    switch (b.type) {
      case BrushType.pencil:
        softness *= 0.15;
      case BrushType.ink:
        softness *= 0.05;
      case BrushType.marker:
        alpha *= 0.7;
        paint.strokeCap = StrokeCap.square;
        softness *= 0.2;
      case BrushType.airbrush:
        alpha *= 0.35;
        softness = softness.clamp(0.4, 1.0);
      case BrushType.watercolor:
        alpha *= 0.45;
        softness = softness.clamp(0.5, 1.0);
      case BrushType.pixel:
        break;
      case BrushType.chalk:
        alpha *= 0.85;
        softness = (softness + 0.2).clamp(0.0, 1.0);
      case BrushType.custom:
        break;
    }

    paint.color = color.withValues(alpha: alpha.clamp(0.0, 1.0));

    final double sigma = b.size * 0.5 * softness;
    if (sigma > 0.4) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    }
    if (erase) {
      paint.blendMode = BlendMode.clear;
    }
  }

  /// Builds a smoothed path through [points]. With smoothing > 0 it uses
  /// Catmull-Rom-style midpoints and quadratic segments; otherwise straight
  /// line segments.
  Path _buildPath(List<Offset> points, double smoothing) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    if (smoothing <= 0.01 || points.length < 3) {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }
    for (int i = 1; i < points.length - 1; i++) {
      final Offset mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}

/// Utility: rasterise a frame to a [ui.Image] at [size] for thumbnails/exports.
Future<ui.Image> rasterizeFrame(
  Frame frame,
  Size size,
  Color background,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final StrokePainter painter = StrokePainter(
    frame: frame,
    onion: const <OnionLayerSpec>[],
    liveStroke: null,
    background: background,
    repaint: const AlwaysStoppedAnimation<double>(0),
  );
  painter.paint(canvas, size);
  final ui.Picture picture = recorder.endRecording();
  return picture.toImage(size.width.round(), size.height.round());
}
