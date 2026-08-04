import 'dart:io';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../drawing/drawing_painter.dart';
import '../models/frame.dart';
import '../models/project.dart';
import '../state/editor_controller.dart';

/// Renders frames and exports the animation as an animated GIF or a single
/// frame as PNG, then hands the file to the platform share sheet.
class ExportService {
  ExportService._();

  static const int _pngMaxDim = 1920;
  static const int _gifMaxDim = 480;

  static double _fitScale(Project project, int maxDim) {
    final longest = project.format.width > project.format.height
        ? project.format.width
        : project.format.height;
    return longest > maxDim ? maxDim / longest : 1.0;
  }

  /// Renders [frame] to a [ui.Image] at [scale] of the project's dimensions.
  static Future<ui.Image> _renderFrame(
    Project project,
    Frame frame,
    double scale,
  ) async {
    final w = (project.format.width * scale).round().clamp(1, 8192);
    final h = (project.format.height * scale).round().clamp(1, 8192);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    DrawingPainter(
      frame: frame,
      formatSize: ui.Size(
        project.format.width.toDouble(),
        project.format.height.toDouble(),
      ),
    ).paint(canvas, ui.Size(w.toDouble(), h.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    return image;
  }

  static Future<img.Image> _toImgImage(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: data!.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  static String _safeName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return cleaned.isEmpty ? 'faby_export' : cleaned;
  }

  static Future<File> _writeTemp(String fileName, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Exports the current frame as a PNG and opens the share sheet.
  static Future<String> exportCurrentFramePng(
      EditorController controller) async {
    final project = controller.project;
    final scale = _fitScale(project, _pngMaxDim);
    final image = await _renderFrame(project, controller.currentFrame, scale);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return 'Render failed';

    final file = await _writeTemp(
      '${_safeName(project.name)}_frame${controller.currentFrameIndex + 1}.png',
      data.buffer.asUint8List(),
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: project.name),
    );
    return 'Frame exported';
  }

  /// Exports the whole animation as an animated GIF (honoring frame holds and
  /// the project frame rate) and opens the share sheet.
  static Future<String> exportGif(EditorController controller) async {
    final project = controller.project;
    final scale = _fitScale(project, _gifMaxDim);
    final encoder = img.GifEncoder();

    for (final frame in project.frames) {
      final uiImage = await _renderFrame(project, frame, scale);
      final image = await _toImgImage(uiImage);
      uiImage.dispose();
      // GIF frame delay is in centiseconds (1/100 s).
      final centis =
          (frame.holdCount * 100 / project.fps).round().clamp(1, 65535);
      encoder.addFrame(image, duration: centis);
    }

    final bytes = encoder.finish();
    if (bytes == null) return 'GIF encode failed';

    final file =
        await _writeTemp('${_safeName(project.name)}.gif', bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: project.name),
    );
    return 'GIF exported (${project.frames.length} frames)';
  }
}
