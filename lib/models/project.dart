import 'frame.dart';
import 'project_format.dart';

/// A single animation project.
class Project {
  Project({
    required this.id,
    required this.name,
    required this.format,
    required this.fps,
    List<Frame>? frames,
    DateTime? createdAt,
  })  : frames = frames ?? <Frame>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  ProjectFormat format;

  /// Playback rate, constrained to 1..24 by the creation dialog.
  int fps;

  final List<Frame> frames;
  final DateTime createdAt;
}
