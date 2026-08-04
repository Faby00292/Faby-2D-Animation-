import 'package:flutter/foundation.dart';

import '../models/frame.dart';
import '../models/layer.dart';
import '../models/project.dart';
import '../models/project_format.dart';

/// In-memory store of the user's projects.
///
/// Persistence (shared_preferences / sqflite) is planned for a later phase;
/// for the vertical slice projects live for the duration of the app session.
class ProjectStore extends ChangeNotifier {
  final List<Project> _projects = <Project>[];
  int _seq = 0;

  List<Project> get projects => List.unmodifiable(_projects);

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

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
    notifyListeners();
    return project;
  }

  void deleteProject(Project project) {
    _projects.remove(project);
    notifyListeners();
  }
}
