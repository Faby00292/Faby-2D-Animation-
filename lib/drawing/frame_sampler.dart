import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/frame.dart';
import 'drawing_painter.dart';

/// Rasterises [frame] and returns the color at [canvasPoint] (in canvas/format
/// coordinates). Used by the eyedropper. Rendered at reduced resolution for
/// speed; the page background is opaque white, so empty areas sample as white.
Future<Color> sampleFrameColor({
  required Frame frame,
  required Size formatSize,
  required Offset canvasPoint,
}) async {
  const maxDim = 640.0;
  final longest = math.max(formatSize.width, formatSize.height);
  final scale = longest > maxDim ? maxDim / longest : 1.0;
  final imgW = (formatSize.width * scale).round().clamp(1, 4096);
  final imgH = (formatSize.height * scale).round().clamp(1, 4096);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  DrawingPainter(frame: frame, formatSize: formatSize)
      .paint(canvas, Size(imgW.toDouble(), imgH.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(imgW, imgH);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  if (byteData == null) return Colors.white;

  final px = (canvasPoint.dx * scale).round().clamp(0, imgW - 1);
  final py = (canvasPoint.dy * scale).round().clamp(0, imgH - 1);
  final offset = (py * imgW + px) * 4;
  return Color.fromARGB(
    byteData.getUint8(offset + 3),
    byteData.getUint8(offset),
    byteData.getUint8(offset + 1),
    byteData.getUint8(offset + 2),
  );
}
