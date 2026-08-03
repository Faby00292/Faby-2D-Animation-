import 'package:uuid/uuid.dart';

import 'stroke.dart';

const Uuid _uuid = Uuid();

/// A single drawing layer within a frame. Up to 10 layers per project are
/// supported. Strokes are painted bottom-to-top in list order.
class Layer {
  Layer({
    String? id,
    required this.name,
    List<Stroke>? strokes,
    this.opacity = 1.0,
    this.locked = false,
    this.hidden = false,
  })  : id = id ?? _uuid.v4(),
        strokes = strokes ?? <Stroke>[];

  final String id;
  String name;
  final List<Stroke> strokes;
  double opacity;
  bool locked;
  bool hidden;

  bool get isEditable => !locked && !hidden;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'opacity': opacity,
        'locked': locked,
        'hidden': hidden,
        'strokes': <Map<String, dynamic>>[
          for (final Stroke s in strokes) s.toJson(),
        ],
      };

  factory Layer.fromJson(Map<String, dynamic> json) => Layer(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Layer',
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        locked: json['locked'] as bool? ?? false,
        hidden: json['hidden'] as bool? ?? false,
        strokes: <Stroke>[
          for (final dynamic s in (json['strokes'] as List<dynamic>? ?? <dynamic>[]))
            Stroke.fromJson(s as Map<String, dynamic>),
        ],
      );

  Layer copy({String? name}) => Layer(
        name: name ?? this.name,
        opacity: opacity,
        locked: locked,
        hidden: hidden,
        strokes: <Stroke>[for (final Stroke s in strokes) s.copy()],
      );
}
