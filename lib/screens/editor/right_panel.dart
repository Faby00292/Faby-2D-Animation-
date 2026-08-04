import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/editor_controller.dart';
import '../../state/settings_store.dart';
import '../../theme/app_theme.dart';
import 'brush_settings_sheet.dart';
import 'color_picker_sheet.dart';

/// Right-hand brush settings panel: brush engine, color, size, opacity,
/// hardness and ruler.
class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final settings = context.watch<SettingsStore>();

    void openBrush() => BrushSettingsSheet.show(
          context,
          controller: context.read<EditorController>(),
          settings: context.read<SettingsStore>(),
        );
    void openColor() => ColorPickerSheet.show(
          context,
          controller: context.read<EditorController>(),
          settings: context.read<SettingsStore>(),
        );

    return Container(
      width: 212,
      decoration: const BoxDecoration(
        color: FabyColors.surface,
        border: Border(left: BorderSide(color: FabyColors.outline)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _BrushButton(
            icon: controller.brushType.icon,
            label: controller.brushType.label,
            onTap: openBrush,
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Brush Color'),
          const SizedBox(height: 10),
          _ColorButton(color: controller.brushColor, onTap: openColor),
          if (settings.colorHistory.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in settings.colorHistory.take(6))
                  _MiniSwatch(
                    color: color,
                    selected: controller.brushColor.toARGB32() ==
                        color.toARGB32(),
                    onTap: () => controller.setColor(color),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          _LabeledSlider(
            label: 'Brush Size',
            value: controller.brushSize,
            min: 1,
            max: 100,
            display: '${controller.brushSize.round()} px',
            onChanged: controller.setSize,
          ),
          _LabeledSlider(
            label: 'Opacity',
            value: controller.brushOpacity,
            min: 0,
            max: 1,
            display: '${(controller.brushOpacity * 100).round()}%',
            onChanged: controller.setOpacity,
          ),
          _LabeledSlider(
            label: 'Hardness',
            value: controller.brushHardness,
            min: 0,
            max: 1,
            display: '${(controller.brushHardness * 100).round()}%',
            onChanged: controller.setHardness,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Ruler'),
            value: controller.rulerEnabled,
            activeThumbColor: FabyColors.turquoise,
            onChanged: (_) => controller.toggleRuler(),
          ),
        ],
      ),
    );
  }
}

class _BrushButton extends StatelessWidget {
  const _BrushButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FabyColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: FabyColors.turquoise),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.tune, size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: FabyColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _MiniSwatch extends StatelessWidget {
  const _MiniSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? FabyColors.turquoise : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
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
      children: [
        Row(
          children: [
            _SectionLabel(label),
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
