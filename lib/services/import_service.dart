import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/audio_track.dart';
import '../state/editor_controller.dart';

/// Handles importing external media (images, GIF animations, audio) into a
/// project. Uses `file_picker` to select files and the `image` package to
/// decode/normalise raster data.
class ImportService {
  ImportService._();

  static const int _stillMaxDim = 1280;
  static const int _gifMaxDim = 640;

  /// Downscales [image] so its longest side is at most [maxDim].
  static img.Image _clamp(img.Image image, int maxDim) {
    final longest =
        image.width > image.height ? image.width : image.height;
    if (longest <= maxDim) return image;
    if (image.width >= image.height) {
      return img.copyResize(image, width: maxDim);
    }
    return img.copyResize(image, height: maxDim);
  }

  /// Imports a still PNG/JPG onto a new layer. Returns a status message.
  static Future<String> importImage(EditorController controller) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    final bytes = result?.files.firstOrNull?.bytes;
    if (bytes == null) return 'No image selected';

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return 'Could not read image';

    final clamped = _clamp(decoded, _stillMaxDim);
    final png = img.encodePng(clamped);
    await controller.addImageLayer(png, clamped.width, clamped.height);
    return 'Image imported';
  }

  /// Imports an animated GIF as one frame per animation frame.
  static Future<String> importGif(EditorController controller) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gif'],
      withData: true,
    );
    final bytes = result?.files.firstOrNull?.bytes;
    if (bytes == null) return 'No GIF selected';

    final decoded = img.decodeGif(bytes);
    if (decoded == null) return 'Could not read GIF';

    final source =
        decoded.frames.isNotEmpty ? decoded.frames : <img.Image>[decoded];
    final frames = <({Uint8List png, int width, int height})>[];
    for (final frame in source) {
      final clamped = _clamp(frame, _gifMaxDim);
      frames.add((
        png: img.encodePng(clamped),
        width: clamped.width,
        height: clamped.height,
      ));
    }
    if (frames.isEmpty) return 'GIF had no frames';

    await controller.addImageFrames(frames);
    return 'Imported ${frames.length} frame${frames.length == 1 ? '' : 's'}';
  }

  /// Imports an audio file, copying it into app storage so it persists.
  static Future<String> importAudio(EditorController controller) async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return 'No audio selected';

    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/faby_audio');
    if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
    final dest = '${audioDir.path}/${controller.project.id}_${file.name}';
    await File(dest).writeAsBytes(bytes);

    controller.setAudioTrack(AudioTrack(name: file.name, path: dest));
    return 'Audio imported';
  }
}
