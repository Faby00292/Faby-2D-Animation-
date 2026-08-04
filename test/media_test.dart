import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:faby_2d_animation/models/audio_track.dart';
import 'package:faby_2d_animation/models/frame.dart';
import 'package:faby_2d_animation/models/layer.dart';
import 'package:faby_2d_animation/models/layer_image.dart';
import 'package:faby_2d_animation/models/project.dart';
import 'package:faby_2d_animation/models/project_format.dart';

void main() {
  test('LayerImage round-trips (bytes via base64)', () {
    final image = LayerImage(
      id: 'img1',
      bytes: Uint8List.fromList([1, 2, 3, 4, 250]),
      srcWidth: 640,
      srcHeight: 480,
      dx: 12,
      dy: 8,
      scale: 1.5,
    );
    final restored = LayerImage.fromJson(image.toJson());
    expect(restored.id, 'img1');
    expect(restored.srcWidth, 640);
    expect(restored.srcHeight, 480);
    expect(restored.dx, 12);
    expect(restored.scale, 1.5);
    expect(restored.bytes, image.bytes);
  });

  test('AudioTrack round-trips', () {
    const track = AudioTrack(name: 'song.mp3', path: '/data/song.mp3');
    final restored = AudioTrack.fromJson(track.toJson());
    expect(restored.name, 'song.mp3');
    expect(restored.path, '/data/song.mp3');
  });

  test('Project persists audio and layer images', () {
    final project = Project(
      id: 'p',
      name: 'T',
      format: ProjectFormat.youtube720,
      fps: 12,
      audio: const AudioTrack(name: 'a.wav', path: '/a.wav'),
      frames: [
        Frame(
          id: 'f0',
          layers: [
            Layer(
              id: 'l0',
              name: 'Image 1',
              images: [
                LayerImage(
                  id: 'i0',
                  bytes: Uint8List.fromList([9, 8, 7]),
                  srcWidth: 10,
                  srcHeight: 10,
                  dx: 0,
                  dy: 0,
                  scale: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final restored = Project.fromJson(project.toJson());
    expect(restored.audio?.name, 'a.wav');
    final img = restored.frames.first.layers.first.images.single;
    expect(img.id, 'i0');
    expect(img.bytes, Uint8List.fromList([9, 8, 7]));
  });
}
