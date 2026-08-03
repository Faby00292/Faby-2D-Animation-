import 'package:flutter/material.dart';

import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_panel.dart';

/// Workspace top bar: Close, Undo, Redo, Menu and Export.
class TopToolbar extends StatelessWidget {
  const TopToolbar({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onMenu,
    required this.onExport,
  });

  final EditorController controller;
  final VoidCallback onClose;
  final VoidCallback onMenu;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Undo',
            onPressed: controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: controller.canRedo ? controller.redo : null,
            icon: const Icon(Icons.redo),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              controller.project.name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onExport,
            style: FilledButton.styleFrom(
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
