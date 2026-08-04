import 'package:flutter/material.dart';

import '../state/editor_controller.dart';
import 'drawing_painter.dart';

/// The zoomable drawing surface.
///
/// Wraps the painted page in an [InteractiveViewer] for pinch-zoom (up to
/// 6400%) and pan. Single-finger input draws via a raw [Listener] (which sees
/// pointer events regardless of the viewer's gesture recognizers); a second
/// finger cancels the in-progress stroke and hands off to pinch-zoom.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.transformationController,
  });

  final EditorController controller;
  final TransformationController transformationController;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  int _pointers = 0;
  bool _drawing = false;

  Size _fit(Size available, double aspect) {
    final w = available.width;
    final h = available.height;
    if (w <= 0 || h <= 0) return const Size(1, 1);
    if (w / h > aspect) {
      return Size(h * aspect, h);
    }
    return Size(w, w / aspect);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final format = controller.project.format;
    final formatSize = Size(format.width.toDouble(), format.height.toDouble());

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = Size(constraints.maxWidth, constraints.maxHeight);
        final display = _fit(
          Size(available.width - 32, available.height - 32),
          format.aspectRatio,
        );
        final scale = display.width / formatSize.width;

        Offset toCanvas(Offset local) => local / scale;

        return InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: 0.25,
          maxScale: 64,
          panEnabled: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Center(
            child: Listener(
              onPointerDown: (event) {
                _pointers++;
                if (_pointers == 1) {
                  _drawing = true;
                  controller.startStroke(toCanvas(event.localPosition));
                } else if (_drawing) {
                  _drawing = false;
                  controller.cancelStroke();
                }
              },
              onPointerMove: (event) {
                if (_pointers == 1 && _drawing) {
                  controller.extendStroke(toCanvas(event.localPosition));
                }
              },
              onPointerUp: (event) {
                if (_pointers > 0) _pointers--;
                if (_pointers == 0 && _drawing) {
                  _drawing = false;
                  controller.endStroke();
                }
              },
              onPointerCancel: (event) {
                if (_pointers > 0) _pointers--;
                if (_pointers == 0 && _drawing) {
                  _drawing = false;
                  controller.endStroke();
                }
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: display.width,
                  height: display.height,
                  child: CustomPaint(
                    size: display,
                    painter: DrawingPainter(
                      frame: controller.currentFrame,
                      formatSize: formatSize,
                      repaint: controller,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
