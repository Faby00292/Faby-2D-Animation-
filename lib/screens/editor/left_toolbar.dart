import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tool.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Vertical tool picker on the left edge of the editor.
class LeftToolbar extends StatelessWidget {
  const LeftToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    return Container(
      width: 60,
      decoration: const BoxDecoration(
        color: FabyColors.surface,
        border: Border(right: BorderSide(color: FabyColors.outline)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final tool in EditorTool.values)
              _ToolButton(
                tool: tool,
                selected: controller.tool == tool,
                onTap: () => controller.selectTool(tool),
              ),
          ],
        ),
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

  final EditorTool tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Tooltip(
        message: tool.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? FabyColors.turquoise.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? FabyColors.turquoise
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              tool.icon,
              size: 22,
              color: selected ? FabyColors.turquoise : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
