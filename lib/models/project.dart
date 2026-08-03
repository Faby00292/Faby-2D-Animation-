import 'package:uuid/uuid.dart';

import 'format_preset.dart';
import 'frame.dart';

const Uuid _uuid = Uuid();

/// Top-level document. A project owns an ordered list of [Frame]s, a canvas
/// [format], a playback [fps], and light metadata used by the home screen
/// (favourite flag, timestamps) for search and filtering.
class Project {
  Project({
    String? id,
    required this.name,
    required this.format,
    this.fps = 12,
    List<Frame>? frames,
    this.favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        frames = frames ?? <Frame>[Frame()],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  FormatPreset format;
  int fps;
  final List<Frame> frames;
  bool favorite;
  final DateTime createdAt;
  DateTime updatedAt;

  int get frameCount => frames.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'format': format.name,
        'fps': fps,
        'favorite': favorite,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'frames': <Map<String, dynamic>>[
          for (final Frame f in frames) f.toJson(),
        ],
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Untitled',
        format: FormatPreset.fromName(json['format'] as String?),
        fps: (json['fps'] as num?)?.toInt() ?? 12,
        favorite: json['favorite'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
        frames: <Frame>[
          for (final dynamic f in (json['frames'] as List<dynamic>? ?? <dynamic>[]))
            Frame.fromJson(f as Map<String, dynamic>),
        ],
      );

  /// A lightweight summary for the home grid — avoids deserialising every
  /// stroke of every frame just to list projects.
  Map<String, dynamic> toSummaryJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'format': format.name,
        'fps': fps,
        'favorite': favorite,
        'frameCount': frameCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Metadata-only view of a project used on the home screen.
class ProjectSummary {
  ProjectSummary({
    required this.id,
    required this.name,
    required this.format,
    required this.fps,
    required this.favorite,
    required this.frameCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final FormatPreset format;
  final int fps;
  bool favorite;
  final int frameCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled',
        format: FormatPreset.fromName(json['format'] as String?),
        fps: (json['fps'] as num?)?.toInt() ?? 12,
        favorite: json['favorite'] as bool? ?? false,
        frameCount: (json['frameCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
