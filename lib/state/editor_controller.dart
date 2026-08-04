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
