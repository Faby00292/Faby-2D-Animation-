import 'package:flutter/material.dart';

import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';

/// Settings for onion skinning: how many previous/next frames to ghost, their
/// tint colours and overall opacity.
class OnionSkinSheet extends StatelessWidget {
  const OnionSkinSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final OnionSkinSettings s = controller.onionSkin;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.layers_outlined, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Text('Onion skin',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Switch(
                    value: s.enabled,
                    onChanged: (bool v) =>
                        controller.updateOnionSkin((OnionSkinSettings o) {
                      o.enabled = v;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _counter(
                context,
                'Previous frames',
                s.prevFrames,
                (int v) => controller.updateOnionSkin(
                    (OnionSkinSettings o) => o.prevFrames = v),
              ),
              _counter(
                context,
                'Next frames',
                s.nextFrames,
                (int v) => controller.updateOnionSkin(
                    (OnionSkinSettings o) => o.nextFrames = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _colorRow(
                      'Previous',
                      s.prevColor,
                      <Color>[
                        const Color(0xFFFF5A7A),
                        const Color(0xFFFF8A65),
                        const Color(0xFFBA68C8),
                      ],
                      (Color c) => controller.updateOnionSkin(
                          (OnionSkinSettings o) => o.prevColor = c),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _colorRow(
                      'Next',
                      s.nextColor,
                      <Color>[
                        const Color(0xFF55A8FF),
                        const Color(0xFF4DD0E1),
                        const Color(0xFF81C784),
                      ],
                      (Color c) => controller.updateOnionSkin(
                          (OnionSkinSettings o) => o.nextColor = c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Opacity ${(s.opacity * 100).round()}%'),
              Slider(
                value: s.opacity,
                min: 0.05,
                max: 1,
                onChanged: (double v) => controller
                    .updateOnionSkin((OnionSkinSettings o) => o.opacity = v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _counter(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text(label),
          const Spacer(),
          IconButton.filledTonal(
            onPressed:
                value > 0 ? () => onChanged((value - 1).clamp(0, 10)) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.filledTonal(
            onPressed:
                value < 10 ? () => onChanged((value + 1).clamp(0, 10)) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _colorRow(
    String label,
    Color selected,
    List<Color> choices,
    ValueChanged<Color> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            for (final Color c in choices)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.toARGB32() == selected.toARGB32()
                            ? Colors.white
                            : Colors.white24,
                        width: c.toARGB32() == selected.toARGB32() ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
