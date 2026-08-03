import 'package:flutter/material.dart';

import '../../../models/layer.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';

/// Layer manager for the current frame: add / duplicate / merge / delete,
/// rename, reorder (drag), opacity, lock and hide. Capped at
/// [EditorController.maxLayers] (10). Displayed top-drawn-first.
class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final List<Layer> layers = controller.currentFrame.layers;
        final int count = layers.length;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.layers, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Text('Layers', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '$count / ${EditorController.maxLayers}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: count < EditorController.maxLayers
                        ? controller.addLayer
                        : null,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: count,
                  onReorder: (int oldD, int newD) {
                    if (newD > oldD) newD -= 1;
                    final int fromModel = (count - 1) - oldD;
                    final int toModel = (count - 1) - newD;
                    controller.moveLayer(fromModel, toModel);
                  },
                  itemBuilder: (BuildContext context, int displayIndex) {
                    final int modelIndex = (count - 1) - displayIndex;
                    final Layer layer = layers[modelIndex];
                    return _LayerTile(
                      key: ValueKey<String>(layer.id),
                      controller: controller,
                      layer: layer,
                      modelIndex: modelIndex,
                      displayIndex: displayIndex,
                      selected: controller.layerIndex == modelIndex,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.controller,
    required this.layer,
    required this.modelIndex,
    required this.displayIndex,
    required this.selected,
  });

  final EditorController controller;
  final Layer layer;
  final int modelIndex;
  final int displayIndex;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected
          ? AppTheme.accent.withValues(alpha: 0.14)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppTheme.accent : Colors.white12,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.selectLayer(modelIndex),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  ReorderableDragStartListener(
                    index: displayIndex,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.drag_indicator, size: 20),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.toggleLayerHidden(modelIndex),
                    icon: Icon(
                      layer.hidden ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: layer.hidden ? Colors.white38 : null,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.toggleLayerLock(modelIndex),
                    icon: Icon(
                      layer.locked ? Icons.lock : Icons.lock_open,
                      size: 20,
                      color: layer.locked ? AppTheme.accent : null,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _rename(context),
                      child: Text(
                        layer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: layer.hidden ? Colors.white38 : null,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String v) => _onMenu(context, v),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                          value: 'rename',
                          child: _MenuRow(Icons.edit, 'Rename')),
                      const PopupMenuItem<String>(
                          value: 'duplicate',
                          child: _MenuRow(Icons.copy, 'Duplicate')),
                      if (modelIndex > 0)
                        const PopupMenuItem<String>(
                            value: 'merge',
                            child: _MenuRow(Icons.merge, 'Merge down')),
                      const PopupMenuItem<String>(
                          value: 'delete',
                          child: _MenuRow(Icons.delete_outline, 'Delete')),
                    ],
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  const SizedBox(width: 8),
                  const Icon(Icons.opacity, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: layer.opacity,
                        onChanged: (double v) =>
                            controller.setLayerOpacity(modelIndex, v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(layer.opacity * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMenu(BuildContext context, String value) {
    switch (value) {
      case 'rename':
        _rename(context);
      case 'duplicate':
        controller.duplicateLayer(modelIndex);
      case 'merge':
        controller.mergeLayerDown(modelIndex);
      case 'delete':
        controller.deleteLayer(modelIndex);
    }
  }

  Future<void> _rename(BuildContext context) async {
    final TextEditingController field =
        TextEditingController(text: layer.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Rename layer'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Layer name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(field.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      controller.renameLayer(modelIndex, name);
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
