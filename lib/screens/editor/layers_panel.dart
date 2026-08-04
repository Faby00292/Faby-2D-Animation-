import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// End-drawer listing the current frame's layers (max 10) with visibility,
/// lock, opacity and add/delete controls.
class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final layers = controller.currentFrame.layers;

    return Drawer(
      backgroundColor: FabyColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    'Layers',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${layers.length}/${EditorController.maxLayers}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add layer',
                    onPressed:
                        controller.canAddLayer ? controller.addLayer : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              // Layers are shown top-most first, matching the canvas stack.
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: layers.length,
                itemBuilder: (context, i) {
                  final index = layers.length - 1 - i;
                  final layer = layers[index];
                  final selected = controller.currentLayerIndex == index;
                  return _LayerTile(
                    name: layer.name,
                    opacity: layer.opacity,
                    isVisible: layer.isVisible,
                    isLocked: layer.isLocked,
                    selected: selected,
                    canDelete: layers.length > 1,
                    onSelect: () => controller.selectLayer(index),
                    onToggleVisible: () =>
                        controller.toggleLayerVisible(index),
                    onToggleLock: () => controller.toggleLayerLock(index),
                    onOpacity: (v) => controller.setLayerOpacity(index, v),
                    onDelete: () => controller.deleteLayer(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.name,
    required this.opacity,
    required this.isVisible,
    required this.isLocked,
    required this.selected,
    required this.canDelete,
    required this.onSelect,
    required this.onToggleVisible,
    required this.onToggleLock,
    required this.onOpacity,
    required this.onDelete,
  });

  final String name;
  final double opacity;
  final bool isVisible;
  final bool isLocked;
  final bool selected;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleLock;
  final ValueChanged<double> onOpacity;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? FabyColors.turquoise.withValues(alpha: 0.10)
            : FabyColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? FabyColors.turquoise : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                  ),
                  onPressed: onToggleVisible,
                  tooltip: isVisible ? 'Hide' : 'Show',
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onSelect,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    size: 20,
                  ),
                  onPressed: onToggleLock,
                  tooltip: isLocked ? 'Unlock' : 'Lock',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: canDelete ? onDelete : null,
                  tooltip: 'Delete layer',
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.opacity,
                    size: 16, color: Colors.white.withValues(alpha: 0.5)),
                Expanded(
                  child: Slider(
                    value: opacity,
                    onChanged: onOpacity,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(opacity * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
