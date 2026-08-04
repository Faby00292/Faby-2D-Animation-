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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'opacity': opacity,
        'visible': isVisible,
        'locked': isLocked,
        'strokes': [for (final s in strokes) s.toJson()],
      };

  factory Layer.fromJson(Map<String, dynamic> json) => Layer(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Layer',
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        isVisible: json['visible'] as bool? ?? true,
        isLocked: json['locked'] as bool? ?? false,
        strokes: [
          for (final s in (json['strokes'] as List? ?? const []))
            Stroke.fromJson(s as Map<String, dynamic>),
        ],
      );
}
