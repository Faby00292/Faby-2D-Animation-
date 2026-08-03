import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../services/storage_service.dart';
import '../../state/editor_controller.dart';
import '../../state/settings_controller.dart';
import 'widgets/brush_settings_sheet.dart';
import 'widgets/color/color_picker_sheet.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/layers_panel.dart';
import 'widgets/left_toolbar.dart';
import 'widgets/onion_skin_sheet.dart';
import 'widgets/right_panel.dart';
import 'widgets/timeline_panel.dart';
import 'widgets/top_toolbar.dart';

/// The workspace. Owns the [EditorController] for the [project] and lays out the
/// drawing canvas with its floating glass toolbars, side panel and timeline.
/// Saves on lifecycle pause and when closed.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.project});

  final Project project;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  late final EditorController _controller;

  @override
  void initState() {
    super.initState();
    final StorageService storage = context.read<StorageService>();
    _controller = EditorController(storage, widget.project);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _controller.saveNow();
    }
  }

  Future<void> _close() async {
    await _controller.saveNow();
    if (mounted) Navigator.of(context).pop();
  }

  void _openColorPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ColorPickerSheet(
        initial: _controller.color,
        history: _controller.colorHistory,
        onChanged: _controller.setColor,
        onPickFromCanvas: () {
          Navigator.of(context).pop();
          _controller.setEyedropper(true);
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('Tap the canvas to pick a colour.'),
            ),
          );
        },
      ),
    );
  }

  void _openBrushSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrushSettingsSheet(controller: _controller),
    );
  }

  void _openLayers() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.7,
        child: LayersPanel(controller: _controller),
      ),
    );
  }

  void _openOnionSkin() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OnionSkinSheet(controller: _controller),
    );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.layers_clear),
              title: const Text('Clear active layer'),
              onTap: () {
                Navigator.of(context).pop();
                _controller.clearActiveLayer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: Text('Frame rate: ${_controller.project.fps} FPS'),
              onTap: () {
                Navigator.of(context).pop();
                _editFps();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import (coming soon)'),
              enabled: false,
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Audio (coming soon)'),
              enabled: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editFps() async {
    double fps = _controller.project.fps.toDouble();
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Frame rate: ${fps.round()} FPS',
                      style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: fps,
                    min: 1,
                    max: 24,
                    divisions: 23,
                    label: '${fps.round()}',
                    onChanged: (double v) {
                      setModalState(() => fps = v);
                      _controller.setFps(v.round());
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _export() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Export (MP4 / GIF / PNG sequence) is coming in a later update.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, _) => _controller.saveNow(),
      child: Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: DrawingCanvas(
                      controller: _controller,
                      settings: settings,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: TopToolbar(
                      controller: _controller,
                      onClose: _close,
                      onMenu: _openMenu,
                      onExport: _export,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 80,
                    bottom: 120,
                    child: Center(child: LeftToolbar(controller: _controller)),
                  ),
                  Positioned(
                    right: 8,
                    top: 80,
                    bottom: 120,
                    child: Center(
                      child: RightPanel(
                        controller: _controller,
                        onOpenColor: _openColorPicker,
                        onOpenBrushSettings: _openBrushSettings,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: TimelinePanel(
                      controller: _controller,
                      onLayers: _openLayers,
                      onOnionSkin: _openOnionSkin,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
