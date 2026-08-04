import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faby_2d_animation/models/brush_type.dart';
import 'package:faby_2d_animation/models/frame.dart';
import 'package:faby_2d_animation/models/layer.dart';
import 'package:faby_2d_animation/models/project.dart';
import 'package:faby_2d_animation/models/project_format.dart';
import 'package:faby_2d_animation/models/stroke.dart';

void main() {
  test('Project round-trips through JSON', () {
    final stroke = Stroke(
      points: const [Offset(1, 2), Offset(3, 4)],
      color: const Color(0xFF55E4C1),
      width: 8,
      opacity: 0.5,
      hardness: 0.7,
      brushType: BrushType.chalk,
      spacing: 0.2,
      seed: 12345,
    );
    final project = Project(
      id: 'p1',
      name: 'Test',
      format: ProjectFormat.tiktok1080,
      fps: 18,
      frames: [
        Frame(
          id: 'f1',
          layers: [Layer(id: 'l1', name: 'Layer 1', strokes: [stroke])],
        ),
      ],
    );

    final restored = Project.fromJson(project.toJson());

    expect(restored.name, 'Test');
    expect(restored.format, ProjectFormat.tiktok1080);
    expect(restored.fps, 18);
    expect(restored.frames.length, 1);

    final restoredStroke = restored.frames.first.layers.first.strokes.first;
    expect(restoredStroke.brushType, BrushType.chalk);
    expect(restoredStroke.points.length, 2);
    expect(restoredStroke.points.last, const Offset(3, 4));
    expect(restoredStroke.color.toARGB32(), const Color(0xFF55E4C1).toARGB32());
    expect(restoredStroke.opacity, 0.5);
    expect(restoredStroke.seed, 12345);
  });
}
