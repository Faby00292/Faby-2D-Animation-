import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/editor_controller.dart';
import '../../state/settings_store.dart';
import '../../theme/app_theme.dart';

/// Full-featured color picker: HSV wheel + value, RGB sliders, HEX input,
/// preset palette, recent-color history and an eyedropper hand-off.
class ColorPickerSheet extends StatefulWidget {
  const ColorPickerSheet({
    super.key,
    required this.controller,
    required this.settings,
  });

  final EditorController controller;
  final SettingsStore settings;

  static Future<void> show(
    BuildContext context, {
    required EditorController controller,
    required SettingsStore settings,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FabyColors.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          ColorPickerSheet(controller: controller, settings: settings),
    );
  }

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  static const double _wheelSize = 220;
  static const List<Color> _palette = [
    Color(0xFF000000), Color(0xFF7F7F7F), Color(0xFFFFFFFF),
    Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFCC00),
    Color(0xFF34C759), Color(0xFF55E4C1), Color(0xFF00C7BE),
    Color(0xFF32ADE6), Color(0xFF007AFF), Color(0xFF5856D6),
    Color(0xFFAF52DE), Color(0xFFFF2D55), Color(0xFFA2845E),
  ];

  late HSVColor _hsv;
  final TextEditingController _hexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.controller.brushColor);
    _syncHex();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();
  int get _r => (_color.toARGB32() >> 16) & 0xFF;
  int get _g => (_color.toARGB32() >> 8) & 0xFF;
  int get _b => _color.toARGB32() & 0xFF;

  void _update(HSVColor value) {
    setState(() => _hsv = value);
    _syncHex();
    widget.controller.setColor(_color);
  }

  void _setColor(Color color) => _update(HSVColor.fromColor(color));

  void _syncHex() {
    final hex = (_color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    _hexController.text = '#$hex';
  }

  void _applyHex(String text) {
    var hex = text.replaceAll('#', '').trim();
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        _setColor(Color(0xFF000000 | value));
        return;
      }
    }
    _syncHex(); // revert on invalid input
  }

  void _onWheelDrag(Offset local) {
    const c = Offset(_wheelSize / 2, _wheelSize / 2);
    final v = local - c;
    var hue = math.atan2(v.dy, v.dx) * 180 / math.pi;
    if (hue < 0) hue += 360;
    final sat = (v.distance / (_wheelSize / 2)).clamp(0.0, 1.0);
    _update(HSVColor.fromAHSV(1, hue, sat, _hsv.value));
  }

  void _done() {
    widget.settings.addColorToHistory(_color);
    Navigator.of(context).pop();
  }

  void _startEyedropper() {
    Navigator.of(context).pop();
    widget.controller.setEyedropperMode(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tap the canvas to pick a color')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markerRad = _hsv.hue * math.pi / 180;
    final markerDist = _hsv.saturation * (_wheelSize / 2);
    final markerX = _wheelSize / 2 + math.cos(markerRad) * markerDist;
    final markerY = _wheelSize / 2 + math.sin(markerRad) * markerDist;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Color',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _startEyedropper,
                  icon: const Icon(Icons.colorize),
                  tooltip: 'Eyedropper',
                ),
                FilledButton(onPressed: _done, child: const Text('Done')),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: _wheelSize,
                height: _wheelSize,
                child: GestureDetector(
                  onPanDown: (d) => _onWheelDrag(d.localPosition),
                  onPanUpdate: (d) => _onWheelDrag(d.localPosition),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WheelPainter(_hsv.value),
                        ),
                      ),
                      Positioned(
                        left: markerX - 9,
                        top: markerY - 9,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _channelSlider(
              'Value',
              _hsv.value,
              const [Colors.black, Colors.white],
              (v) => _update(_hsv.withValue(v)),
            ),
            _channelSlider(
              'R',
              _r / 255,
              const [Colors.black, Color(0xFFFF0000)],
              (v) => _setColor(
                  Color.fromARGB(255, (v * 255).round(), _g, _b)),
            ),
            _channelSlider(
              'G',
              _g / 255,
              const [Colors.black, Color(0xFF00FF00)],
              (v) => _setColor(
                  Color.fromARGB(255, _r, (v * 255).round(), _b)),
            ),
            _channelSlider(
              'B',
              _b / 255,
              const [Colors.black, Color(0xFF0000FF)],
              (v) => _setColor(
                  Color.fromARGB(255, _r, _g, (v * 255).round())),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      labelText: 'HEX',
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp('[0-9a-fA-F#]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    onSubmitted: _applyHex,
                    onEditingComplete: () => _applyHex(_hexController.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionLabel('Palette'),
            const SizedBox(height: 10),
            _swatchWrap(_palette),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) {
                final history = widget.settings.colorHistory;
                if (history.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Recent'),
                    const SizedBox(height: 10),
                    _swatchWrap(history),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );

  Widget _swatchWrap(List<Color> colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in colors)
          GestureDetector(
            onTap: () => _setColor(color),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.toARGB32() == _color.toARGB32()
                      ? FabyColors.turquoise
                      : Colors.white24,
                  width: color.toARGB32() == _color.toARGB32() ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _channelSlider(
    String label,
    double value,
    List<Color> trackColors,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              trackShape: _GradientTrackShape(trackColors),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 255).round()}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Paints the HSV wheel: hue by angle, saturation by radius, dimmed by value.
class _WheelPainter extends CustomPainter {
  _WheelPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final hueShader = SweepGradient(
      colors: [
        for (double h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h % 360, 1, 1).toColor(),
      ],
    ).createShader(rect);
    canvas.drawCircle(center, radius, Paint()..shader = hueShader);

    final satShader = RadialGradient(
      colors: [Colors.white, Colors.white.withValues(alpha: 0)],
    ).createShader(rect);
    canvas.drawCircle(center, radius, Paint()..shader = satShader);

    if (value < 1) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 1 - value),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.value != value;
}

/// Slider track that shows a gradient of the channel being edited.
class _GradientTrackShape extends RoundedRectSliderTrackShape {
  const _GradientTrackShape(this.colors);

  final List<Color> colors;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(rect);
    final radius = Radius.circular(rect.height / 2);
    context.canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
  }
}
