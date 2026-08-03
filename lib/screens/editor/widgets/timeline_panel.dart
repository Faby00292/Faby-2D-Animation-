import 'package:flutter/material.dart';

import '../../../models/frame.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_panel.dart';
import 'stroke_painter.dart';

/// The timeline: a play transport, frame operations and a draggable, thumbnail
/// frame strip supporting selection and per-frame hold (duration).
class TimelinePanel extends StatelessWidget {
  const TimelinePanel({
    super.key,
    required this.controller,
    required this.onLayers,
    required this.onOnionSkin,
  });

  final EditorController controller;
  final VoidCallback onLayers;
  final VoidCallback onOnionSkin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return GlassPanel(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _controls(context),
              const SizedBox(height: 6),
              SizedBox(height: 84, child: _strip(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _controls(BuildContext context) {
    final bool hasSelection = controller.selectedFrames.isNotEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: controller.playing ? 'Stop' : 'Play',
            onPressed: controller.togglePlay,
            icon: Icon(
              controller.playing ? Icons.stop : Icons.play_arrow,
              color: AppTheme.accent,
            ),
          ),
          _sep(),
          IconButton(
            tooltip: 'Add frame',
            onPressed: controller.addFrame,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Duplicate frame',
            onPressed: () => controller.duplicateFrame(),
            icon: const Icon(Icons.control_point_duplicate),
          ),
          IconButton(
            tooltip: 'Insert before',
            onPressed: controller.insertFrameBefore,
            icon: const Icon(Icons.playlist_add),
          ),
          IconButton(
            tooltip: 'Copy frame',
            onPressed: () => controller.copyFrame(),
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: 'Paste frame',
            onPressed:
                controller.hasFrameClipboard ? controller.pasteFrame : null,
            icon: const Icon(Icons.paste),
          ),
          IconButton(
            tooltip: 'Delete frame',
            onPressed: () => controller.deleteFrame(),
            icon: const Icon(Icons.delete_outline),
          ),
          _sep(),
          IconButton(
            tooltip: 'Onion skin',
            onPressed: onOnionSkin,
            icon: Icon(
              Icons.layers_outlined,
              color: controller.onionSkin.enabled ? AppTheme.accent : null,
            ),
          ),
          IconButton(
            tooltip: 'Layers',
            onPressed: onLayers,
            icon: const Icon(Icons.layers),
          ),
          if (hasSelection) ...<Widget>[
            _sep(),
            Chip(
              label: Text('${controller.selectedFrames.length} selected'),
              onDeleted: controller.clearFrameSelection,
            ),
            IconButton(
              tooltip: 'Delete selected',
              onPressed: () => _deleteSelected(),
              icon: const Icon(Icons.delete_sweep),
            ),
          ],
        ],
      ),
    );
  }

  void _deleteSelected() {
    final List<int> indices = controller.selectedFrames.toList()
      ..sort((int a, int b) => b.compareTo(a));
    for (final int i in indices) {
      controller.deleteFrame(i);
    }
    controller.clearFrameSelection();
  }

  Widget _sep() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white12,
      );

  Widget _strip(BuildContext context) {
    final List<Frame> frames = controller.project.frames;
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      itemCount: frames.length,
      onReorder: (int oldIndex, int newIndex) =>
          controller.reorderFrame(oldIndex, newIndex),
      proxyDecorator: (Widget child, int index, Animation<double> animation) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (BuildContext context, int index) {
        final Frame frame = frames[index];
        final bool current = controller.frameIndex == index;
        final bool selected = controller.selectedFrames.contains(index);
        return ReorderableDelayedDragStartListener(
          key: ValueKey<String>(frame.id),
          index: index,
          child: _FrameThumb(
            controller: controller,
            frame: frame,
            index: index,
            current: current,
            selected: selected,
          ),
        );
      },
    );
  }
}

class _FrameThumb extends StatelessWidget {
  const _FrameThumb({
    required this.controller,
    required this.frame,
    required this.index,
    required this.current,
    required this.selected,
  });

  final EditorController controller;
  final Frame frame;
  final int index;
  final bool current;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final double aspect = controller.project.format.aspectRatio;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () => controller.goToFrame(index),
        onLongPress: () => controller.toggleFrameSelection(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: current
                          ? AppTheme.accent
                          : (selected ? Colors.orangeAccent : Colors.white24),
                      width: current || selected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      height: 54,
                      child: AspectRatio(
                        aspectRatio: aspect,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: controller.project.format.width.toDouble(),
                            height: controller.project.format.height.toDouble(),
                            child: CustomPaint(
                              size: controller.project.format.size,
                              painter: StrokePainter(
                                frame: frame,
                                onion: const <OnionLayerSpec>[],
                                liveStroke: null,
                                background: Colors.white,
                                repaint:
                                    const AlwaysStoppedAnimation<double>(0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
                if (frame.hold > 1)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => _editHold(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '×${frame.hold}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            GestureDetector(
              onTap: () => _editHold(context),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'hold ${frame.hold}',
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editHold(BuildContext context) async {
    controller.goToFrame(index);
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, _) {
            final int hold = controller.project.frames[index].hold;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Frame ${index + 1} duration',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'How many timeline slots this drawing occupies.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: hold > 1
                            ? () => controller.setFrameHold(index, hold - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$hold',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () =>
                            controller.setFrameHold(index, hold + 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
