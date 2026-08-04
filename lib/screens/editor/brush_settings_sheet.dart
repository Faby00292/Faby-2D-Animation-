import 'package:flutter/material.dart';

import '../../models/brush_preset.dart';
import '../../models/brush_type.dart';
import '../../state/editor_controller.dart';
import '../../state/settings_store.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet for choosing a brush engine, tuning spacing/smoothing and
/// managing saved custom brushes.
class BrushSettingsSheet extends StatelessWidget {
  const BrushSettingsSheet({
    super.key,
    required this.controller,
    required this.settings,
  });

  final EditorController controller;
  final SettingsStore settings;

  static Future<void> show(
    BuildContext context, {
    required EditorController controller,
    required SettingsStore settings,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FabyColors.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          BrushSettingsSheet(controller: controller, settings: settings),
    );
  }

  Future<void> _saveCustomBrush(BuildContext context) async {
    final nameController = TextEditingController(
      text: '${controller.brushType.label} brush',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save custom brush'),
        content: TextField(
          controller: nameController,
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
            onPressed: () =>
                Navigator.of(dialogContext).pop(nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.trim().isEmpty) return;
    settings.addCustomBrush(controller.toPreset(name.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, settings]),
        builder: (context, _) {
          final customBrushes = settings.customBrushes;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brush',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final type in BrushType.values)
                      if (type != BrushType.custom)
                        _TypeChip(
                          type: type,
                          selected: controller.brushType == type,
                          onTap: () => controller.selectBrushType(type),
                        ),
                  ],
                ),
                const SizedBox(height: 20),
                _LabeledSlider(
                  label: 'Spacing',
                  value: controller.brushSpacing,
                  display: '${(controller.brushSpacing * 100).round()}%',
                  onChanged: controller.setSpacing,
                ),
                _LabeledSlider(
                  label: 'Smoothing',
                  value: controller.brushSmoothing,
                  display: '${(controller.brushSmoothing * 100).round()}%',
                  onChanged: controller.setSmoothing,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Custom Brushes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _saveCustomBrush(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Save current'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (customBrushes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Save your current brush settings to reuse them later.',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  )
                else
                  ...customBrushes.map(
                    (preset) => _CustomBrushTile(
                      preset: preset,
                      onApply: () => controller.applyPreset(preset),
                      onDelete: () => settings.removeCustomBrush(preset.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final BrushType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? FabyColors.turquoise.withValues(alpha: 0.16)
              : FabyColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? FabyColors.turquoise : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 18,
              color: selected ? FabyColors.turquoise : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: TextStyle(
                color: selected ? FabyColors.turquoise : Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBrushTile extends StatelessWidget {
  const _CustomBrushTile({
    required this.preset,
    required this.onApply,
    required this.onDelete,
  });

  final BrushPreset preset;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: FabyColors.surface,
      child: ListTile(
        onTap: onApply,
        leading: Icon(preset.type.icon, color: FabyColors.turquoise),
        title: Text(preset.name),
        subtitle: Text(
          '${preset.type.label} · ${preset.size.round()} px · '
          '${(preset.opacity * 100).round()}%',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Text(
              display,
              style: const TextStyle(
                fontSize: 12,
                color: FabyColors.turquoise,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0.0, 1.0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
