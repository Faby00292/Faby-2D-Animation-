import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home/home_screen.dart';
import 'state/project_store.dart';
import 'state/settings_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FabyApp());
}

class FabyApp extends StatelessWidget {
  const FabyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectStore>(
          create: (_) => ProjectStore()..load(),
        ),
        ChangeNotifierProvider<SettingsStore>(
          create: (_) => SettingsStore()..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Faby 2D Animation',
        debugShowCheckedModeBanner: false,
        theme: buildFabyTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
