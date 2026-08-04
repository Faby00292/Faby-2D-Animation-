import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../drawing/drawing_painter.dart';
import '../../models/frame.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

/// Bottom timeline: frame thumbnails with copy/paste/duplicate/insert/extend,
/// per-frame hold, drag-and-drop reordering and multi-frame selection.
class TimelinePanel extends StatelessWidget {
  const TimelinePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final frames = controller.project.frames;
    final format = controller.project.format;
    final formatSize = Size(format.width.toDouble(), format.height.toDouble());

    return Container(
      height: 156,
      decoration: const BoxDecoration(
        color: FabyColors.surface,
        border: Border(top: BorderSide(color: FabyColors.outline)),
      ),
      child: Column(
        children: [
          controller.hasFrameSelection
              ? _SelectionHeader(controller: controller)
              : _ActionHeader(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.all(10),
                    itemCount: frames.length,
                    onReorderItem: controller.reorderFrames,
                    itemBuilder: (context, index) {
                      final frame = frames[index];
                      return Padding(
                        key: ValueKey(frame.id),
                        padding: const EdgeInsets.only(right: 10),
                        child: _FrameTile(
                          index: index,
                          frame: frame,
                          formatSize: formatSize,
                          isActive: controller.currentFrameIndex == index,
                          isSelected: controller.isFrameSelected(frame.id),
                          selectionMode: controller.hasFrameSelection,
                          onTap: () {
                            if (controller.hasFrameSelection) {
                              controller.toggleFrameSelected(frame.id);
                            } else {
                              controller.selectFrame(index);
                            }
                          },
                          onLongPress: () =>
                              controller.toggleFrameSelected(frame.id),
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(width: 1, color: FabyColors.outline),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: IconButton.filled(
                      onPressed: controller.addFrame,
                      icon: const Icon(Icons.add),
                      tooltip: 'Add frame',
                      style: IconButton.styleFrom(
                        backgroundColor: FabyColors.turquoise,
                        foregroundColor: const Color(0xFF00382E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionHeader extends StatelessWidget {
  const _ActionHeader({required this.controller});

  final EditorController controller;

  Future<void> _extend(BuildContext context) async {
    final count = await showDialog<int>(
      context: context,
      builder: (_) => const _ExtendDialog(),
    );
    if (count != null && count > 0) controller.extendFrame(count);
  }

  @override
  Widget build(BuildContext context) {
    final index = controller.currentFrameIndex;
    final frames = controller.project.frames;
    final hold = frames[index].holdCount;

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(
              'Frame ${index + 1}/${frames.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Text(
              '· ${controller.durationSeconds.toStringAsFixed(1)}s',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const _HeaderDivider(),
            _HeaderButton(
              icon: Icons.copy,
              tooltip: 'Copy frame',
              onPressed: () => controller.copyFrame(),
            ),
            _HeaderButton(
              icon: Icons.content_paste,
              tooltip: 'Paste frame',
              onPressed: controller.canPaste ? controller.pasteFrame : null,
            ),
            _HeaderButton(
              icon: Icons.control_point_duplicate,
              tooltip: 'Duplicate frame',
              onPressed: () => controller.duplicateFrame(),
            ),
            _HeaderButton(
              icon: Icons.playlist_add,
              tooltip: 'Insert blank frame',
              onPressed: controller.insertBlankFrame,
            ),
            _HeaderButton(
              icon: Icons.more_time,
              tooltip: 'Extend across frames',
              onPressed: () => _extend(context),
            ),
            _HeaderButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete frame',
              onPressed: frames.length > 1
                  ? () => controller.deleteFrame(index)
                  : null,
            ),
            const _HeaderDivider(),
            _HoldStepper(
              hold: hold,
              onChanged: (delta) => controller.changeFrameHold(index, delta),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear selection',
              onPressed: controller.clearFrameSelection,
            ),
            Text(
              '${controller.selectedFrameCount} selected',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            _HeaderButton(
              icon: Icons.control_point_duplicate,
              tooltip: 'Duplicate selected',
              onPressed: controller.duplicateSelectedFrames,
            ),
            _HeaderButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete selected',
              onPressed: controller.deleteSelectedFrames,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldStepper extends StatelessWidget {
  const _HoldStepper({required this.hold, required this.onChanged});

  final int hold;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Hold',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove, size: 18),
          onPressed: hold > 1 ? () => onChanged(-1) : null,
        ),
        Text('$hold', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 18),
          onPressed: hold < 99 ? () => onChanged(1) : null,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: FabyColors.outline,
    );
  }
}

class _FrameTile extends StatelessWidget {
  const _FrameTile({
    required this.index,
    required this.frame,
    required this.formatSize,
    required this.isActive,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.dragHandle,
  });

  final int index;
  final Frame frame;
  final Size formatSize;
  final bool isActive;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final aspect = formatSize.width / formatSize.height;
    final borderColor = isSelected
        ? FabyColors.turquoise
        : isActive
            ? FabyColors.turquoise
            : Colors.white24;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: (isActive || isSelected) ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: aspect,
                  child: SizedBox(
                    height: 64,
                    child: CustomPaint(
                      painter: DrawingPainter(
                        frame: frame,
                        formatSize: formatSize,
                      ),
                    ),
                  ),
                ),
              ),
              if (frame.holdCount > 1)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${frame.holdCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: FabyColors.turquoise,
                      ),
                    ),
                  ),
                ),
              if (selectionMode)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: isSelected ? FabyColors.turquoise : Colors.white54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? FabyColors.turquoise : Colors.white54,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              dragHandle,
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtendDialog extends StatefulWidget {
  const _ExtendDialog();

  @override
  State<_ExtendDialog> createState() => _ExtendDialogState();
}

class _ExtendDialogState extends State<_ExtendDialog> {
  double _count = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Extend across frames'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add ${_count.round()} copies of this frame',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _count,
            min: 1,
            max: 24,
            divisions: 23,
            label: '${_count.round()}',
            onChanged: (v) => setState(() => _count = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_count.round()),
          child: const Text('Extend'),
        ),
      ],
    );
  }
}
