import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular hue/saturation picker. Hue maps to the angle, saturation to the
/// radius; brightness (value) is supplied externally and shading the wheel.
class HsvWheel extends StatelessWidget {
  const HsvWheel({
    super.key,
    required this.color,
    required this.onChanged,
    this.size = 220,
  });

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;
  final double size;

  void _handle(Offset local) {
    final double r = size / 2;
    final Offset c = Offset(r, r);
    final Offset v = local - c;
    double sat = (v.distance / r).clamp(0.0, 1.0);
    double hue = (math.atan2(v.dy, v.dx) * 180 / math.pi);
    if (hue < 0) hue += 360;
    onChanged(color.withHue(hue).withSaturation(sat));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanDown: (DragDownDetails d) => _handle(d.localPosition),
        onPanUpdate: (DragUpdateDetails d) => _handle(d.localPosition),
        child: CustomPaint(
          painter: _WheelPainter(color),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.color);

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset center = Offset(r, r);

    // Hue sweep.
    final Paint hue = Paint()
      ..shader = SweepGradient(
        colors: <Color>[
          for (int i = 0; i <= 360; i += 60)
            HSVColor.fromAHSV(1, i.toDouble() % 360, 1, 1).toColor(),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, hue);

    // Saturation: white in the centre fading out.
    final Paint sat = Paint()
      ..shader = RadialGradient(
        colors: <Color>[Colors.white, Colors.white.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, sat);

    // Value: darken uniformly.
    if (color.value < 1) {
      final Paint dark = Paint()
        ..color = Colors.black.withValues(alpha: 1 - color.value);
      canvas.drawCircle(center, r, dark);
    }

    // Selection indicator.
    final double angle = color.hue * math.pi / 180;
    final double dist = color.saturation * r;
    final Offset sel =
        center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
    canvas.drawCircle(
      sel,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(sel, 8, Paint()..color = color.toColor());
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.color != color;
}
