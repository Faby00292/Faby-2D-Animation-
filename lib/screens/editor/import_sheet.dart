import 'package:flutter/material.dart';

import '../../services/import_service.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet offering media import: still images, GIF animations, video and
/// audio.
class ImportSheet extends StatelessWidget {
  const ImportSheet({super.key, required this.controller});

  final EditorController controller;

  static Future<void> show(
    BuildContext context, {
    required EditorController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: FabyColors.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ImportSheet(controller: controller),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<String> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    try {
      final message = await action();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _videoInfo(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'MP4 import needs a native video decoder (planned). '
          'Import animated GIFs for now.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final audio = controller.project.audio;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Import',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              _ImportTile(
                icon: Icons.image_outlined,
                title: 'Image',
                subtitle: 'PNG or JPG onto a new layer',
                onTap: () => _run(context, () => ImportService.importImage(controller)),
              ),
              _ImportTile(
                icon: Icons.gif_box_outlined,
                title: 'Animation (GIF)',
                subtitle: 'Each GIF frame becomes a project frame',
                onTap: () => _run(context, () => ImportService.importGif(controller)),
              ),
              _ImportTile(
                icon: Icons.movie_outlined,
                title: 'Video (MP4)',
                subtitle: 'Requires a native decoder — planned',
                onTap: () => _videoInfo(context),
              ),
              _ImportTile(
                icon: Icons.music_note_outlined,
                title: 'Audio',
                subtitle: 'Import your own music',
                onTap: () => _run(context, () => ImportService.importAudio(controller)),
              ),
              if (audio != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FabyColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.audiotrack,
                            color: FabyColors.turquoise, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            audio.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Remove audio',
                          onPressed: () => controller.setAudioTrack(null),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: FabyColors.turquoise.withValues(alpha: 0.14),
        child: Icon(icon, color: FabyColors.turquoise),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
