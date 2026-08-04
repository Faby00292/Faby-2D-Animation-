import 'package:flutter/material.dart';

import '../../services/export_service.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet offering export options: animated GIF, PNG frame, and MP4
/// (stubbed pending a native encoder).
class ExportSheet extends StatelessWidget {
  const ExportSheet({super.key, required this.controller});

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
      builder: (_) => ExportSheet(controller: controller),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<String> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Rendering…')),
    );
    try {
      final message = await action();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _videoInfo(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'MP4 export needs a native encoder (planned). '
          'Export as GIF for now.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Export',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          _ExportTile(
            icon: Icons.gif_box_outlined,
            title: 'Animated GIF',
            subtitle: 'Whole animation, honoring frame holds',
            onTap: () =>
                _run(context, () => ExportService.exportGif(controller)),
          ),
          _ExportTile(
            icon: Icons.image_outlined,
            title: 'PNG (current frame)',
            subtitle: 'Export the frame you\'re viewing',
            onTap: () => _run(
                context, () => ExportService.exportCurrentFramePng(controller)),
          ),
          _ExportTile(
            icon: Icons.movie_outlined,
            title: 'Video (MP4)',
            subtitle: 'Requires a native encoder — planned',
            onTap: () => _videoInfo(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
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
