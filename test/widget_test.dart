// Basic smoke test for the Faby 2D Animation app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faby_2d_animation/main.dart';

void main() {
  testWidgets('Home screen shows title and empty state', (tester) async {
    await tester.pumpWidget(const FabyApp());

    expect(find.text('Faby 2D Animation'), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
