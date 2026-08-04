/// An imported audio track attached to a project. Playback lands in a later
/// phase; for now the file is copied into app storage and referenced by path.
class AudioTrack {
  const AudioTrack({required this.name, required this.path});

  final String name;
  final String path;

  Map<String, dynamic> toJson() => {'name': name, 'path': path};

  factory AudioTrack.fromJson(Map<String, dynamic> json) => AudioTrack(
        name: json['name'] as String? ?? 'Audio',
        path: json['path'] as String? ?? '',
      );
}
