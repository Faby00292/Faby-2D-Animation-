import 'brush_type.dart';

/// A user-saved custom brush: a named bundle of brush settings that can be
/// re-applied later.
class BrushPreset {
  BrushPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.opacity,
    required this.hardness,
    required this.spacing,
  });

  final String id;
  String name;
  BrushType type;
  double size;
  double opacity;
  double hardness;
  double spacing;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'size': size,
        'opacity': opacity,
        'hardness': hardness,
        'spacing': spacing,
      };

  factory BrushPreset.fromJson(Map<String, dynamic> json) => BrushPreset(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Brush',
        type: BrushType.fromName(json['type'] as String?),
        size: (json['size'] as num?)?.toDouble() ?? 12,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        hardness: (json['hardness'] as num?)?.toDouble() ?? 1.0,
        spacing: (json['spacing'] as num?)?.toDouble() ?? 0.1,
      );
}
