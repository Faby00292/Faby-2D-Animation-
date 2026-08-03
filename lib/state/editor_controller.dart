import 'dart:async';

import 'package:flutter/material.dart';

import '../models/brush.dart';
import '../models/frame.dart';
import '../models/layer.dart';
import '../models/project.dart';
import '../models/stroke.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Onion-skin display configuration.
class OnionSkinSettings {
  OnionSkinSettings({
    this.enabled = false,
    this.prevFrames = 1,
    this.nextFrames = 1,
    this.prevColor = const Color(0xFFFF5A7A),
    this.nextColor = const Color(0xFF55A8FF),
    this.opacity = 0.35,
  });

  bool enabled;
  int prevFrames;
  int nextFrames;
  Color prevColor;
  Color nextColor;
  double opacity;
}

class _UndoEntry {
  _UndoEntry(this.undo, this.redo);
  final VoidCallback undo;
  final VoidCallback redo;
}

/// Drives everything inside the workspace: the active project, current frame /
/// layer, selected tool, brush + colour, onion skin, undo/redo, playback and
/// debounced auto-save. Widgets listen to this via [ChangeNotifier].
class EditorController extends ChangeNotifier {
  EditorController(this._storage, this.project);

  final StorageService _storage;
  final Project project;

  static const int maxLayers = 10;

  int _frameIndex = 0;
  int _layerIndex = 0;
  ToolType _tool = ToolType.brush;
  final BrushSettings brush = BrushSettings();
  Color _color = AppTheme.accent;
  bool _rulerEnabled = false;
  bool _eyedropperActive = false;

  final List<Color> colorHistory = <Color>[AppTheme.accent, Colors.white];
  final OnionSkinSettings onionSkin = OnionSkinSettings();

  final List<_UndoEntry> _undoStack = <_UndoEntry>[];
  final List<_UndoEntry> _redoStack = <_UndoEntry>[];

  final Set<int> selectedFrames = <int>{};
  Frame? _frameClipboard;

  bool _playing = false;
  Timer? _playTimer;
  Timer? _saveTimer;

  // ---- Getters ---------------------------------------------------------------

  int get frameIndex => _frameIndex;
  int get layerIndex => _layerIndex.clamp(0, currentFrame.layers.length - 1);
  ToolType get tool => _tool;
  Color get color => _color;
  bool get rulerEnabled => _rulerEnabled;
  bool get eyedropperActive => _eyedropperActive;
  bool get playing => _playing;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasFrameClipboard => _frameClipboard != null;

  Frame get currentFrame => project.frames[_frameIndex];
  Layer get activeLayer => currentFrame.layers[layerIndex];

  // ---- Selection / navigation ------------------------------------------------

  void goToFrame(int index) {
    if (index < 0 || index >= project.frames.length) return;
    _frameIndex = index;
    _layerIndex = _layerIndex.clamp(0, currentFrame.layers.length - 1);
    notifyListeners();
  }

  void selectLayer(int index) {
    _layerIndex = index.clamp(0, currentFrame.layers.length - 1);
    notifyListeners();
  }

  void setTool(ToolType tool) {
    _tool = tool;
    if (tool == ToolType.brush) {
      brush.type = BrushType.ink;
    } else if (tool == ToolType.pencil) {
      brush.type = BrushType.pencil;
    }
    notifyListeners();
  }

  void setBrushType(BrushType type) {
    brush.type = type;
    _tool = ToolType.brush;
    notifyListeners();
  }

  void setColor(Color value) {
    _color = value;
    colorHistory.removeWhere((Color c) => c.toARGB32() == value.toARGB32());
    colorHistory.insert(0, value);
    if (colorHistory.length > 16) {
      colorHistory.removeRange(16, colorHistory.length);
    }
    notifyListeners();
  }

  void setBrushSize(double v) {
    brush.size = v;
    notifyListeners();
  }

  void setOpacity(double v) {
    brush.opacity = v;
    notifyListeners();
  }

  void setHardness(double v) {
    brush.hardness = v;
    notifyListeners();
  }

  void setSpacing(double v) {
    brush.spacing = v;
    notifyListeners();
  }

  void setSmoothing(double v) {
    brush.smoothing = v;
    notifyListeners();
  }

  void toggleRuler() {
    _rulerEnabled = !_rulerEnabled;
    notifyListeners();
  }

  void setEyedropper(bool active) {
    _eyedropperActive = active;
    notifyListeners();
  }

  void updateOnionSkin(void Function(OnionSkinSettings s) update) {
    update(onionSkin);
    notifyListeners();
  }

  // ---- Drawing ---------------------------------------------------------------

  /// Commits a finished stroke to the active layer (respecting lock/hide) and
  /// records it for undo.
  void commitStroke(Stroke stroke) {
    final Layer layer = activeLayer;
    if (!layer.isEditable) return;
    _push(
      undo: () => layer.strokes.remove(stroke),
      redo: () => layer.strokes.add(stroke),
    );
    scheduleSave();
  }

