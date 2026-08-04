import 'package:flutter/material.dart';

/// A single freehand stroke, stored in canvas (format-pixel) coordinates so it
/// renders consistently at any zoom level or thumbnail size.
class Stroke {
  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.hardness,
    this.isEraser = false,
  });

  /// Poly-line points in canvas coordinates. Grows while the stroke is drawn.
  final List<Offset> points;

  final Color color;

  /// Stroke width in canvas pixels.
  final double width;

  /// 0..1 opacity applied to [color].
  final double opacity;

  /// 0..1 edge hardness (1 = crisp, 0 = very soft/blurred).
  final double hardness;

  /// When true the stroke erases rather than paints.
  final bool isEraser;
}
