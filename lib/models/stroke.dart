import 'package:flutter/material.dart';

import 'brush_type.dart';

/// A single freehand stroke, stored in canvas (format-pixel) coordinates so it
/// renders consistently at any zoom level or thumbnail size.
class Stroke {
  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.hardness,
    required this.brushType,
    required this.spacing,
    required this.seed,
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

  /// The brush engine used to render this stroke.
  final BrushType brushType;

  /// Dab spacing (fraction of width) for stamped brush types.
  final double spacing;

  /// Deterministic seed for stamped brushes (chalk/watercolor jitter).
  final int seed;

  /// When true the stroke erases rather than paints.
  final bool isEraser;

  Map<String, dynamic> toJson() => {
        'pts': [
          for (final p in points) [p.dx, p.dy],
        ],
        'color': color.toARGB32(),
        'width': width,
        'opacity': opacity,
        'hardness': hardness,
        'type': brushType.name,
        'spacing': spacing,
        'seed': seed,
        'eraser': isEraser,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        points: [
          for (final p in (json['pts'] as List))
            Offset(
              ((p as List)[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ),
        ],
        color: Color((json['color'] as num).toInt()),
        width: (json['width'] as num).toDouble(),
        opacity: (json['opacity'] as num).toDouble(),
        hardness: (json['hardness'] as num).toDouble(),
        brushType: BrushType.fromName(json['type'] as String?),
        spacing: (json['spacing'] as num?)?.toDouble() ?? 0.1,
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        isEraser: json['eraser'] as bool? ?? false,
      );
}
