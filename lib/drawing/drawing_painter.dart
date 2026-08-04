import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/brush_type.dart';
import '../models/frame.dart';
import '../models/stroke.dart';

/// A neighbouring frame rendered as a tinted onion-skin ghost beneath the
/// current frame.
class OnionSkinFrame {
  const OnionSkinFrame({
    required this.frame,
    required this.color,
    required this.opacity,
  });

  final Frame frame;
  final Color color;
  final double opacity;
}

/// Renders a [Frame]'s visible layers (bottom to top) onto the canvas.
///
/// Strokes are stored in canvas/format coordinates, so the painter scales the
/// canvas to the given paint [size]; the same painter is reused for full-size
/// editing and small timeline thumbnails. Each [BrushType] renders with a
/// distinct style — continuous paths for pencil/ink/marker, stamped dabs for
/// airbrush/watercolor/chalk/pixel. Optional [onionFrames] are drawn as tinted
/// ghosts beneath the current frame (never in thumbnails).
class DrawingPainter extends CustomPainter {
  DrawingPainter({
    required this.frame,
    required this.formatSize,
    this.onionFrames = const [],
    super.repaint,
  });

  final Frame frame;
  final Size formatSize;
  final List<OnionSkinFrame> onionFrames;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / formatSize.width,
      size.height / formatSize.height,
    );

    final pageRect = Offset.zero & formatSize;
    canvas.drawRect(pageRect, Paint()..color = Colors.white);

    // Onion skins: draw each neighbour's strokes (no page background), tinted
    // to a single color via a src-atop color filter, at reduced opacity.
    for (final onion in onionFrames) {
      canvas.saveLayer(
        pageRect,
        Paint()..color = Colors.white.withValues(alpha: onion.opacity),
      );
      canvas.saveLayer(
        pageRect,
        Paint()..colorFilter = ColorFilter.mode(onion.color, BlendMode.srcATop),
      );
      _paintContent(canvas, onion.frame);
      canvas.restore();
      canvas.restore();
    }

    _paintContent(canvas, frame);

    canvas.restore();
  }

  /// Paints a frame's visible layers and strokes (no page background).
  void _paintContent(Canvas canvas, Frame source) {
    final pageRect = Offset.zero & formatSize;
    for (final layer in source.layers) {
      if (!layer.isVisible) continue;
      // Isolate each layer so eraser strokes only cut within their own layer.
      canvas.saveLayer(
        pageRect,
        Paint()..color = Colors.white.withValues(alpha: layer.opacity),
      );
      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke);
      }
      canvas.restore();
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    if (stroke.isEraser) {
      _drawContinuous(canvas, stroke, eraser: true);
    } else if (stroke.brushType.isStamp) {
      _drawStamped(canvas, stroke);
    } else {
      _drawContinuous(canvas, stroke, eraser: false);
    }
  }

  // --- Continuous path brushes (pencil / ink / marker / custom / eraser) ---
  void _drawContinuous(Canvas canvas, Stroke stroke, {required bool eraser}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width
      ..color = eraser
          ? Colors.black
          : stroke.color.withValues(alpha: stroke.opacity);

    if (eraser) {
      paint.blendMode = BlendMode.clear;
    } else if (stroke.hardness < 1.0) {
      final sigma = (1.0 - stroke.hardness) * stroke.width * 0.5;
      if (sigma > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
      }
    }

    if (stroke.points.length == 1) {
      final dot = Paint()
        ..style = PaintingStyle.fill
        ..color = paint.color
        ..blendMode = paint.blendMode
        ..maskFilter = paint.maskFilter;
      canvas.drawCircle(stroke.points.first, stroke.width / 2, dot);
      return;
    }

    final path = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (var i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  // --- Stamped brushes (airbrush / watercolor / chalk / pixel) ---
  void _drawStamped(Canvas canvas, Stroke stroke) {
    final rnd = math.Random(stroke.seed);
    final radius = stroke.width / 2;
    final step = math.max(1.0, stroke.width * stroke.spacing);
    for (final point in _dabPositions(stroke.points, step)) {
      _stampDab(canvas, stroke, point, radius, rnd);
    }
  }

  /// Evenly spaced points along the poly-line at [step] intervals.
  List<Offset> _dabPositions(List<Offset> points, double step) {
    if (points.length == 1) return [points.first];
    final out = <Offset>[points.first];
    var carry = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final seg = (b - a).distance;
      if (seg == 0) continue;
      var d = step - carry;
      while (d <= seg) {
        final t = d / seg;
        out.add(Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t));
        d += step;
      }
      carry = seg - (d - step);
    }
    return out;
  }

  void _stampDab(
    Canvas canvas,
    Stroke stroke,
    Offset center,
    double radius,
    math.Random rnd,
  ) {
    final color = stroke.color;
    switch (stroke.brushType) {
      case BrushType.pixel:
        final grid = math.max(1.0, stroke.width);
        final gx = (center.dx / grid).floor() * grid;
        final gy = (center.dy / grid).floor() * grid;
        canvas.drawRect(
          Rect.fromLTWH(gx, gy, grid, grid),
          Paint()
            ..isAntiAlias = false
            ..color = color.withValues(alpha: stroke.opacity),
        );
        break;

      case BrushType.airbrush:
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color.withValues(alpha: stroke.opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7),
        );
        break;

      case BrushType.watercolor:
        final jitter = Offset(
          (rnd.nextDouble() - 0.5) * radius * 0.5,
          (rnd.nextDouble() - 0.5) * radius * 0.5,
        );
        final r = radius * (0.8 + rnd.nextDouble() * 0.5);
        final a = (stroke.opacity * (0.6 + rnd.nextDouble() * 0.6)).clamp(0.0, 1.0);
        canvas.drawCircle(
          center + jitter,
          r,
          Paint()
            ..color = color.withValues(alpha: a)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
        );
        break;

      case BrushType.chalk:
        const grains = 6;
        final grainRadius = math.max(0.6, stroke.width * 0.08);
        for (var g = 0; g < grains; g++) {
          final off = Offset(
            (rnd.nextDouble() - 0.5) * stroke.width,
            (rnd.nextDouble() - 0.5) * stroke.width,
          );
          if (off.distance > radius) continue;
          final a = (stroke.opacity * (0.3 + rnd.nextDouble() * 0.7))
              .clamp(0.0, 1.0);
          canvas.drawCircle(
            center + off,
            grainRadius,
            Paint()..color = color.withValues(alpha: a),
          );
        }
        break;

      default:
        final paint = Paint()..color = color.withValues(alpha: stroke.opacity);
        if (stroke.hardness < 1.0) {
          paint.maskFilter =
              MaskFilter.blur(BlurStyle.normal, radius * (1 - stroke.hardness));
        }
        canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
