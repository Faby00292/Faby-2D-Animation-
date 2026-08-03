# Faby 2D Animation

A modern, frame-by-frame **2D animation editor** for Android, built with Flutter
and Material 3 — a minimalist dark UI with turquoise (`#55E4C1`) accents,
glassmorphism panels and large, comfortable controls.

> This is the **first development iteration**: a runnable foundation with a deep
> drawing/brush engine. Import, audio and export are stubbed with "coming soon"
> placeholders and land in later iterations (see [Roadmap](#roadmap)).

## Features in this build

**Library / start page**
- Project grid with format-aware previews
- Search + filters: Recent, Name, Favorites
- Create projects with a name, one of 10 format presets, and 1–24 FPS
- Delete and favourite projects; auto-save keeps everything on device

**Workspace**
- Custom pan/zoom canvas: **one finger draws, two fingers pinch-zoom/pan**
- Zoom **10%–6400%** with a one-tap **reset-to-100%** chip when off 100%
- Top toolbar: Close · Undo · Redo · Menu · Export
- Left tool rail: Brush · Pencil · Eraser · Fill · Text* · Blur · Lasso*
- Right panel: colour · eyedropper · size · opacity · hardness · ruler toggle

**Brush engine**
- Brush types: Pencil, Ink, Marker, Airbrush, Watercolor, Pixel, Chalk, Custom
- Per-brush size, opacity, hardness, spacing and smoothing
- Eraser (per-layer) and Fill

**Colour**
- HSV colour wheel + brightness, RGB sliders, HEX entry
- Preset palette, recent-colour history, and canvas eyedropper

**Timeline**
- Add / insert / duplicate / copy / paste / delete frames
- Drag-to-reorder, multi-select (long-press), per-frame hold/duration
- Loop playback at the project FPS

**Layers** (up to 10 per frame)
- Create, delete, rename, reorder, duplicate, merge-down
- Opacity, lock and hide

**Onion skin**
- Configurable previous/next frame counts, tint colours and opacity

**Settings**
- Dark / Light / System theme
- Language selector (scaffolded)
- Input method: finger, stylus, or both (filters canvas input)

\* Text and Lasso appear as tools but show a "coming soon" notice.

## Getting started

This container the app was authored in has no Flutter SDK, so it has **not been
compiled here**. On a machine with Flutter **3.27+**:

```bash
# 1. Generate any missing platform/binary files (e.g. the Gradle wrapper).
#    This is idempotent and leaves existing source files in place.
flutter create --org com.faby --project-name faby_2d_animation .

# 2. Fetch dependencies.
flutter pub get

# 3. Static analysis (expected clean).
flutter analyze

# 4. Run on an Android emulator or device.
flutter run
```

To build a debug APK: `flutter build apk --debug`.

## Architecture

```
lib/
  main.dart                 # bootstraps providers, loads settings + project index
  app.dart                  # MaterialApp + theme wiring
  theme/                    # Material 3 dark/light theme, glassmorphism panel
  models/                   # Project → Frame → Layer → Stroke, brushes, formats
  services/storage_service  # JSON persistence (documents dir) + project index
  state/                    # provider ChangeNotifiers
    projects_controller     #   home library, search/filter, CRUD
    editor_controller       #   active project: tools, undo/redo, playback, autosave
    settings_controller     #   theme, language, input method
  screens/
    home/                   # start page, project card, new-project dialog
    editor/                 # workspace + widgets/ (canvas, toolbars, timeline,
                            #   layers, onion skin, brush settings, colour picker)
    settings/               # preferences
```

- **State**: `provider` (`ChangeNotifier`).
- **Persistence**: projects are individual JSON files plus a lightweight
  `index.json` of summaries, so the library lists without loading every stroke.
  The editor debounces auto-save and also saves on app pause/close.
- **Rendering**: a single `CustomPainter` (`StrokePainter`) draws paper, onion
  skin, layers (each in its own compositing group so the eraser and layer
  opacity behave) and the live stroke. Strokes are stored in canvas-pixel space,
  making them resolution-independent for thumbnails and future export.

## Roadmap

Planned for later iterations (present as "coming soon" in the UI):

- **Import**: PNG/JPG images, MP4/GIF video
- **Audio**: MP3/WAV with trim, fade, volume, waveform and frame sync
- **Objects**: video and image objects (scale/rotate/crop/speed)
- **Advanced text** (outline, shadow, gradient) and **shapes**
- **Export**: MP4, GIF, PNG/JPEG sequences, transparent PNG sequence
