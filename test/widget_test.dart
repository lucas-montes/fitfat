import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/src/testing_flags.dart';
import 'package:fitfat/src/app.dart';

void main() {
  testWidgets('App launches and shows food screen', (
    WidgetTester tester,
  ) async {
    disableUiTimers = true;
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));

    // Default route is /diet, should show the Diet tabs.
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
  });

  testWidgets('Navigate to Exercise tab and open Seance Library', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));
    await tester.pumpAndSettle();

    // Tap Exercise navigation bar
    await tester.tap(find.text('Exercise'));
    await tester.pumpAndSettle();

    // Switch to Seances tab
    await tester.tap(find.text('Seances'));
    await tester.pumpAndSettle();
    expect(find.text('Start Blank Seance'), findsOneWidget);
    expect(find.text('Templates / Start from Template'), findsOneWidget);

    // Open Seance Library
    await tester.tap(find.text('Templates / Start from Template'));
    await tester.pumpAndSettle();
    expect(find.text('Templates: Start or Create'), findsOneWidget);
    expect(find.text('No templates yet'), findsOneWidget);
  });

  testWidgets('Create template and start seance from template', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seances'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Templates / Start from Template'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    // Fill in template name
    await tester.enterText(find.byType(TextField).first, 'Push Day');
    // Add an exercise
    await tester.enterText(find.byType(TextField).at(1), 'Bench Press');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    // Save template
    await tester.tap(find.text('Save Template'));
    await tester.pumpAndSettle();
    // Should see template in library
    expect(find.text('Push Day'), findsOneWidget);
    // Start seance from template
    await tester.tap(find.byIcon(Icons.play_arrow));
    // Do a single pump (avoid pumpAndSettle because the Active Seance starts a recurring timer)
    await tester.pump();
    // Should navigate back to Exercise tab and show active seance UI
    expect(find.text('Active Seance'), findsOneWidget);
  });
}
