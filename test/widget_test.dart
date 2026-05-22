import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/src/testing_flags.dart';
import 'package:fitfat/src/app.dart';
import 'package:fitfat/src/providers/seance_providers.dart';
import 'package:fitfat/src/repositories/in_memory_seance_repository.dart';

void main() {
  testWidgets('App launches and shows food screen', (
    WidgetTester tester,
  ) async {
    disableUiTimers = true;
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));

    // Default route is /dashboard; navigate to Diet tab.
    await tester.tap(find.text('Diet'));
    await tester.pumpAndSettle();
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
  });

  testWidgets('Navigate to Exercise tab and open Seance Library', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));
    await tester.pumpAndSettle();

    // Tap Exercise navigation bar
    await tester.tap(find.text('Exercise'));
    await tester.pumpAndSettle();

    // Switch to Seances tab
    await tester.tap(find.text('Seances'));
    await tester.pumpAndSettle();
    expect(find.text('Start Blank Seance'), findsOneWidget);

    // Open create template screen via the Create button
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Create Template'), findsOneWidget);
  });

  testWidgets('Create template and start seance from template', (tester) async {
    disableUiTimers = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Use in-memory repo so tests don't need a database
          seanceRepositoryProvider.overrideWithValue(
            InMemorySeanceRepository(),
          ),
        ],
        child: const FitFatApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seances'));
    await tester.pumpAndSettle();
    // Tap "Create" to open template creator
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    // Fill in template name
    await tester.enterText(find.byType(TextField).first, 'Push Day');
    // Type in the search field to add a custom exercise
    await tester.enterText(find.byType(TextField).at(1), 'Bench Press');
    await tester.pumpAndSettle();
    // Tap the add_circle suffix icon to add as custom exercise
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    // Save template (Save button in AppBar)
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // Should see template in library
    expect(find.text('Push Day'), findsOneWidget);
    // Start seance from template
    await tester.tap(find.byIcon(Icons.play_arrow).first);
    // pumpAndSettle is safe here because disableUiTimers prevents the seance timer
    await tester.pumpAndSettle();
    // Starting a seance pushes /current-seance route — should show active seance UI
    expect(find.text('Active Seance'), findsOneWidget);
  });
}
