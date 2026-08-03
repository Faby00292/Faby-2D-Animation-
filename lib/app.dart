import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home/home_screen.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';

/// Root widget. Reacts to [SettingsController] so theme changes apply live.
class FabyApp extends StatelessWidget {
  const FabyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    return MaterialApp(
      title: 'Faby 2D Animation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
