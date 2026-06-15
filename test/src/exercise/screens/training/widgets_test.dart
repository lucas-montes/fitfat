import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/exercise/providers/workout_provider.dart';
import 'package:fitfat/src/exercise/screens/training/calendar_strip.dart';
import 'package:fitfat/src/exercise/screens/training/start_workout_card.dart';
import 'package:fitfat/src/exercise/screens/training/workout_history_card.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:fitfat/src/models/workout.dart' as domain;

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// Test-only notifier that always returns null (no active workout).
class _NullWorkoutNotifier extends ActiveWorkoutNotifier {
  @override
  domain.Workout? build() => null;
}

void main() {
  group('WorkoutHistoryCard', () {
    testWidgets('renders workout name and date', (tester) async {
      final workout = domain.Workout(
        id: 'w1',
        name: 'Push Day',
        startTime: DateTime(2026, 6, 10, 10, 0),
        endTime: DateTime(2026, 6, 10, 11, 0),
        entries: [],
        source: 'manual',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithMaterial(WorkoutHistoryCard(workout: workout)),
        ),
      );

      expect(find.text('Push Day'), findsOneWidget);
    });

    testWidgets('shows weightlifting set summary', (tester) async {
      final workout = domain.Workout(
        id: 'w2',
        name: 'Leg Day',
        startTime: DateTime(2026, 6, 11, 9, 0),
        endTime: DateTime(2026, 6, 11, 10, 0),
        entries: [
          domain.WorkoutEntry(
            id: 'e1',
            exercise: const ExerciseDefinition(
              id: 'ex-squat',
              name: 'Squat',
              category: 'Legs',
            ),
            sets: const [
              domain.WeightSet(reps: 5, weightKg: 100.0),
              domain.WeightSet(reps: 5, weightKg: 110.0),
            ],
            sortOrder: 0,
          ),
        ],
        source: 'manual',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithMaterial(WorkoutHistoryCard(workout: workout)),
        ),
      );

      expect(find.text('Squat'), findsOneWidget);
      expect(find.textContaining('5×100'), findsOneWidget);
      expect(find.textContaining('5×110'), findsOneWidget);
    });

    testWidgets('shows cardio duration', (tester) async {
      final workout = domain.Workout(
        id: 'w3',
        name: 'Cardio',
        startTime: DateTime(2026, 6, 12, 7, 0),
        endTime: DateTime(2026, 6, 12, 7, 30),
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
          child: _wrapWithMaterial(WorkoutHistoryCard(workout: workout)),
        ),
      );

      expect(find.text('Swimming'), findsOneWidget);
      expect(find.textContaining('30 min'), findsOneWidget);
    });
  });

  group('CalendarStrip', () {
    testWidgets('renders day labels', (tester) async {
      final monday = DateTime(2026, 6, 8);

      await tester.pumpWidget(
        _wrapWithMaterial(
          CalendarStrip(
            weekStart: monday,
            selectedDay: monday,
            plannedWorkouts: const [],
            onWeekChanged: (_) {},
            onDaySelected: (_) {},
          ),
        ),
      );

      // Day name labels should be present
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('renders without crashing', (tester) async {
      final monday = DateTime(2026, 6, 8);
      final selected = DateTime(2026, 6, 10);

      await tester.pumpWidget(
        _wrapWithMaterial(
          CalendarStrip(
            weekStart: monday,
            selectedDay: selected,
            plannedWorkouts: const [],
            onWeekChanged: (_) {},
            onDaySelected: (_) {},
          ),
        ),
      );

      // Smoke test: no crashes
      expect(find.byType(CalendarStrip), findsOneWidget);
    });
  });

  group('StartWorkoutCard', () {
    testWidgets(
      'shows start and quick log when no active workout and no plan',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeWorkoutProvider.overrideWith(_NullWorkoutNotifier.new),
            ],
            child: _wrapWithMaterial(
              const StartWorkoutCard(todaysPlannedWorkouts: []),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Start workout'), findsNWidgets(2));
        expect(find.text('Quick Log'), findsOneWidget);
      },
    );

    testWidgets('shows follow plan and quick log when plan exists', (
      tester,
    ) async {
      final plan = domain.PlannedWorkout(
        id: 'p1',
        scheduledDate: DateTime.now(),
        name: 'Push Day',
        entries: const [],
        source: 'from_template',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkoutProvider.overrideWith(_NullWorkoutNotifier.new),
          ],
          child: _wrapWithMaterial(
            StartWorkoutCard(todaysPlannedWorkouts: [plan]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Follow today\'s plan'), findsWidgets);
      expect(find.text('Quick Log'), findsOneWidget);
    });
  });
}
