import 'package:flutter/material.dart';

import '../../../models/brush.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_panel.dart';

/// Vertical tool rail: Brush, Pencil, Eraser, Fill, Text, Blur, Lasso.
class LeftToolbar extends StatelessWidget {
  const LeftToolbar({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final ToolType tool in ToolType.values)
            _ToolButton(
              tool: tool,
              selected: controller.tool == tool,
              onTap: () => controller.setTool(tool),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final ToolType tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tool.label,
        child: Material(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(
                tool.icon,
                color: selected
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
