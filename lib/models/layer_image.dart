import 'dart:convert';
import 'dart:typed_data';

/// A raster image (imported PNG/JPG or a GIF frame) placed on a layer.
///
/// [bytes] holds PNG-encoded image data. Position and scale are in canvas
/// (format-pixel) coordinates, so images render consistently at any zoom.
class LayerImage {
  LayerImage({
    required this.id,
    required this.bytes,
    required this.srcWidth,
    required this.srcHeight,
    required this.dx,
    required this.dy,
    required this.scale,
  });

  final String id;
  final Uint8List bytes;
  final int srcWidth;
  final int srcHeight;
  double dx;
  double dy;
  double scale;

  double get displayWidth => srcWidth * scale;
  double get displayHeight => srcHeight * scale;

  Map<String, dynamic> toJson() => {
        'id': id,
        'w': srcWidth,
        'h': srcHeight,
        'dx': dx,
        'dy': dy,
        'scale': scale,
        'png': base64Encode(bytes),
      };

  factory LayerImage.fromJson(Map<String, dynamic> json) => LayerImage(
        id: json['id'] as String,
        bytes: base64Decode(json['png'] as String),
        srcWidth: (json['w'] as num).toInt(),
        srcHeight: (json['h'] as num).toInt(),
        dx: (json['dx'] as num).toDouble(),
        dy: (json['dy'] as num).toDouble(),
        scale: (json['scale'] as num).toDouble(),
      );
}
