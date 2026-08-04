import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/brush_preset.dart';

/// App-wide, persisted preferences: recently used colors and saved custom
/// brushes.
class SettingsStore extends ChangeNotifier {
  static const String _colorsKey = 'faby_color_history';
  static const String _brushesKey = 'faby_custom_brushes';
  static const int _maxHistory = 18;

  final List<Color> _colorHistory = <Color>[];
  final List<BrushPreset> _customBrushes = <BrushPreset>[];
  SharedPreferences? _prefs;

  List<Color> get colorHistory => List.unmodifiable(_colorHistory);
  List<BrushPreset> get customBrushes => List.unmodifiable(_customBrushes);

  Future<void> load() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();

    final colors = prefs.getStringList(_colorsKey) ?? const [];
    _colorHistory
      ..clear()
      ..addAll(colors.map((c) => Color(int.parse(c))));

    final brushes = prefs.getStringList(_brushesKey) ?? const [];
    _customBrushes
      ..clear()
      ..addAll(
        brushes.map(
          (b) => BrushPreset.fromJson(jsonDecode(b) as Map<String, dynamic>),
        ),
      );

    notifyListeners();
  }

  void addColorToHistory(Color color) {
    final value = color.toARGB32();
    _colorHistory.removeWhere((c) => c.toARGB32() == value);
    _colorHistory.insert(0, color);
    if (_colorHistory.length > _maxHistory) {
      _colorHistory.removeRange(_maxHistory, _colorHistory.length);
    }
    _saveColors();
    notifyListeners();
  }

  void addCustomBrush(BrushPreset preset) {
    _customBrushes.insert(0, preset);
    _saveBrushes();
    notifyListeners();
  }

  void removeCustomBrush(String id) {
    _customBrushes.removeWhere((b) => b.id == id);
    _saveBrushes();
    notifyListeners();
  }

  void _saveColors() {
    _prefs?.setStringList(
      _colorsKey,
      _colorHistory.map((c) => c.toARGB32().toString()).toList(),
    );
  }

  void _saveBrushes() {
    _prefs?.setStringList(
      _brushesKey,
      _customBrushes.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }
}
