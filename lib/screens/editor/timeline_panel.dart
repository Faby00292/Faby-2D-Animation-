import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../drawing/drawing_painter.dart';
import '../../models/frame.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Bottom timeline showing frame thumbnails with add / delete controls.
class TimelinePanel extends StatelessWidget {
  const TimelinePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final frames = controller.project.frames;
    final format = controller.project.format;
    final formatSize = Size(format.width.toDouble(), format.height.toDouble());

    return Container(
      height: 108,
      decoration: const BoxDecoration(
        color: FabyColors.surface,
        border: Border(top: BorderSide(color: FabyColors.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              itemCount: frames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _FrameThumb(
                index: index,
                frame: frames[index],
                formatSize: formatSize,
                selected: controller.currentFrameIndex == index,
                onTap: () => controller.selectFrame(index),
              ),
            ),
          ),
          Container(width: 1, color: FabyColors.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: controller.addFrame,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add frame',
                  style: IconButton.styleFrom(
                    backgroundColor: FabyColors.turquoise,
                    foregroundColor: const Color(0xFF00382E),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: frames.length > 1
                      ? () => controller
                          .deleteFrame(controller.currentFrameIndex)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete frame',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameThumb extends StatelessWidget {
  const _FrameThumb({
    required this.index,
    required this.frame,
    required this.formatSize,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final Frame frame;
  final Size formatSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final aspect = formatSize.width / formatSize.height;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? FabyColors.turquoise : Colors.white24,
                width: selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: aspect,
              child: SizedBox(
                height: 60,
                child: CustomPaint(
                  painter: DrawingPainter(
                    frame: frame,
                    formatSize: formatSize,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11,
              color: selected ? FabyColors.turquoise : Colors.white54,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