  /// Fill the active layer with a solid rectangle of the current colour. A
  /// lightweight stand-in for flood fill on a stroke-based canvas.
  void fillActiveLayer(Size canvasSize) {
    final Layer layer = activeLayer;
    if (!layer.isEditable) return;
    final Stroke fill = Stroke(
      points: <Offset>[
        Offset.zero,
        Offset(canvasSize.width, canvasSize.height),
      ],
      color: _color,
      brush: brush.copyWith(),
      fill: true,
    );
    _push(
      undo: () => layer.strokes.remove(fill),
      redo: () => layer.strokes.add(fill),
    );
    scheduleSave();
  }

  void clearActiveLayer() {
    final Layer layer = activeLayer;
    if (!layer.isEditable) return;
    final List<Stroke> previous = List<Stroke>.from(layer.strokes);
    _push(
      undo: () => layer.strokes
        ..clear()
        ..addAll(previous),
      redo: () => layer.strokes.clear(),
    );
    scheduleSave();
  }

  // ---- Layers ----------------------------------------------------------------

  void addLayer() {
    final List<Layer> layers = currentFrame.layers;
    if (layers.length >= maxLayers) return;
    final Layer layer = Layer(name: 'Layer ${layers.length + 1}');
    _push(
      undo: () {
        layers.remove(layer);
        _layerIndex = _layerIndex.clamp(0, layers.length - 1);
      },
      redo: () => layers.add(layer),
    );
    _layerIndex = layers.indexOf(layer);
    scheduleSave();
  }

  void deleteLayer(int index) {
    final List<Layer> layers = currentFrame.layers;
    if (layers.length <= 1 || index < 0 || index >= layers.length) return;
    final Layer removed = layers[index];
    _push(
      undo: () => layers.insert(index, removed),
      redo: () {
        layers.remove(removed);
        _layerIndex = _layerIndex.clamp(0, layers.length - 1);
      },
    );
    _layerIndex = _layerIndex.clamp(0, layers.length - 1);
    scheduleSave();
  }

  void duplicateLayer(int index) {
    final List<Layer> layers = currentFrame.layers;
    if (layers.length >= maxLayers || index < 0 || index >= layers.length) {
      return;
    }
    final Layer copy = layers[index].copy(name: '${layers[index].name} copy');
    _push(
      undo: () => layers.remove(copy),
      redo: () => layers.insert(index + 1, copy),
    );
    scheduleSave();
  }

