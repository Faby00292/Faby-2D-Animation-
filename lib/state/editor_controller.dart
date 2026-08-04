import 'package:flutter/material.dart';

import '../models/brush_preset.dart';
import '../models/brush_type.dart';
import '../models/frame.dart';
import '../models/layer.dart';
import '../models/project.dart';
import '../models/stroke.dart';
import '../models/tool.dart';

/// Holds all mutable editor state for a single [Project]: the active frame and
/// layer, brush settings, the in-progress stroke, and undo/redo history.
class EditorController extends ChangeNotifier {
  EditorController(this.project);

  final Project project;

  static const int maxLayers = 10;

  int currentFrameIndex = 0;
  int currentLayerIndex = 0;

  // --- Brush / tool settings ---
  EditorTool tool = EditorTool.brush;
  BrushType brushType = BrushType.ink;
  Color brushColor = const Color(0xFF55E4C1);
  double brushSize = 10; // canvas pixels
  double brushOpacity = 1.0;
  double brushHardness = 1.0;
  double brushSpacing = 0.05; // fraction of width, for stamped brushes
  double brushSmoothing = 0.4; // 0 = raw input, 1 = heavily smoothed
  bool rulerEnabled = false;

  /// When true, the next canvas tap samples a color instead of drawing.
  bool eyedropperMode = false;

  int _seq = 0;
  Stroke? _activeStroke;
  final List<Stroke> _redoStack = <Stroke>[];
  Frame? _clipboardFrame;
  final Set<String> _selectedFrameIds = <String>{};

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  // --- Derived accessors ---
  Frame get currentFrame => project.frames[currentFrameIndex];
  Layer get currentLayer => currentFrame.layers[currentLayerIndex];

  bool get canUndo => currentLayer.strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  bool get canDraw =>
      !eyedropperMode &&
      tool.isDrawing &&
      currentLayer.isVisible &&
      !currentLayer.isLocked;

  // --- Tool / brush mutations ---
  void selectTool(EditorTool value) {
    tool = value;
    notifyListeners();
  }

  /// Selects a brush engine and applies its default parameters.
  void selectBrushType(BrushType type) {
    brushType = type;
    final d = type.defaults;
    brushSize = d.size;
    brushOpacity = d.opacity;
    brushHardness = d.hardness;
    brushSpacing = d.spacing;
    if (!tool.isDrawing || tool == EditorTool.eraser) {
      tool = EditorTool.brush;
    }
    notifyListeners();
  }

  /// Applies a saved custom brush preset (keeps the current color).
  void applyPreset(BrushPreset preset) {
    brushType = preset.type;
    brushSize = preset.size;
    brushOpacity = preset.opacity;
    brushHardness = preset.hardness;
    brushSpacing = preset.spacing;
    if (!tool.isDrawing || tool == EditorTool.eraser) {
      tool = EditorTool.brush;
    }
    notifyListeners();
  }

  /// Snapshots the current brush settings into a named preset.
  BrushPreset toPreset(String name) => BrushPreset(
        id: _id('brush_'),
        name: name,
        type: brushType,
        size: brushSize,
        opacity: brushOpacity,
        hardness: brushHardness,
        spacing: brushSpacing,
      );

  void setColor(Color value) {
    brushColor = value;
    notifyListeners();
  }

  void setSize(double value) {
    brushSize = value;
    notifyListeners();
  }

  void setOpacity(double value) {
    brushOpacity = value;
    notifyListeners();
  }

  void setHardness(double value) {
    brushHardness = value;
    notifyListeners();
  }

  void setSpacing(double value) {
    brushSpacing = value;
    notifyListeners();
  }

  void setSmoothing(double value) {
    brushSmoothing = value;
    notifyListeners();
  }

  void toggleRuler() {
    rulerEnabled = !rulerEnabled;
    notifyListeners();
  }

  void setEyedropperMode(bool value) {
    eyedropperMode = value;
    notifyListeners();
  }

  // --- Drawing ---
  void startStroke(Offset canvasPoint) {
    if (!canDraw) return;
    final stroke = Stroke(
      points: <Offset>[canvasPoint],
      color: brushColor,
      width: brushSize,
      opacity: brushOpacity,
      hardness: brushHardness,
      brushType: brushType,
      spacing: brushSpacing,
      seed: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
      isEraser: tool == EditorTool.eraser,
    );
    _activeStroke = stroke;
    currentLayer.strokes.add(stroke);
    _redoStack.clear();
    notifyListeners();
  }

