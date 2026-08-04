import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faby_2d_animation/models/frame.dart';
import 'package:faby_2d_animation/models/layer.dart';
import 'package:faby_2d_animation/models/project.dart';
import 'package:faby_2d_animation/models/project_format.dart';
import 'package:faby_2d_animation/models/stroke.dart';
import 'package:faby_2d_animation/models/brush_type.dart';
import 'package:faby_2d_animation/state/editor_controller.dart';

EditorController _controllerWithFrames(int count) {
  final project = Project(
    id: 'p',
    name: 'T',
    format: ProjectFormat.youtube1080,
    fps: 12,
    frames: [
      for (var i = 0; i < count; i++)
        Frame(id: 'f$i', layers: [Layer(id: 'l$i', name: 'Layer 1')]),
    ],
  );
  return EditorController(project);
}

void main() {
  test('duplicate deep-copies strokes independently', () {
    final c = _controllerWithFrames(1);
    c.currentLayer.strokes.add(
      Stroke(
        points: [const Offset(0, 0), const Offset(1, 1)],
        color: const Color(0xFF000000),
        width: 4,
        opacity: 1,
        hardness: 1,
        brushType: BrushType.ink,
        spacing: 0.1,
        seed: 1,
      ),
    );
    c.duplicateFrame();

    expect(c.project.frames.length, 2);
    // Editing the original must not affect the duplicate.
    c.project.frames[0].layers[0].strokes.clear();
    expect(c.project.frames[1].layers[0].strokes.length, 1);
  });

  test('copy/paste inserts after the active frame', () {
    final c = _controllerWithFrames(2);
    c.selectFrame(0);
    c.copyFrame();
    c.pasteFrame();
    expect(c.project.frames.length, 3);
    expect(c.currentFrameIndex, 1);
  });

  test('reorder keeps the active frame active', () {
    final c = _controllerWithFrames(3);
    c.selectFrame(0); // frame f0 active
    // Move f0 to the end (newIndex already adjusted for removal).
    c.reorderFrames(0, 2);
    expect(c.project.frames.map((f) => f.id).toList(), ['f1', 'f2', 'f0']);
    expect(c.currentFrameIndex, 2);
  });

  test('hold and total slots', () {
    final c = _controllerWithFrames(2);
    c.setFrameHold(0, 3);
    c.changeFrameHold(1, 1); // 1 -> 2
    expect(c.totalFrameSlots, 5);
  });

  test('multi-select delete keeps at least one frame', () {
    final c = _controllerWithFrames(3);
    c.toggleFrameSelected('f1');
    c.toggleFrameSelected('f2');
    expect(c.selectedFrameCount, 2);
    c.deleteSelectedFrames();
    expect(c.project.frames.map((f) => f.id).toList(), ['f0']);
    expect(c.hasFrameSelection, false);
  });

  test('extend adds copies after the active frame', () {
    final c = _controllerWithFrames(1);
    c.extendFrame(3);
    expect(c.project.frames.length, 4);
  });
}
