import 'package:flutter/material.dart';

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
  Color brushColor = const Color(0xFF55E4C1);
  double brushSize = 12; // canvas pixels
  double brushOpacity = 1.0;
  double brushHardness = 1.0;
  bool rulerEnabled = false;

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
      tool.isDrawing && currentLayer.isVisible && !currentLayer.isLocked;

  // --- Tool / brush mutations ---
  void selectTool(EditorTool value) {
    tool = value;
    notifyListeners();
  }

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

  void toggleRuler() {
    rulerEnabled = !rulerEnabled;
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
    stroke.points.add(canvasPoint);
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
