import 'stroke.dart';

/// A single drawing layer within a [Frame].
class Layer {
  Layer({
    required this.id,
    required this.name,
    List<Stroke>? strokes,
    this.opacity = 1.0,
    this.isVisible = true,
    this.isLocked = false,
  }) : strokes = strokes ?? <Stroke>[];

  final String id;
  String name;
  final List<Stroke> strokes;

  /// 0..1 layer opacity.
  double opacity;
  bool isVisible;
  bool isLocked;
}
