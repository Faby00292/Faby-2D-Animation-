import 'package:flutter/material.dart';

import '../models/format_preset.dart';
import '../models/project.dart';
import '../services/storage_service.dart';

/// How the home grid is ordered / filtered.
enum ProjectSort { updated, name, favorites }

/// Owns the list of project summaries shown on the home screen and mediates
/// create/delete/favourite through [StorageService]. The editor loads and saves
/// full [Project] documents separately.
class ProjectsController extends ChangeNotifier {
  ProjectsController(this._storage);

  final StorageService _storage;

  List<ProjectSummary> _all = <ProjectSummary>[];
  String _query = '';
  ProjectSort _sort = ProjectSort.updated;
  bool _loading = true;

  bool get loading => _loading;
  String get query => _query;
  ProjectSort get sort => _sort;

  StorageService get storage => _storage;

  List<ProjectSummary> get visible {
    Iterable<ProjectSummary> list = _all;
    if (_query.trim().isNotEmpty) {
      final String q = _query.toLowerCase();
      list = list.where((ProjectSummary s) => s.name.toLowerCase().contains(q));
    }
    final List<ProjectSummary> result = list.toList();
    switch (_sort) {
      case ProjectSort.updated:
        result.sort((ProjectSummary a, ProjectSummary b) =>
            b.updatedAt.compareTo(a.updatedAt));
      case ProjectSort.name:
        result.sort((ProjectSummary a, ProjectSummary b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ProjectSort.favorites:
        result
          ..retainWhere((ProjectSummary s) => s.favorite)
          ..sort((ProjectSummary a, ProjectSummary b) =>
              b.updatedAt.compareTo(a.updatedAt));
    }
    return result;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _storage.loadIndex();
    _loading = false;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(ProjectSort sort) {
    _sort = sort;
    notifyListeners();
  }

  /// Creates, persists and returns a new project (which the caller opens).
  Future<Project> create({
    required String name,
    required FormatPreset format,
    required int fps,
  }) async {
    final Project project = Project(
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
      format: format,
      fps: fps,
    );
    await _storage.saveProject(project);
    await load();
    return project;
  }

  Future<void> delete(String id) async {
    await _storage.deleteProject(id);
    await load();
  }

  Future<void> toggleFavorite(String id) async {
    ProjectSummary? summary;
    for (final ProjectSummary s in _all) {
      if (s.id == id) {
        summary = s;
        break;
      }
    }
    if (summary == null) return;
    await _storage.setFavorite(id, !summary.favorite);
    await load();
  }
}
