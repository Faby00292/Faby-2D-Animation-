import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:faby_2d_animation/app.dart';
import 'package:faby_2d_animation/models/format_preset.dart';
import 'package:faby_2d_animation/models/project.dart';
import 'package:faby_2d_animation/screens/editor/editor_screen.dart';
import 'package:faby_2d_animation/services/storage_service.dart';
import 'package:faby_2d_animation/state/projects_controller.dart';
import 'package:faby_2d_animation/state/settings_controller.dart';

void main() {
  test('project round-trips through JSON', () {
    final Project project = Project(
      name: 'Test',
      format: FormatPreset.tiktok1080,
      fps: 18,
    );
    project.frames.first.layers.first.name = 'Base';

    final Project restored = Project.fromJson(project.toJson());

    expect(restored.name, 'Test');
    expect(restored.format, FormatPreset.tiktok1080);
    expect(restored.fps, 18);
    expect(restored.frames.length, project.frames.length);
    expect(restored.frames.first.layers.first.name, 'Base');
  });

  test('format presets expose sane dimensions', () {
    expect(FormatPreset.youtube1080.width, 1920);
    expect(FormatPreset.instagram11.aspectRatio, 1.0);
    expect(FormatPreset.values.length, 10);
  });

  testWidgets('home screen builds', (WidgetTester tester) async {
    final StorageService storage = StorageService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<SettingsController>(
            create: (_) => SettingsController(),
          ),
          ChangeNotifierProvider<ProjectsController>(
            create: (_) => ProjectsController(storage),
          ),
        ],
        child: const FabyApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Faby'), findsOneWidget);
  });

  testWidgets('editor screen builds for a project', (WidgetTester tester) async {
    final StorageService storage = StorageService();
    final Project project = Project(
      name: 'Demo',
      format: FormatPreset.instagram11,
      fps: 12,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<SettingsController>(
            create: (_) => SettingsController(),
          ),
        ],
        child: MaterialApp(home: EditorScreen(project: project)),
      ),
    );
    await tester.pump();
    expect(find.byType(EditorScreen), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
  });
}
