import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../drawing/drawing_canvas.dart';
import '../../models/project.dart';
import '../../state/editor_controller.dart';
import '../../state/project_store.dart';
import '../../theme/app_theme.dart';
import 'import_sheet.dart';
import 'layers_panel.dart';
import 'left_toolbar.dart';
import 'onion_settings_sheet.dart';
import 'right_panel.dart';
import 'timeline_panel.dart';
import 'top_toolbar.dart';

/// The main animation workspace for a single [Project].
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.project});

  final Project project;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final EditorController _controller;
  final TransformationController _transform = TransformationController();
  ProjectStore? _projectStore;

  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = EditorController(widget.project);
    _transform.addListener(_onTransformChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captured so we can persist edits from dispose(), where the context may
    // no longer resolve providers.
    _projectStore = context.read<ProjectStore>();
  }

  @override
  void dispose() {
    _projectStore?.save();
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transform.value.getMaxScaleOnAxis();
    if ((scale - _zoom).abs() > 0.001) {
      setState(() => _zoom = scale);
    }
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoomPercent = (_zoom * 100).round();
    final showReset = (_zoom - 1.0).abs() > 0.01;

    return ChangeNotifierProvider<EditorController>.value(
      value: _controller,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: FabyColors.background,
        endDrawer: const LayersPanel(),
        body: SafeArea(
          child: Column(
            children: [
              TopToolbar(
                onClose: () => Navigator.of(context).maybePop(),
                onOpenOnion: () => OnionSettingsSheet.show(
                  context,
                  controller: _controller,
                ),
                onOpenLayers: () => _scaffoldKey.currentState?.openEndDrawer(),
                onMenu: () =>
                    ImportSheet.show(context, controller: _controller),
                onExport: () => _comingSoon('Export'),
              ),
              Expanded(
                child: Row(
                  children: [
                    const LeftToolbar(),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DrawingCanvas(
                              controller: _controller,
                              transformationController: _transform,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: _ZoomIndicator(
                              percent: zoomPercent,
                              showReset: showReset,
                              onReset: _resetZoom,
                            ),
                          ),
                          Consumer<EditorController>(
                            builder: (context, controller, _) {
                              if (!controller.eyedropperMode) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                top: 12,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _EyedropperBanner(
                                    onCancel: () =>
                                        controller.setEyedropperMode(false),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const RightPanel(),
                  ],
                ),
              ),
              const TimelinePanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EyedropperBanner extends StatelessWidget {
  const _EyedropperBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FabyColors.surfaceHigh.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.colorize, size: 18, color: FabyColors.turquoise),
            const SizedBox(width: 8),
            const Text('Tap the canvas to pick a color'),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onCancel,
              tooltip: 'Cancel',
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomIndicator extends StatelessWidget {
  const _ZoomIndicator({
    required this.percent,
    required this.showReset,
    required this.onReset,
  });

  final int percent;
  final bool showReset;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FabyColors.surfaceHigh.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: showReset ? onReset : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (showReset) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.center_focus_strong,
                  size: 18,
                  color: FabyColors.turquoise,
                ),
                const SizedBox(width: 2),
                const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 12,
                    color: FabyColors.turquoise,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
