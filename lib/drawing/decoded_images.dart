import 'dart:typed_data';
import 'dart:ui' as ui;

/// Process-wide cache of decoded [ui.Image]s keyed by [LayerImage] id.
///
/// `CustomPainter` needs images synchronously, so images are decoded once
/// (on import or project load) and looked up here while painting.
class DecodedImages {
  DecodedImages._();

  static final Map<String, ui.Image> _cache = {};

  static ui.Image? get(String id) => _cache[id];

  static bool has(String id) => _cache.containsKey(id);

  static Future<ui.Image> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Decodes [bytes] and stores the result under [id].
  static Future<void> load(String id, Uint8List bytes) async {
    if (_cache.containsKey(id)) return;
    _cache[id] = await decode(bytes);
  }

  static void remove(String id) {
    _cache.remove(id)?.dispose();
  }
}
