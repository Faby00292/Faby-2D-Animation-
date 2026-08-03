import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_theme.dart';
import 'hsv_wheel.dart';

/// Full colour picker presented as a bottom sheet: HSV wheel + brightness, RGB
/// sliders, HEX entry, a preset palette and recent-colour history. Emits every
/// change through [onChanged] so the canvas colour updates live.
class ColorPickerSheet extends StatefulWidget {
  const ColorPickerSheet({
    super.key,
    required this.initial,
    required this.history,
    required this.onChanged,
    required this.onPickFromCanvas,
  });

  final Color initial;
  final List<Color> history;
  final ValueChanged<Color> onChanged;
  final VoidCallback onPickFromCanvas;

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  late HSVColor _hsv;
  late TextEditingController _hex;

  static const List<Color> _palette = <Color>[
    Colors.black,
    Colors.white,
    Color(0xFF9E9E9E),
    Color(0xFFEF5350),
    Color(0xFFFF7043),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    AppTheme.accent,
    Color(0xFF29B6F6),
    Color(0xFF5C6BC0),
    Color(0xFFAB47BC),
    Color(0xFFEC407A),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hex = TextEditingController(text: _toHex(widget.initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  String _toHex(Color c) {
    final int argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _emit(HSVColor value) {
    setState(() {
      _hsv = value;
      _hex.text = _toHex(value.toColor());
    });
    widget.onChanged(value.toColor());
  }

  void _emitColor(Color c) => _emit(HSVColor.fromColor(c));

  void _applyHex(String text) {
    String hex = text.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return;
    final int? value = int.tryParse(hex, radix: 16);
    if (value == null) return;
    _emitColor(Color(value));
  }

  @override
  Widget build(BuildContext context) {
    final Color current = _hsv.toColor();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: current,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Color', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: widget.onPickFromCanvas,
                    icon: const Icon(Icons.colorize, size: 18),
                    label: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: HsvWheel(
                  color: _hsv,
                  onChanged: _emit,
                ),
              ),
              const SizedBox(height: 16),
              _channel(
                'Brightness',
                _hsv.value,
                <Color>[Colors.black, _hsv.withValue(1).toColor()],
                (double v) => _emit(_hsv.withValue(v)),
              ),
              const Divider(height: 28),
              _rgbSliders(current),
              const SizedBox(height: 12),
              TextField(
                controller: _hex,
                decoration: const InputDecoration(
                  labelText: 'HEX',
                  prefixIcon: Icon(Icons.tag),
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp('[0-9a-fA-F#]'),
                  ),
                  LengthLimitingTextInputFormatter(9),
                ],
                onSubmitted: _applyHex,
                onEditingComplete: () => _applyHex(_hex.text),
              ),
              const Divider(height: 28),
              const Text('Palette', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _swatches(_palette),
              const SizedBox(height: 16),
              const Text('History', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _swatches(
                widget.history.isEmpty
                    ? <Color>[widget.initial]
                    : widget.history,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rgbSliders(Color c) {
    return Column(
      children: <Widget>[
        _channel(
          'R',
          (c.r * 255).roundToDouble() / 255,
          <Color>[
            Color.fromARGB(255, 0, (c.g * 255).round(), (c.b * 255).round()),
            Color.fromARGB(255, 255, (c.g * 255).round(), (c.b * 255).round()),
          ],
          (double v) => _emitColor(
            c.withValues(red: v),
          ),
        ),
        _channel(
          'G',
          (c.g * 255).roundToDouble() / 255,
          <Color>[
            Color.fromARGB(255, (c.r * 255).round(), 0, (c.b * 255).round()),
            Color.fromARGB(255, (c.r * 255).round(), 255, (c.b * 255).round()),
          ],
          (double v) => _emitColor(
            c.withValues(green: v),
          ),
        ),
        _channel(
          'B',
          (c.b * 255).roundToDouble() / 255,
          <Color>[
            Color.fromARGB(255, (c.r * 255).round(), (c.g * 255).round(), 0),
            Color.fromARGB(255, (c.r * 255).round(), (c.g * 255).round(), 255),
          ],
          (double v) => _emitColor(
            c.withValues(blue: v),
          ),
        ),
      ],
    );
  }

  Widget _channel(
    String label,
    double value,
    List<Color> track,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: track),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Slider(
                  value: value.clamp(0.0, 1.0),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 255).round()}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: AppTheme.accent),
          ),
        ),
      ],
    );
  }

  Widget _swatches(List<Color> colors) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final Color c in colors)
          GestureDetector(
            onTap: () => _emitColor(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: c.toARGB32() == _hsv.toColor().toARGB32()
                      ? AppTheme.accent
                      : Colors.white24,
                  width: c.toARGB32() == _hsv.toColor().toARGB32() ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
