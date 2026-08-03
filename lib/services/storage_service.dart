import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

/// Persists projects as individual JSON files under the app documents
/// directory, plus a lightweight `index.json` of [ProjectSummary]s so the home
/// screen can list projects without loading every stroke.
///
/// This is what backs both explicit saves and the editor's debounced auto-save.
class StorageService {
  StorageService();

  Directory? _root;

  Future<Directory> _projectsDir() async {
    if (_root != null) return _root!;
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/faby_projects');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _root = dir;
    return dir;
  }

  File _projectFile(Directory dir, String id) => File('${dir.path}/$id.json');
  File _indexFile(Directory dir) => File('${dir.path}/index.json');

  Future<List<ProjectSummary>> loadIndex() async {
    final Directory dir = await _projectsDir();
    final File index = _indexFile(dir);
    if (!await index.exists()) return <ProjectSummary>[];
    try {
      final dynamic decoded = jsonDecode(await index.readAsString());
      if (decoded is! List) return <ProjectSummary>[];
      return decoded
          .map((dynamic e) =>
              ProjectSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <ProjectSummary>[];
    }
  }

  Future<void> _writeIndex(
    Directory dir,
    List<ProjectSummary> summaries,
  ) async {
    final List<Map<String, dynamic>> data = summaries
        .map((ProjectSummary s) => <String, dynamic>{
              'id': s.id,
              'name': s.name,
              'format': s.format.name,
              'fps': s.fps,
              'favorite': s.favorite,
              'frameCount': s.frameCount,
              'createdAt': s.createdAt.toIso8601String(),
              'updatedAt': s.updatedAt.toIso8601String(),
            })
        .toList();
    await _indexFile(dir).writeAsString(jsonEncode(data));
  }

  Future<Project?> loadProject(String id) async {
    final Directory dir = await _projectsDir();
    final File file = _projectFile(dir, id);
    if (!await file.exists()) return null;
    try {
      final Map<String, dynamic> json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Writes the full project document and refreshes its entry in the index.
  Future<void> saveProject(Project project) async {
    final Directory dir = await _projectsDir();
    project.updatedAt = DateTime.now();
    await _projectFile(dir, project.id)
        .writeAsString(jsonEncode(project.toJson()));

    final List<ProjectSummary> summaries = await loadIndex();
    summaries.removeWhere((ProjectSummary s) => s.id == project.id);
    summaries.add(ProjectSummary.fromJson(project.toSummaryJson()));
    await _writeIndex(dir, summaries);
  }

  Future<void> deleteProject(String id) async {
    final Directory dir = await _projectsDir();
    final File file = _projectFile(dir, id);
    if (await file.exists()) await file.delete();
    final List<ProjectSummary> summaries = await loadIndex();
    summaries.removeWhere((ProjectSummary s) => s.id == id);
    await _writeIndex(dir, summaries);
  }

  Future<void> setFavorite(String id, bool favorite) async {
    final Project? p = await loadProject(id);
    if (p == null) return;
    p.favorite = favorite;
    await saveProject(p);
  }
}
