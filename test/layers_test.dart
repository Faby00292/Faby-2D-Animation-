import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faby_2d_animation/models/brush_type.dart';
import 'package:faby_2d_animation/models/frame.dart';
import 'package:faby_2d_animation/models/layer.dart';
import 'package:faby_2d_animation/models/project.dart';
import 'package:faby_2d_animation/models/project_format.dart';
import 'package:faby_2d_animation/models/stroke.dart';
import 'package:faby_2d_animation/state/editor_controller.dart';

Stroke _stroke() => Stroke(
      points: const [Offset(0, 0)],
      color: const Color(0xFF000000),
      width: 4,
      opacity: 1,
      hardness: 1,
      brushType: BrushType.ink,
      spacing: 0.1,
      seed: 1,
    );

EditorController _controllerWithLayers(List<String> names) {
  final project = Project(
    id: 'p',
    name: 'T',
    format: ProjectFormat.youtube1080,
    fps: 12,
    frames: [
      Frame(
        id: 'f0',
        layers: [
          for (final n in names) Layer(id: 'layer_$n', name: n),
        ],
      ),
    ],
  );
  return EditorController(project);
}

void main() {
  test('rename updates the layer name', () {
    final c = _controllerWithLayers(['A']);
    c.renameLayer(0, 'Background');
    expect(c.currentFrame.layers[0].name, 'Background');
  });

  test('duplicate deep-copies strokes and respects max layers', () {
    final c = _controllerWithLayers(['A']);
    c.currentFrame.layers[0].strokes.add(_stroke());
    c.duplicateLayer(0);
    expect(c.currentFrame.layers.length, 2);
    c.currentFrame.layers[0].strokes.clear();
    expect(c.currentFrame.layers[1].strokes.length, 1);

    // Fill to the max and confirm duplicate is a no-op past the cap.
    while (c.canAddLayer) {
      c.addLayer();
    }
    expect(c.currentFrame.layers.length, EditorController.maxLayers);
    c.duplicateLayer(0);
    expect(c.currentFrame.layers.length, EditorController.maxLayers);
  });

  test('merge down combines strokes into the lower layer', () {
    final c = _controllerWithLayers(['A', 'B']); // A bottom, B top
    c.currentFrame.layers[0].strokes.add(_stroke());
    c.currentFrame.layers[1].strokes
      ..add(_stroke())
      ..add(_stroke());
    c.mergeLayerDown(1); // merge B into A
    expect(c.currentFrame.layers.length, 1);
    expect(c.currentFrame.layers[0].strokes.length, 3);
    expect(c.currentLayerIndex, 0);
  });

  test('reorder (display order) keeps the active layer active', () {
    final c = _controllerWithLayers(['A', 'B', 'C']); // model bottom->top
    c.selectLayer(0); // A active
    // Display is [C, B, A]; move display index 0 to 2.
    c.reorderLayers(0, 2);
    expect(
      c.currentFrame.layers.map((l) => l.name).toList(),
      ['C', 'A', 'B'],
    );
    expect(c.currentFrame.layers[c.currentLayerIndex].name, 'A');
  });
}
