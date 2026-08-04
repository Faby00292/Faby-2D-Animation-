import 'package:flutter/material.dart';

/// Tools available in the editor's left toolbar.
///
/// [brush], [pencil] and [eraser] are wired up for the vertical slice; the
/// remaining tools are selectable placeholders scheduled for later phases.
enum EditorTool {
  brush('Brush', Icons.brush),
  pencil('Pencil', Icons.create),
  eraser('Eraser', Icons.cleaning_services),
  fill('Fill', Icons.format_color_fill),
  text('Text', Icons.text_fields),
  blur('Blur', Icons.blur_on),
  lasso('Lasso', Icons.gesture);

  const EditorTool(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Whether the tool produces freehand strokes on the canvas.
  bool get isDrawing =>
      this == EditorTool.brush ||
      this == EditorTool.pencil ||
      this == EditorTool.eraser;
}
