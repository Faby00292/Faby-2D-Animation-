import 'package:uuid/uuid.dart';

import 'layer.dart';

const Uuid _uuid = Uuid();

/// A single animation frame. Holds its own stack of [Layer]s.
///
/// [hold] lets a frame occupy multiple slots on the timeline without copying
/// its content (e.g. hold == 3 shows this drawing for three frame-durations).
class Frame {
  Frame({
    String? id,
    List<Layer>? layers,
    this.hold = 1,
  })  : id = id ?? _uuid.v4(),
        layers = layers ?? <Layer>[Layer(name: 'Layer 1')];

  final String id;
  final List<Layer> layers;

  /// Number of timeline slots this frame occupies (>= 1).
  int hold;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'hold': hold,
        'layers': <Map<String, dynamic>>[
          for (final Layer l in layers) l.toJson(),
        ],
      };

  factory Frame.fromJson(Map<String, dynamic> json) => Frame(
        id: json['id'] as String?,
        hold: (json['hold'] as num?)?.toInt() ?? 1,
        layers: <Layer>[
          for (final dynamic l in (json['layers'] as List<dynamic>? ?? <dynamic>[]))
            Layer.fromJson(l as Map<String, dynamic>),
        ],
      );

  Frame copy() => Frame(
        hold: hold,
        layers: <Layer>[for (final Layer l in layers) l.copy()],
      );
}
