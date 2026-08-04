import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home/home_screen.dart';
import 'state/project_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FabyApp());
}

class FabyApp extends StatelessWidget {
  const FabyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectStore>(
      create: (_) => ProjectStore(),
      child: MaterialApp(
        title: 'Faby 2D Animation',
        debugShowCheckedModeBanner: false,
        theme: buildFabyTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
