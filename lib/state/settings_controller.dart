import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the user draws — used to filter stylus vs. finger input on the canvas.
enum InputMethod { finger, stylus, both }

/// App-wide preferences: theme mode, language and input method. Persisted with
/// [SharedPreferences] and exposed as a [ChangeNotifier] for the widget tree.
class SettingsController extends ChangeNotifier {
  SettingsController();

  static const String _kTheme = 'theme_mode';
  static const String _kLanguage = 'language';
  static const String _kInput = 'input_method';

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';
  InputMethod _inputMethod = InputMethod.both;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  InputMethod get inputMethod => _inputMethod;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? theme = prefs.getString(_kTheme);
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    _language = prefs.getString(_kLanguage) ?? 'en';
    final String? input = prefs.getString(_kInput);
    _inputMethod = InputMethod.values.firstWhere(
      (InputMethod m) => m.name == input,
      orElse: () => InputMethod.both,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode.name);
  }

  Future<void> setLanguage(String code) async {
    _language = code;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  Future<void> setInputMethod(InputMethod method) async {
    _inputMethod = method;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInput, method.name);
  }
}
