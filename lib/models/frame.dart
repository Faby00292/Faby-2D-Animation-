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
}
