import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// End-drawer listing the current frame's layers (max 10), top-most first, with
/// visibility, lock, opacity, drag-to-reorder and a rename / duplicate / merge
/// / delete menu.
class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key});

  Future<void> _rename(
    BuildContext context,
    EditorController controller,
    int index,
    String current,
  ) async {
    final textController = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename layer'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(textController.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (name != null) controller.renameLayer(index, name);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final layers = controller.currentFrame.layers;
    final count = layers.length;

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
                    '$count/${EditorController.maxLayers}',
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
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: count,
                onReorderItem: controller.reorderLayers,
                itemBuilder: (context, displayIndex) {
                  // Display top-most first; map to the model index.
                  final index = count - 1 - displayIndex;
                  final layer = layers[index];
                  return _LayerTile(
                    key: ValueKey(layer.id),
                    displayIndex: displayIndex,
                    name: layer.name,
                    opacity: layer.opacity,
                    isVisible: layer.isVisible,
                    isLocked: layer.isLocked,
                    selected: controller.currentLayerIndex == index,
                    canDelete: count > 1,
                    canMergeDown: index > 0,
                    canDuplicate: controller.canAddLayer,
                    onSelect: () => controller.selectLayer(index),
                    onToggleVisible: () => controller.toggleLayerVisible(index),
                    onToggleLock: () => controller.toggleLayerLock(index),
                    onOpacity: (v) => controller.setLayerOpacity(index, v),
                    onRename: () =>
                        _rename(context, controller, index, layer.name),
                    onDuplicate: () => controller.duplicateLayer(index),
                    onMergeDown: () => controller.mergeLayerDown(index),
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

enum _LayerAction { rename, duplicate, mergeDown, delete }

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.displayIndex,
    required this.name,
    required this.opacity,
    required this.isVisible,
    required this.isLocked,
    required this.selected,
    required this.canDelete,
    required this.canMergeDown,
    required this.canDuplicate,
    required this.onSelect,
    required this.onToggleVisible,
    required this.onToggleLock,
    required this.onOpacity,
    required this.onRename,
    required this.onDuplicate,
    required this.onMergeDown,
    required this.onDelete,
  });

  final int displayIndex;
  final String name;
  final double opacity;
  final bool isVisible;
  final bool isLocked;
  final bool selected;
  final bool canDelete;
  final bool canMergeDown;
  final bool canDuplicate;
  final VoidCallback onSelect;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleLock;
  final ValueChanged<double> onOpacity;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onMergeDown;
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
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
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
                    onDoubleTap: onRename,
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
                ReorderableDragStartListener(
                  index: displayIndex,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_indicator,
                        size: 20, color: Colors.white38),
                  ),
                ),
                PopupMenuButton<_LayerAction>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    switch (action) {
                      case _LayerAction.rename:
                        onRename();
                      case _LayerAction.duplicate:
                        onDuplicate();
                      case _LayerAction.mergeDown:
                        onMergeDown();
                      case _LayerAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _LayerAction.rename,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Rename'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _LayerAction.duplicate,
                      enabled: canDuplicate,
                      child: const ListTile(
                        leading: Icon(Icons.copy_all_outlined),
                        title: Text('Duplicate'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _LayerAction.mergeDown,
                      enabled: canMergeDown,
                      child: const ListTile(
                        leading: Icon(Icons.merge_type),
                        title: Text('Merge down'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _LayerAction.delete,
                      enabled: canDelete,
                      child: const ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
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
