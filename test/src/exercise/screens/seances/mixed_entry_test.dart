import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/exercise/screens/seances/active/summary_screen.dart';
import 'package:fitfat/src/exercise/screens/seances/active/guided_set_card.dart';
import 'package:fitfat/src/exercise/screens/seances/active/freeform_set_card.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:fitfat/src/models/workout.dart' as domain;

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('WorkoutSummaryScreen', () {
    testWidgets('shows weightlifting workout summary', (tester) async {
      final workout = domain.Workout(
        id: 'w1',
        name: 'Push Day',
        startTime: DateTime(2026, 6, 10, 10, 0),
        endTime: DateTime(2026, 6, 10, 11, 0),
        entries: [
          domain.WorkoutEntry(
            id: 'e1',
            exercise: const ExerciseDefinition(
              id: 'ex-bench',
              name: 'Bench Press',
              category: 'Chest',
            ),
            sets: const [
              domain.WeightSet(reps: 10, weightKg: 50.0),
              domain.WeightSet(reps: 8, weightKg: 60.0),
            ],
            sortOrder: 0,
          ),
        ],
        source: 'manual',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithMaterial(WorkoutSummaryScreen(workout: workout)),
        ),
      );

      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.textContaining(':00'), findsOneWidget); // duration
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('shows cardio workout summary', (tester) async {
      final workout = domain.Workout(
        id: 'w2',
        name: 'Cardio Session',
        startTime: DateTime(2026, 6, 11, 7, 0),
        endTime: DateTime(2026, 6, 11, 7, 30),
        entries: [
          domain.WorkoutEntry(
            id: 'e1',
            exercise: const ExerciseDefinition(
              id: 'ex-swim',
              name: 'Swimming',
              type: 'cardio',
            ),
            sets: [],
            cardioDetail: const domain.CardioDetail(durationMinutes: 30),
            sortOrder: 0,
          ),
        ],
        source: 'manual',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithMaterial(WorkoutSummaryScreen(workout: workout)),
        ),
      );

      expect(find.text('Cardio Session'), findsOneWidget);
      expect(find.textContaining('min cardio'), findsOneWidget);
      expect(find.text('Swimming'), findsOneWidget);
      expect(find.byIcon(Icons.directions_run), findsOneWidget);
    });
  });

  group('GuidedSetCard with WeightSet', () {
    testWidgets('renders set details', (tester) async {
      final set = const domain.WeightSet(reps: 10, weightKg: 50.0);

      await tester.pumpWidget(
        _wrapWithMaterial(
          GuidedSetCard(set: set, index: 0, onTap: () {}, onLongPress: () {}),
        ),
      );

      expect(find.text('Set 1'), findsOneWidget);
      expect(find.textContaining('10 reps × 50.0kg'), findsOneWidget);
    });

    testWidgets('shows completed state', (tester) async {
      final set = domain.WeightSet(
        reps: 8,
        weightKg: 60.0,
        completedAt: DateTime(2026, 6, 10, 10, 30),
      );

      await tester.pumpWidget(
        _wrapWithMaterial(
          GuidedSetCard(set: set, index: 0, onTap: () {}, onLongPress: () {}),
        ),
      );

      expect(find.textContaining('8 reps × 60.0kg'), findsOneWidget);
      expect(find.textContaining('10:30'), findsOneWidget);
    });
  });

  group('FreeformSetCard with WeightSet', () {
    testWidgets('renders set details', (tester) async {
      final set = const domain.WeightSet(reps: 5, weightKg: 100.0);

      await tester.pumpWidget(
        _wrapWithMaterial(
          FreeformSetCard(set: set, index: 0, onLongPress: () {}),
        ),
      );

      expect(find.text('Set 1'), findsOneWidget);
      expect(find.textContaining('5 reps × 100.0kg'), findsOneWidget);
    });
  });
}
