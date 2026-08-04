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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'format': format.name,
        'fps': fps,
        'createdAt': createdAt.toIso8601String(),
        'frames': [for (final f in frames) f.toJson()],
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Untitled',
        format: ProjectFormat.fromName(json['format'] as String?),
        fps: (json['fps'] as num?)?.toInt() ?? 12,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        frames: [
          for (final f in (json['frames'] as List? ?? const []))
            Frame.fromJson(f as Map<String, dynamic>),
        ],
      );
}
