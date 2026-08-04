import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Right-hand brush settings panel: color, size, opacity, hardness and ruler.
class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  static const List<Color> _palette = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFF55E4C1),
    Color(0xFF4F9DFF),
    Color(0xFF9B6BFF),
    Color(0xFFFF6B9B),
    Color(0xFFFF784F),
    Color(0xFFFFC24F),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    return Container(
      width: 208,
      decoration: const BoxDecoration(
        color: FabyColors.surface,
        border: Border(left: BorderSide(color: FabyColors.outline)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _SectionLabel('Brush Color'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _palette)
                _Swatch(
                  color: color,
                  selected: controller.brushColor.toARGB32() == color.toARGB32(),
                  onTap: () => controller.setColor(color),
                ),
            ],
          ),
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

class _Swatch extends StatelessWidget {
  const _Swatch({
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? FabyColors.turquoise : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
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
