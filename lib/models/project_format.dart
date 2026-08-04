/// Export/canvas presets offered when creating a new project.
///
/// Each format defines the pixel dimensions of the drawing canvas. The list
/// mirrors the presets from the product brief.
enum ProjectFormat {
  youtube1080('YouTube (1080p)', 1920, 1080),
  youtube720('YouTube (720p)', 1280, 720),
  instagram169('Instagram (16:9)', 1920, 1080),
  instagram11('Instagram (1:1)', 1080, 1080),
  tiktok1080('TikTok (1080p)', 1080, 1920),
  tiktok720('TikTok (720p)', 720, 1280),
  vimeo1080('Vimeo (1080p)', 1920, 1080),
  facebook720('Facebook (720p)', 1280, 720),
  tumblr169('Tumblr (16:9)', 1920, 1080),
  tumblr43('Tumblr (4:3)', 1440, 1080);

  const ProjectFormat(this.label, this.width, this.height);

  /// Human-readable name shown in the UI.
  final String label;

  /// Canvas width in pixels.
  final int width;

  /// Canvas height in pixels.
  final int height;

  /// Width / height, used to lay out the canvas and previews.
  double get aspectRatio => width / height;

  /// e.g. "1920 × 1080".
  String get dimensionsLabel => '$width × $height';
}
