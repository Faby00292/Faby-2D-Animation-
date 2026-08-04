import 'layer_image.dart';
import 'stroke.dart';

/// A single drawing layer within a [Frame].
class Layer {
  Layer({
    required this.id,
    required this.name,
    List<Stroke>? strokes,
    List<LayerImage>? images,
    this.opacity = 1.0,
    this.isVisible = true,
    this.isLocked = false,
  })  : strokes = strokes ?? <Stroke>[],
        images = images ?? <LayerImage>[];

  final String id;
  String name;
  final List<Stroke> strokes;

  /// Imported raster images (PNG/JPG, GIF frames) on this layer.
  final List<LayerImage> images;

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
        'images': [for (final i in images) i.toJson()],
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
        images: [
          for (final i in (json['images'] as List? ?? const []))
            LayerImage.fromJson(i as Map<String, dynamic>),
        ],
      );
}
