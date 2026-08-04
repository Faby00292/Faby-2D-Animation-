# Faby 2D Animation

A professional frame-by-frame 2D animation editor for **Android and iOS**, built
with Flutter — a modern, minimalist take on apps like FlipaClip, with a dark
theme, turquoise accents (`#55E4C1`), glassmorphism panels and Material 3.

This repository currently contains the **foundation + a working vertical slice**:
the project scaffolding plus an end-to-end flow from the start page to a
functional drawing workspace. The remaining features are stubbed and scheduled
in the roadmap below.

## Implemented in this slice

- **Start page** — project grid with empty state, a "New Project" button and a
  settings sheet.
- **New Project dialog** — name, all 10 export formats (YouTube, Instagram,
  TikTok, Vimeo, Facebook, Tumblr) and a 1–24 FPS slider.
- **Workspace**
  - Zoomable/pannable canvas (pinch-zoom up to 6400%) with a one-tap
    **reset-to-100%** control.
  - **Top toolbar**: close, undo, redo, layers, menu, export.
  - **Left toolbar**: Brush, Pencil, Eraser, Fill, Text, Blur, Lasso (brush /
    pencil / eraser are functional; the rest are selectable placeholders).
  - **Right panel**: brush color, size, opacity, hardness and a ruler toggle.
  - **Drawing engine**: freehand strokes with per-stroke color, size, opacity
    and softness (hardness → blur); eraser cuts within its own layer.
  - **Timeline**: frame thumbnails with add / delete, **copy / paste**,
    **duplicate**, **insert**, **extend-across-frames**, per-frame **hold /
    duration**, **drag-and-drop reordering** and **multi-frame selection**.
  - **Layers**: up to 10 layers with visibility, lock, opacity, add / delete,
    **rename**, **duplicate**, **merge down** and **drag-to-reorder**.
- **Persistence** — projects are saved to device storage and restored on
  relaunch.
- **8 brush engines** — Pencil, Ink, Marker, Airbrush, Watercolor, Pixel, Chalk
  and Custom, each with a distinct look, plus per-brush **spacing** and
  **smoothing**, and **saveable custom brushes**.
- **Full color picker** — HSV wheel + value, RGB sliders, HEX input, preset
  palette, recent-color history and an **eyedropper** that samples the canvas.
- **Onion skin** — ghosted previous/next frames with configurable frame count,
  per-direction tint colors and opacity.
- **Import** — PNG/JPG images (onto a new layer), animated **GIFs** (each GIF
  frame becomes a project frame) and **audio** (copied into app storage). MP4
  import is stubbed pending a native video decoder.

## Architecture

```
lib/
  main.dart                 App entry + theme + ProjectStore provider
  models/                   Project, Frame, Layer, Stroke, ProjectFormat, EditorTool
  state/                    ProjectStore, EditorController (ChangeNotifier)
  theme/                    Dark Material 3 theme, GlassPanel
  drawing/                  DrawingCanvas (InteractiveViewer) + DrawingPainter
  screens/home/             HomeScreen, NewProjectDialog, ProjectCard
  screens/editor/           EditorScreen + toolbars/panels
```

State is managed with `provider` (`ChangeNotifier`). Projects live in memory for
this slice; persistence is planned (see roadmap).

## Getting started

```bash
flutter pub get
flutter run          # Android device/emulator, or iOS on macOS/Xcode
flutter analyze      # static analysis
flutter test         # widget smoke test
```

> An APK/IPA build requires the platform SDKs (Android SDK; Xcode for iOS).

## Roadmap

- **Phase 2** ✅ — persistence; full color picker (RGB/HEX/HSV/wheel/palette/
  history/eyedropper); 8 brush types + custom brushes; spacing/smoothing.
- **Phase 3** ✅ — full timeline (copy/paste/duplicate/insert/hold/duration,
  drag-reorder, multi-select, extend-across-frames).
- **Phase 4** ✅ — full layers (rename/reorder/merge/duplicate).
- **Phase 5** ✅ — onion skin.
- **Phase 6** 🚧 — import PNG/JPG + GIF (any length) + audio done; MP4 frame
  extraction pending a native (FFmpeg) decoder.
- **Phase 7** — export/render + playback.
