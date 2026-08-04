import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/frame.dart';
import '../models/layer.dart';
import '../models/project.dart';
import '../models/project_format.dart';

/// Store of the user's projects, persisted to [SharedPreferences] as JSON.
class ProjectStore extends ChangeNotifier {
  static const String _key = 'faby_projects';

  final List<Project> _projects = <Project>[];
  int _seq = 0;
  bool _loaded = false;
  SharedPreferences? _prefs;

  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoaded => _loaded;

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  /// Loads persisted projects. Safe to call once at startup.
  Future<void> load() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _projects
          ..clear()
          ..addAll(
            list.map((p) => Project.fromJson(p as Map<String, dynamic>)),
          );
      } catch (_) {
        // Ignore corrupt data and start fresh.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Creates a project seeded with one frame containing one layer, inserts it
  /// at the top of the list and returns it.
  Project createProject({
    required String name,
    required ProjectFormat format,
    required int fps,
  }) {
    final trimmed = name.trim();
    final layer = Layer(id: _id('layer_'), name: 'Layer 1');
    final frame = Frame(id: _id('frame_'), layers: <Layer>[layer]);
    final project = Project(
      id: _id('proj_'),
      name: trimmed.isEmpty ? 'Untitled' : trimmed,
      format: format,
      fps: fps.clamp(1, 24),
      frames: <Frame>[frame],
    );
    _projects.insert(0, project);
    save();
    notifyListeners();
    return project;
  }

  void deleteProject(Project project) {
    _projects.remove(project);
    save();
    notifyListeners();
  }

  /// Persists the current project list. Call after edits (e.g. on editor exit).
  void save() {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = jsonEncode([for (final p in _projects) p.toJson()]);
    prefs.setString(_key, raw);
  }
}
