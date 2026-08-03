import 'dart:ui';

import 'brush.dart';

/// A single drawn stroke: an ordered list of points plus the brush settings and
/// colour it was painted with. Eraser strokes set [erase] so the painter can
/// use [BlendMode.clear] against the layer.
class Stroke {
  Stroke({
    required this.points,
    required this.color,
    required this.brush,
    this.erase = false,
    this.fill = false,
  });

  final List<Offset> points;
  final Color color;
  final BrushSettings brush;
  final bool erase;

  /// When true this stroke paints a solid fill of [points] as a bounding rect
  /// (used by the Fill tool) rather than a brush path.
  final bool fill;

  Map<String, dynamic> toJson() => <String, dynamic>{
        // Points are flattened to [x0,y0,x1,y1,...] to keep the JSON compact
        // for projects with thousands of frames.
        'pts': <double>[
          for (final Offset p in points) ...<double>[p.dx, p.dy],
        ],
        'color': color.toARGB32(),
        'brush': brush.toJson(),
        'erase': erase,
        'fill': fill,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['pts'] as List<dynamic>?) ?? <dynamic>[];
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i + 1 < raw.length; i += 2) {
      pts.add(Offset((raw[i] as num).toDouble(), (raw[i + 1] as num).toDouble()));
    }
    return Stroke(
      points: pts,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      brush: BrushSettings.fromJson(
        (json['brush'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      erase: json['erase'] as bool? ?? false,
      fill: json['fill'] as bool? ?? false,
    );
  }

  Stroke copy() => Stroke(
        points: List<Offset>.from(points),
        color: color,
        brush: brush.copyWith(),
        erase: erase,
        fill: fill,
      );
}
