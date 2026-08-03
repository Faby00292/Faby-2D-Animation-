import 'package:flutter/material.dart';

import '../../../models/brush.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';

/// Bottom sheet exposing brush type selection plus the full parameter set
/// (size, opacity, hardness, spacing, smoothing). Includes an entry point for
/// creating a custom brush.
class BrushSettingsSheet extends StatelessWidget {
  const BrushSettingsSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final BrushSettings b = controller.brush;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Text('Brush', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final BrushType type in BrushType.values)
                      _BrushChip(
                        type: type,
                        selected: b.type == type,
                        onTap: () => controller.setBrushType(type),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _slider('Size', b.size, 1, 120,
                    '${b.size.round()} px', controller.setBrushSize),
                _slider('Opacity', b.opacity, 0.05, 1,
                    '${(b.opacity * 100).round()}%', controller.setOpacity),
                _slider('Hardness', b.hardness, 0, 1,
                    '${(b.hardness * 100).round()}%', controller.setHardness),
                _slider('Spacing', b.spacing, 0.01, 1,
                    '${(b.spacing * 100).round()}%', controller.setSpacing),
                _slider('Smoothing', b.smoothing, 0, 1,
                    '${(b.smoothing * 100).round()}%', controller.setSmoothing),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () {
                    controller.setBrushType(BrushType.custom);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Custom brush selected — tune the sliders above to '
                          'shape it.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create custom brush'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    String display,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(label),
              const Spacer(),
              Text(
                display,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BrushChip extends StatelessWidget {
  const _BrushChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final BrushType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        type.icon,
        size: 18,
        color: selected ? Colors.black : null,
      ),
      label: Text(type.label),
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.accent,
      labelStyle: TextStyle(
        color: selected ? Colors.black : null,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
