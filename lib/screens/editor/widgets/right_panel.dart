import 'package:flutter/material.dart';

import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_panel.dart';

/// Right-hand quick controls: brush size, colour swatch, opacity, hardness and
/// a ruler toggle. A "more" button opens the full brush settings sheet.
class RightPanel extends StatelessWidget {
  const RightPanel({
    super.key,
    required this.controller,
    required this.onOpenColor,
    required this.onOpenBrushSettings,
  });

  final EditorController controller;
  final VoidCallback onOpenColor;
  final VoidCallback onOpenBrushSettings;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: 190,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text('Color', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onOpenColor,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: controller.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => controller.setEyedropper(true),
                icon: Icon(
                  Icons.colorize,
                  size: 18,
                  color: controller.eyedropperActive ? AppTheme.accent : null,
                ),
                label: const Text('Eyedropper'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                ),
              ),
              const Divider(height: 22),
              _SliderRow(
                label: 'Size',
                value: controller.brush.size,
                min: 1,
                max: 120,
                display: '${controller.brush.size.round()}',
                onChanged: controller.setBrushSize,
              ),
              _SliderRow(
                label: 'Opacity',
                value: controller.brush.opacity,
                min: 0.05,
                max: 1,
                display: '${(controller.brush.opacity * 100).round()}%',
                onChanged: controller.setOpacity,
              ),
              _SliderRow(
                label: 'Hardness',
                value: controller.brush.hardness,
                min: 0,
                max: 1,
                display: '${(controller.brush.hardness * 100).round()}%',
                onChanged: controller.setHardness,
              ),
              const Divider(height: 22),
              Row(
                children: <Widget>[
                  const Icon(Icons.straighten, size: 18),
                  const SizedBox(width: 8),
                  const Text('Ruler', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Switch(
                    value: controller.rulerEnabled,
                    onChanged: (_) => controller.toggleRuler(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton.tonalIcon(
                onPressed: onOpenBrushSettings,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Brush settings'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Text(
              display,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
