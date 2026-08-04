import 'package:flutter/material.dart';

/// Default brush parameters applied when a [BrushType] is selected.
class BrushDefaults {
  const BrushDefaults({
    required this.size,
    required this.opacity,
    required this.hardness,
    required this.spacing,
  });

  final double size;
  final double opacity;
  final double hardness;
  final double spacing;
}

/// The available brush engines. Each renders strokes with a distinct feel.
///
/// [pencil], [ink], [marker] paint continuous strokes; [airbrush], [watercolor],
/// [chalk], [pixel] stamp dabs along the path. [custom] is used by saved
/// user presets.
enum BrushType {
  pencil('Pencil', Icons.create),
  ink('Ink', Icons.brush),
  marker('Marker', Icons.border_color),
  airbrush('Airbrush', Icons.blur_on),
  watercolor('Watercolor', Icons.water_drop),
  pixel('Pixel', Icons.grid_on),
  chalk('Chalk', Icons.texture),
  custom('Custom', Icons.tune);

  const BrushType(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Whether strokes are rendered as dabs stamped along the path.
  bool get isStamp =>
      this == airbrush ||
      this == watercolor ||
      this == chalk ||
      this == pixel;

  /// Sensible starting parameters for this brush.
  BrushDefaults get defaults {
    switch (this) {
      case pencil:
        return const BrushDefaults(
            size: 6, opacity: 1.0, hardness: 0.9, spacing: 0.1);
      case ink:
        return const BrushDefaults(
            size: 10, opacity: 1.0, hardness: 1.0, spacing: 0.05);
      case marker:
        return const BrushDefaults(
            size: 24, opacity: 0.6, hardness: 0.7, spacing: 0.05);
      case airbrush:
        return const BrushDefaults(
            size: 40, opacity: 0.25, hardness: 0.0, spacing: 0.12);
      case watercolor:
        return const BrushDefaults(
            size: 50, opacity: 0.18, hardness: 0.0, spacing: 0.18);
      case pixel:
        return const BrushDefaults(
            size: 12, opacity: 1.0, hardness: 1.0, spacing: 0.5);
      case chalk:
        return const BrushDefaults(
            size: 18, opacity: 0.9, hardness: 0.5, spacing: 0.22);
      case custom:
        return const BrushDefaults(
            size: 20, opacity: 0.8, hardness: 0.6, spacing: 0.2);
    }
  }

  /// Parses a stored [name] back into a [BrushType], defaulting to [ink].
  static BrushType fromName(String? name) {
    for (final t in BrushType.values) {
      if (t.name == name) return t;
    }
    return BrushType.ink;
  }
}
