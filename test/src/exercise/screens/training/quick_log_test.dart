import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/exercise/screens/training/quick_log_sheet.dart';
import 'package:fitfat/src/exercise/providers/exercises.dart';
import 'package:fitfat/src/models/exercise.dart';

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// A test notifier that extends the real ExerciseListNotifier.
class _TestExerciseListNotifier extends ExerciseListNotifier {
  @override
  List<ExerciseDefinition> build() => [
    const ExerciseDefinition(
      id: 'ex-bench',
      name: 'Bench Press',
      category: 'Chest',
      type: 'weightlifting',
    ),
    const ExerciseDefinition(
      id: 'ex-swim',
      name: 'Swimming',
      category: 'Cardio',
      type: 'cardio',
    ),
  ];
}

void main() {
  group('QuickLogSheet', () {
    testWidgets('renders search field and exercise list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseListProvider.overrideWith(
              () => _TestExerciseListNotifier(),
            ),
          ],
          child: _wrapWithMaterial(const QuickLogSheet()),
        ),
      );

      expect(find.text('Quick Log'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Swimming'), findsOneWidget);
    });

    testWidgets('filters exercises by search query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseListProvider.overrideWith(
              () => _TestExerciseListNotifier(),
            ),
          ],
          child: _wrapWithMaterial(const QuickLogSheet()),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'bench');
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Swimming'), findsNothing);
    });

    testWidgets('shows weightlifting input fields after selecting exercise', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseListProvider.overrideWith(
              () => _TestExerciseListNotifier(),
            ),
          ],
          child: _wrapWithMaterial(const QuickLogSheet()),
        ),
      );

      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      expect(find.text('Reps'), findsWidgets);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Log Workout'), findsOneWidget);
    });

    testWidgets('shows cardio input fields after selecting cardio exercise', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseListProvider.overrideWith(
              () => _TestExerciseListNotifier(),
            ),
          ],
          child: _wrapWithMaterial(const QuickLogSheet()),
        ),
      );

      await tester.tap(find.text('Swimming'));
      await tester.pumpAndSettle();

      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Reps'), findsNothing);
      expect(find.text('Weight (kg)'), findsNothing);
      expect(find.text('Log Workout'), findsOneWidget);
    });
  });
}