  void renameLayer(int index, String name) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    currentFrame.layers[index].name = name;
    notifyListeners();
    scheduleSave();
  }

  void setLayerOpacity(int index, double opacity) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    currentFrame.layers[index].opacity = opacity;
    notifyListeners();
    scheduleSave();
  }

  void toggleLayerLock(int index) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    currentFrame.layers[index].locked = !currentFrame.layers[index].locked;
    notifyListeners();
    scheduleSave();
  }

  void toggleLayerHidden(int index) {
    if (index < 0 || index >= currentFrame.layers.length) return;
    currentFrame.layers[index].hidden = !currentFrame.layers[index].hidden;
    notifyListeners();
    scheduleSave();
  }

  /// Moves a layer from [fromModel] to [toModel] in model order (0 = bottom).
  /// Final-position semantics: [toModel] is the destination index after removal.
  void moveLayer(int fromModel, int toModel) {
    final List<Layer> layers = currentFrame.layers;
    if (fromModel < 0 || fromModel >= layers.length) return;
    final Layer layer = layers.removeAt(fromModel);
    toModel = toModel.clamp(0, layers.length);
    layers.insert(toModel, layer);
    _layerIndex = layers.indexOf(layer);
    notifyListeners();
    scheduleSave();
  }

  /// Merge the layer at [index] down into the one beneath it.
  void mergeLayerDown(int index) {
    final List<Layer> layers = currentFrame.layers;
    if (index <= 0 || index >= layers.length) return;
    final Layer top = layers[index];
    final Layer below = layers[index - 1];
    final List<Stroke> belowBefore = List<Stroke>.from(below.strokes);
    _push(
      undo: () {
        below.strokes
          ..clear()
          ..addAll(belowBefore);
        layers.insert(index, top);
        _layerIndex = _layerIndex.clamp(0, layers.length - 1);
      },
      redo: () {
        below.strokes.addAll(top.strokes);
        layers.remove(top);
        _layerIndex = _layerIndex.clamp(0, layers.length - 1);
      },
    );
    _layerIndex = _layerIndex.clamp(0, layers.length - 1);
    scheduleSave();
  }

  // ---- Frames ----------------------------------------------------------------

  void addFrame() {
    final Frame frame = Frame();
    final int at = _frameIndex + 1;
    _push(
      undo: () {
        project.frames.remove(frame);
        _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
      },
      redo: () => project.frames.insert(at, frame),
    );
    _frameIndex = at;
    _layerIndex = 0;
    scheduleSave();
  }

  void insertFrameBefore() {
    final Frame frame = Frame();
    final int at = _frameIndex;
    _push(
      undo: () {
        project.frames.remove(frame);
        _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
      },
      redo: () => project.frames.insert(at, frame),
    );
    _layerIndex = 0;
    scheduleSave();
  }

  void duplicateFrame([int? index]) {
    final int src = index ?? _frameIndex;
    if (src < 0 || src >= project.frames.length) return;
    final Frame copy = project.frames[src].copy();
    final int at = src + 1;
    _push(
      undo: () {
        project.frames.remove(copy);
        _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
      },
      redo: () => project.frames.insert(at, copy),
    );
    _frameIndex = at;
    _layerIndex = 0;
    scheduleSave();
  }

  void deleteFrame([int? index]) {
    if (project.frames.length <= 1) return;
    final int at = index ?? _frameIndex;
    if (at < 0 || at >= project.frames.length) return;
    final Frame removed = project.frames[at];
    _push(
      undo: () {
        project.frames.insert(at, removed);
      },
      redo: () {
        project.frames.remove(removed);
        _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
      },
    );
    _frameIndex = at.clamp(0, project.frames.length - 1);
    _layerIndex = 0;
    scheduleSave();
  }

  void copyFrame([int? index]) {
    final int src = index ?? _frameIndex;
    if (src < 0 || src >= project.frames.length) return;
    _frameClipboard = project.frames[src].copy();
    notifyListeners();
  }

  void pasteFrame() {
    final Frame? clip = _frameClipboard;
    if (clip == null) return;
    final Frame copy = clip.copy();
    final int at = _frameIndex + 1;
    _push(
      undo: () {
        project.frames.remove(copy);
        _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
      },
      redo: () => project.frames.insert(at, copy),
    );
    _frameIndex = at;
    _layerIndex = 0;
    scheduleSave();
  }

  void setFrameHold(int index, int hold) {
    if (index < 0 || index >= project.frames.length) return;
    project.frames[index].hold = hold.clamp(1, 99);
    notifyListeners();
    scheduleSave();
  }

  void reorderFrame(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= project.frames.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, project.frames.length - 1);
    final Frame frame = project.frames.removeAt(oldIndex);
    project.frames.insert(newIndex, frame);
    _frameIndex = newIndex;
    notifyListeners();
    scheduleSave();
  }

  void toggleFrameSelection(int index) {
    if (selectedFrames.contains(index)) {
      selectedFrames.remove(index);
    } else {
      selectedFrames.add(index);
    }
    notifyListeners();
  }

  void clearFrameSelection() {
    selectedFrames.clear();
    notifyListeners();
  }

  // ---- Undo / redo -----------------------------------------------------------

  void _push({required VoidCallback undo, required VoidCallback redo}) {
    redo();
    _undoStack.add(_UndoEntry(undo, redo));
    if (_undoStack.length > 100) _undoStack.removeAt(0);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final _UndoEntry entry = _undoStack.removeLast();
    entry.undo();
    _redoStack.add(entry);
    _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
    _layerIndex = _layerIndex.clamp(0, currentFrame.layers.length - 1);
    notifyListeners();
    scheduleSave();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final _UndoEntry entry = _redoStack.removeLast();
    entry.redo();
    _undoStack.add(entry);
    _frameIndex = _frameIndex.clamp(0, project.frames.length - 1);
    _layerIndex = _layerIndex.clamp(0, currentFrame.layers.length - 1);
    notifyListeners();
    scheduleSave();
  }

  // ---- Playback --------------------------------------------------------------

  void togglePlay() {
    if (_playing) {
      stop();
    } else {
      play();
    }
  }

  void play() {
    if (project.frames.length <= 1) return;
    _playing = true;
    final Duration interval =
        Duration(milliseconds: (1000 / project.fps).round());
    _playTimer?.cancel();
    _playTimer = Timer.periodic(interval, (_) {
      _frameIndex = (_frameIndex + 1) % project.frames.length;
      _layerIndex = _layerIndex.clamp(0, currentFrame.layers.length - 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void stop() {
    _playing = false;
    _playTimer?.cancel();
    _playTimer = null;
    notifyListeners();
  }

  void setFps(int fps) {
    project.fps = fps.clamp(1, 24);
    if (_playing) play();
    notifyListeners();
    scheduleSave();
  }

  // ---- Persistence -----------------------------------------------------------

  /// Debounced auto-save. Called after every mutating action; also invoked
  /// directly on app pause via [saveNow].
  void scheduleSave() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), saveNow);
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await _storage.saveProject(project);
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _saveTimer?.cancel();
    // Best-effort final save.
    unawaited(_storage.saveProject(project));
    super.dispose();
  }
}
