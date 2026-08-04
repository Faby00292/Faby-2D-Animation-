import 'package:flutter/material.dart';

import '../models/frame.dart';
import '../models/stroke.dart';

/// Renders a [Frame]'s visible layers (bottom to top) onto the canvas.
///
/// Strokes are stored in canvas/format coordinates, so the painter scales the
/// canvas to the given paint [size]; the same painter is reused for full-size
/// editing and small timeline thumbnails.
class DrawingPainter extends CustomPainter {
  DrawingPainter({
    required this.frame,
    required this.formatSize,
    super.repaint,
  });

  final Frame frame;
  final Size formatSize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / formatSize.width,
      size.height / formatSize.height,
    );

    final pageRect = Offset.zero & formatSize;
    canvas.drawRect(pageRect, Paint()..color = Colors.white);

    for (final layer in frame.layers) {
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

    canvas.restore();
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width
      ..color = stroke.isEraser
          ? Colors.black
          : stroke.color.withValues(alpha: stroke.opacity);

    if (stroke.isEraser) {
      paint.blendMode = BlendMode.clear;
    }

    if (stroke.hardness < 1.0) {
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

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
