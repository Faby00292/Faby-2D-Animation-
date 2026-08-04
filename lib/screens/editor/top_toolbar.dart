import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// The editor's top toolbar: close, undo, redo, project title, layers, menu,
/// and export.
class TopToolbar extends StatelessWidget {
  const TopToolbar({
    super.key,
    required this.onClose,
    required this.onOpenOnion,
    required this.onOpenLayers,
    required this.onMenu,
    required this.onExport,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenOnion;
  final VoidCallback onOpenLayers;
  final VoidCallback onMenu;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: FabyColors.surface,
        border: Border(
          bottom: BorderSide(color: FabyColors.outline),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: onClose,
          ),
          const VerticalDivider(indent: 12, endIndent: 12),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: controller.canUndo ? controller.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: controller.canRedo ? controller.redo : null,
          ),
          Expanded(
            child: Text(
              controller.project.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.animation),
            tooltip: 'Onion skin',
            color: controller.onionEnabled ? FabyColors.turquoise : null,
            onPressed: onOpenOnion,
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Layers',
            onPressed: onOpenLayers,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onPressed: onMenu,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('Export'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
