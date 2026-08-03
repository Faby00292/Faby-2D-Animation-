import 'package:flutter/material.dart';

/// The distinct brush engines the drawing canvas can render.
///
/// Each type maps to a different combination of stroke paint, edge softness and
/// alpha build-up in [StrokePainter]. [BrushType.custom] is a user-tunable
/// brush whose behaviour is driven entirely by [BrushSettings].
enum BrushType {
  pencil('Pencil', Icons.edit),
  ink('Ink', Icons.brush),
  marker('Marker', Icons.format_color_fill),
  airbrush('Airbrush', Icons.blur_on),
  watercolor('Watercolor', Icons.water_drop),
  pixel('Pixel', Icons.grid_on),
  chalk('Chalk', Icons.gesture),
  custom('Custom', Icons.tune);

  const BrushType(this.label, this.icon);

  final String label;
  final IconData icon;

  static BrushType fromName(String? name) => BrushType.values.firstWhere(
        (BrushType b) => b.name == name,
        orElse: () => BrushType.pencil,
      );
}

/// The active drawing tools selectable from the left toolbar. Some tools
/// (text, lasso) are scaffolded for a later iteration.
enum ToolType {
  brush('Brush', Icons.brush),
  pencil('Pencil', Icons.edit),
  eraser('Eraser', Icons.auto_fix_normal),
  fill('Fill', Icons.format_color_fill),
  text('Text', Icons.title),
  blur('Blur', Icons.blur_on),
  lasso('Lasso', Icons.gesture);

  const ToolType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Fully serializable brush configuration. Ranges are normalised 0..1 except
/// [size] which is a stroke width in canvas pixels.
class BrushSettings {
  BrushSettings({
    this.type = BrushType.pencil,
    this.size = 12,
    this.opacity = 1.0,
    this.hardness = 0.9,
    this.spacing = 0.1,
    this.smoothing = 0.4,
  });

  BrushType type;
  double size;
  double opacity;
  double hardness;
  double spacing;
  double smoothing;

  BrushSettings copyWith({
    BrushType? type,
    double? size,
    double? opacity,
    double? hardness,
    double? spacing,
    double? smoothing,
  }) {
    return BrushSettings(
      type: type ?? this.type,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      hardness: hardness ?? this.hardness,
      spacing: spacing ?? this.spacing,
      smoothing: smoothing ?? this.smoothing,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'size': size,
        'opacity': opacity,
        'hardness': hardness,
        'spacing': spacing,
        'smoothing': smoothing,
      };

  factory BrushSettings.fromJson(Map<String, dynamic> json) => BrushSettings(
        type: BrushType.fromName(json['type'] as String?),
        size: (json['size'] as num?)?.toDouble() ?? 12,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        hardness: (json['hardness'] as num?)?.toDouble() ?? 0.9,
        spacing: (json['spacing'] as num?)?.toDouble() ?? 0.1,
        smoothing: (json['smoothing'] as num?)?.toDouble() ?? 0.4,
      );
}