  void extendStroke(Offset canvasPoint) {
    final stroke = _activeStroke;
    if (stroke == null) return;
    // Exponential smoothing: higher smoothing pulls new points toward the last.
    final last = stroke.points.last;
    final t = (1.0 - brushSmoothing).clamp(0.05, 1.0);
    final smoothed = Offset(
      last.dx + (canvasPoint.dx - last.dx) * t,
      last.dy + (canvasPoint.dy - last.dy) * t,
    );
    stroke.points.add(smoothed);
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke == null) return;
    _activeStroke = null;
    notifyListeners();
  }

  /// Aborts the in-progress stroke (e.g. when a second finger starts a pinch).
  void cancelStroke() {
    final stroke = _activeStroke;
    if (stroke == null) return;
    currentLayer.strokes.remove(stroke);
    _activeStroke = null;
    notifyListeners();
  }

  void undo() {
    final strokes = currentLayer.strokes;
    if (strokes.isEmpty) return;
    _redoStack.add(strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    currentLayer.strokes.add(_redoStack.removeLast());
    notifyListeners();
  }

  // --- Frames ---
  void selectFrame(int index) {
    if (index < 0 || index >= project.frames.length) return;
    currentFrameIndex = index;
    currentLayerIndex = 0;
    _activeStroke = null;
    _redoStack.clear();
    notifyListeners();
  }

  void addFrame() {
    final layer = Layer(id: _id('layer_'), name: 'Layer 1');
    final frame = Frame(id: _id('frame_'), layers: <Layer>[layer]);
    project.frames.insert(currentFrameIndex + 1, frame);
    currentFrameIndex += 1;
    currentLayerIndex = 0;
    _redoStack.clear();
    notifyListeners();
  }

  void deleteFrame(int index) {
    if (project.frames.length <= 1) return;
    project.frames.removeAt(index);
    if (currentFrameIndex >= project.frames.length) {
      currentFrameIndex = project.frames.length - 1;
    }
    currentLayerIndex = 0;
    _redoStack.clear();
    notifyListeners();
  }

  // --- Frame clipboard / duplication / insertion / reordering ---
  bool get canPaste => _clipboardFrame != null;

  Stroke _cloneStroke(Stroke s) => Stroke(
        points: List<Offset>.of(s.points),
        color: s.color,
        width: s.width,
        opacity: s.opacity,
        hardness: s.hardness,
        brushType: s.brushType,
        spacing: s.spacing,
        seed: s.seed,
        isEraser: s.isEraser,
      );

  Frame _cloneFrame(Frame source) => Frame(
        id: _id('frame_'),
        holdCount: source.holdCount,
        layers: [
          for (final l in source.layers)
            Layer(
              id: _id('layer_'),
              name: l.name,
              opacity: l.opacity,
              isVisible: l.isVisible,
              isLocked: l.isLocked,
              strokes: [for (final s in l.strokes) _cloneStroke(s)],
            ),
        ],
      );

  void copyFrame([int? index]) {
    final i = index ?? currentFrameIndex;
    _clipboardFrame = _cloneFrame(project.frames[i]);
    notifyListeners();
  }

  void pasteFrame() {
    final clip = _clipboardFrame;
    if (clip == null) return;
    project.frames.insert(currentFrameIndex + 1, _cloneFrame(clip));
    currentFrameIndex += 1;
    currentLayerIndex = 0;
    _redoStack.clear();
    notifyListeners();
  }

  void duplicateFrame([int? index]) {
    final i = index ?? currentFrameIndex;
    project.frames.insert(i + 1, _cloneFrame(project.frames[i]));
    currentFrameIndex = i + 1;
    currentLayerIndex = 0;
    _redoStack.clear();
    notifyListeners();
  }

  /// Inserts a blank frame at the current position (before the active frame),
  /// which becomes the new active frame.
  void insertBlankFrame() {
    final layer = Layer(id: _id('layer_'), name: 'Layer 1');
    final frame = Frame(id: _id('frame_'), layers: <Layer>[layer]);
    project.frames.insert(currentFrameIndex, frame);
    currentLayerIndex = 0;
    _redoStack.clear();
    notifyListeners();
  }

  /// Duplicates the active frame [count] times immediately after it, so a
  /// drawing can be extended across several frames at once.
  void extendFrame(int count) {
    if (count <= 0) return;
    final source = project.frames[currentFrameIndex];
    for (var k = 0; k < count; k++) {
      project.frames.insert(currentFrameIndex + 1 + k, _cloneFrame(source));
    }
    notifyListeners();
  }

  /// Reorders a frame. [newIndex] is already adjusted for the removal of the
  /// item at [oldIndex] (matching [ReorderableListView.onReorderItem]).
  void reorderFrames(int oldIndex, int newIndex) {
    final active = project.frames[currentFrameIndex];
    final moved = project.frames.removeAt(oldIndex);
    project.frames.insert(newIndex, moved);
    currentFrameIndex = project.frames.indexOf(active);
    clearFrameSelection();
    _redoStack.clear();
    notifyListeners();
  }

  // --- Frame hold / duration ---
  void setFrameHold(int index, int hold) {
    project.frames[index].holdCount = hold.clamp(1, 99);
    notifyListeners();
  }

  void changeFrameHold(int index, int delta) =>
      setFrameHold(index, project.frames[index].holdCount + delta);

  /// Total number of playback slots (sum of frame holds).
  int get totalFrameSlots {
    var total = 0;
    for (final f in project.frames) {
      total += f.holdCount;
    }
    return total;
  }

  /// Estimated duration in seconds at the project's frame rate.
  double get durationSeconds => totalFrameSlots / project.fps;

  // --- Multi-frame selection ---
  bool get hasFrameSelection => _selectedFrameIds.isNotEmpty;
  int get selectedFrameCount => _selectedFrameIds.length;
  bool isFrameSelected(String id) => _selectedFrameIds.contains(id);

  void toggleFrameSelected(String id) {
    if (!_selectedFrameIds.add(id)) {
      _selectedFrameIds.remove(id);
    }
    notifyListeners();
  }

  void clearFrameSelection() {
    if (_selectedFrameIds.isEmpty) return;
    _selectedFrameIds.clear();
    notifyListeners();
  }

  void duplicateSelectedFrames() {
    if (_selectedFrameIds.isEmpty) return;
    final sources = <Frame>[
      for (final f in project.frames)
        if (_selectedFrameIds.contains(f.id)) f,
    ];
    // Insert from last to first so earlier indices stay valid.
    for (final src in sources.reversed) {
      final idx = project.frames.indexOf(src);
      project.frames.insert(idx + 1, _cloneFrame(src));
    }
    clearFrameSelection();
    _redoStack.clear();
    notifyListeners();
  }

  void deleteSelectedFrames() {
    if (_selectedFrameIds.isEmpty) return;
    final active = project.frames[currentFrameIndex];
    final remaining = <Frame>[
      for (final f in project.frames)
        if (!_selectedFrameIds.contains(f.id)) f,
    ];
    if (remaining.isEmpty) {
      // Always keep at least one frame.
      _selectedFrameIds.clear();
      notifyListeners();
      return;
    }
    project.frames
      ..clear()
      ..addAll(remaining);
    final activeIdx = project.frames.indexOf(active);
    currentFrameIndex = activeIdx >= 0 ? activeIdx : project.frames.length - 1;
    currentLayerIndex = 0;
    _selectedFrameIds.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // --- Layers (max [maxLayers]) ---
  bool get canAddLayer => currentFrame.layers.length < maxLayers;

  void addLayer() {
    if (!canAddLayer) return;
    final n = currentFrame.layers.length + 1;
    currentFrame.layers.add(Layer(id: _id('layer_'), name: 'Layer $n'));
    currentLayerIndex = currentFrame.layers.length - 1;
    notifyListeners();
  }

  void selectLayer(int index) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    currentLayerIndex = index;
    notifyListeners();
  }

  void deleteLayer(int index) {
    if (currentFrame.layers.length <= 1) return;
    currentFrame.layers.removeAt(index);
    if (currentLayerIndex >= currentFrame.layers.length) {
      currentLayerIndex = currentFrame.layers.length - 1;
    }
    notifyListeners();
  }

  void toggleLayerVisible(int index) {
    final layer = currentFrame.layers[index];
    layer.isVisible = !layer.isVisible;
    notifyListeners();
  }

  void toggleLayerLock(int index) {
    final layer = currentFrame.layers[index];
    layer.isLocked = !layer.isLocked;
    notifyListeners();
  }

  void setLayerOpacity(int index, double value) {
    currentFrame.layers[index].opacity = value;
    notifyListeners();
  }
}
