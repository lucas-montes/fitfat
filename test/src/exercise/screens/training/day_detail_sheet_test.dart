import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/exercise/screens/training/day_detail_sheet.dart';
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
  group('DayDetailSheet', () {
    final testDate = DateTime(2026, 6, 15);

    testWidgets('shows add CTA when no planned workouts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithMaterial(
            DayDetailSheet(date: testDate, plannedWorkouts: []),
          ),
        ),
      );

      expect(find.text('15/6/2026'), findsOneWidget);
      expect(find.text('No planned workouts for this day'), findsOneWidget);
      expect(find.text('Add planned workout'), findsOneWidget);
    });

    testWidgets('shows planned workout with start/edit/delete', (tester) async {
      final plan = domain.PlannedWorkout(
        id: 'p1',
        scheduledDate: testDate,
        name: 'Push Day',
        entries: [
          domain.PlannedEntry(
            id: 'pe1',
            exercise: const ExerciseDefinition(id: 'ex1', name: 'Bench Press'),
            plannedReps: 10,
            plannedWeightKg: 50.0,
            sortOrder: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithMaterial(
            DayDetailSheet(date: testDate, plannedWorkouts: [plan]),
          ),
        ),
      );

      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
