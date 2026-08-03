import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'app.dart';
import 'services/storage_service.dart';
import 'state/projects_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final StorageService storage = StorageService();
  final SettingsController settings = SettingsController();
  final ProjectsController projects = ProjectsController(storage);

  await settings.load();
  await projects.load();

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<ProjectsController>.value(value: projects),
      ],
      child: const FabyApp(),
    ),
  );
}
