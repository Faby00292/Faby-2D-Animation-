import 'package:flutter/material.dart';

/// Export/canvas format presets offered in the New Project dialog.
///
/// Each preset carries a pixel resolution used as the drawing canvas size and
/// as the default export resolution. Aspect is derived from width/height.
enum FormatPreset {
  youtube1080('YouTube', '1080p', 1920, 1080),
  youtube720('YouTube', '720p', 1280, 720),
  instagram169('Instagram', '16:9', 1920, 1080),
  instagram11('Instagram', '1:1', 1080, 1080),
  tiktok1080('TikTok', '1080p', 1080, 1920),
  tiktok720('TikTok', '720p', 720, 1280),
  vimeo1080('Vimeo', '1080p', 1920, 1080),
  facebook720('Facebook', '720p', 1280, 720),
  tumblr169('Tumblr', '16:9', 1920, 1080),
  tumblr43('Tumblr', '4:3', 1440, 1080);

  const FormatPreset(this.platform, this.variant, this.width, this.height);

  final String platform;
  final String variant;
  final int width;
  final int height;

  String get label => '$platform ($variant)';
  double get aspectRatio => width / height;
  Size get size => Size(width.toDouble(), height.toDouble());

  static FormatPreset fromName(String? name) {
    return FormatPreset.values.firstWhere(
      (FormatPreset f) => f.name == name,
      orElse: () => FormatPreset.youtube1080,
    );
  }
}
