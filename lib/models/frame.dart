import 'layer.dart';

/// A single animation frame, composed of one or more stacked [Layer]s.
class Frame {
  Frame({
    required this.id,
    List<Layer>? layers,
    this.holdCount = 1,
  }) : layers = layers ?? <Layer>[];

  final String id;
  final List<Layer> layers;

  /// How many timeline slots this frame is held for (frame hold / duration).
  int holdCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'hold': holdCount,
        'layers': [for (final l in layers) l.toJson()],
      };

  factory Frame.fromJson(Map<String, dynamic> json) => Frame(
        id: json['id'] as String,
        holdCount: (json['hold'] as num?)?.toInt() ?? 1,
        layers: [
          for (final l in (json['layers'] as List? ?? const []))
            Layer.fromJson(l as Map<String, dynamic>),
        ],
      );
}
