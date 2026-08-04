import 'package:flutter/material.dart';

import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet controlling onion-skin display: enable, previous/next frames,
/// frame count, tint colors and opacity.
class OnionSettingsSheet extends StatelessWidget {
  const OnionSettingsSheet({super.key, required this.controller});

  final EditorController controller;

  static const List<Color> _colorOptions = [
    Color(0xFFFF5A5A), Color(0xFFFF9500), Color(0xFFFFCC00),
    Color(0xFF34C759), Color(0xFF55E4C1), Color(0xFF4F9DFF),
    Color(0xFFAF52DE), Color(0xFFFF2D55),
  ];

  static Future<void> show(
    BuildContext context, {
    required EditorController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FabyColors.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => OnionSettingsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final enabled = controller.onionEnabled;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.animation, color: FabyColors.turquoise),
                    const SizedBox(width: 10),
                    const Text(
                      'Onion Skin',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Switch(
                      value: enabled,
                      activeThumbColor: FabyColors.turquoise,
                      onChanged: controller.setOnionEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: enabled ? 1 : 0.4,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Previous frames'),
                          value: controller.onionShowPrevious,
                          activeThumbColor: FabyColors.turquoise,
                          onChanged: controller.setOnionShowPrevious,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Next frames'),
                          value: controller.onionShowNext,
                          activeThumbColor: FabyColors.turquoise,
                          onChanged: controller.setOnionShowNext,
                        ),
                        const SizedBox(height: 8),
                        _label('Number of frames'),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: controller.onionFrameCount.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: '${controller.onionFrameCount}',
                                onChanged: (v) =>
                                    controller.setOnionFrameCount(v.round()),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${controller.onionFrameCount}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: FabyColors.turquoise,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _label('Opacity'),
                        Slider(
                          value: controller.onionOpacity,
                          onChanged: controller.setOnionOpacity,
                        ),
                        const SizedBox(height: 12),
                        _label('Previous frame color'),
                        const SizedBox(height: 8),
                        _ColorRow(
                          options: _colorOptions,
                          selected: controller.onionPrevColor,
                          onSelected: controller.setOnionPrevColor,
                        ),
                        const SizedBox(height: 16),
                        _label('Next frame color'),
                        const SizedBox(height: 8),
                        _ColorRow(
                          options: _colorOptions,
                          selected: controller.onionNextColor,
                          onSelected: controller.setOnionNextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> options;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in options)
          GestureDetector(
            onTap: () => onSelected(color),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.toARGB32() == selected.toARGB32()
                      ? Colors.white
                      : Colors.white24,
                  width: color.toARGB32() == selected.toARGB32() ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
