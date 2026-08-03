import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';

/// App preferences: theme, language and input method.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _languages = <String, String>{
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    'fr': 'Français',
    'de': 'Deutsch',
    'ru': 'Русский',
    'uk': 'Українська',
  };

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _section(context, 'Appearance'),
          Card(
            child: Column(
              children: <Widget>[
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (ThemeMode? v) =>
                      settings.setThemeMode(v ?? ThemeMode.dark),
                  title: const Text('Dark theme'),
                  secondary: const Icon(Icons.dark_mode),
                  activeColor: AppTheme.accent,
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (ThemeMode? v) =>
                      settings.setThemeMode(v ?? ThemeMode.light),
                  title: const Text('Light theme'),
                  secondary: const Icon(Icons.light_mode),
                  activeColor: AppTheme.accent,
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (ThemeMode? v) =>
                      settings.setThemeMode(v ?? ThemeMode.system),
                  title: const Text('System default'),
                  secondary: const Icon(Icons.brightness_auto),
                  activeColor: AppTheme.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(context, 'Language'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              trailing: DropdownButton<String>(
                value: settings.language,
                underline: const SizedBox.shrink(),
                items: _languages.entries
                    .map(
                      (MapEntry<String, String> e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) {
                  if (v != null) settings.setLanguage(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section(context, 'Input'),
          Card(
            child: Column(
              children: <Widget>[
                for (final InputMethod method in InputMethod.values)
                  RadioListTile<InputMethod>(
                    value: method,
                    groupValue: settings.inputMethod,
                    onChanged: (InputMethod? v) =>
                        settings.setInputMethod(v ?? InputMethod.both),
                    title: Text(_inputLabel(method)),
                    secondary: Icon(_inputIcon(method)),
                    activeColor: AppTheme.accent,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Faby 2D Animation · v0.1.0',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: AppTheme.accent,
        ),
      ),
    );
  }

  String _inputLabel(InputMethod m) => switch (m) {
        InputMethod.finger => 'Finger only',
        InputMethod.stylus => 'Stylus only',
        InputMethod.both => 'Finger & stylus',
      };

  IconData _inputIcon(InputMethod m) => switch (m) {
        InputMethod.finger => Icons.touch_app,
        InputMethod.stylus => Icons.draw,
        InputMethod.both => Icons.gesture,
      };
}
