import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/exercise/widgets/set_actuals_dialog.dart';
import 'package:fitfat/src/models/exercise_set.dart';
import 'package:fitfat/src/models/units.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Skating has a duration but no distance. The actuals dialog must lead with
/// duration (prefilled from the plan) and keep distance behind "+ distance",
/// so a time-only session is one tap: open, save.
void main() {
  const duration = ValueKey('cardio-duration');
  const distance = ValueKey('cardio-distance');
  const addDistance = ValueKey('cardio-add-distance');

  Future<SetActuals?> openAndSave(
    WidgetTester tester,
    ExerciseSet set, {
    bool hasDistanceHistory = false,
    Future<void> Function()? interact,
  }) async {
    SetActuals? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showSetActualsDialog(
                context,
                set: set,
                l10n: AppLocalizations.of(context)!,
                isWeightlifting: false,
                isCardio: true,
                unit: WeightUnit.kg,
                hasDistanceHistory: hasDistanceHistory,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    if (interact != null) await interact();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    return result;
  }

  const plannedSkate = ExerciseSet(
    id: 's1',
    workoutExerciseId: 'we1',
    setNumber: 1,
    durationMinutes: 45,
  );

  testWidgets('time-only set: distance hidden, duration prefilled', (
    tester,
  ) async {
    final result = await openAndSave(
      tester,
      plannedSkate,
      interact: () async {
        expect(find.byKey(distance), findsNothing);
        expect(find.byKey(addDistance), findsOneWidget);
        final field = tester.widget<TextField>(find.byKey(duration));
        expect(field.controller!.text, '45');
      },
    );
    expect(result!.actualDurationMinutes, 45);
    expect(result.actualDistanceMeters, isNull);
  });

  testWidgets('"+ distance" reveals the field', (tester) async {
    final result = await openAndSave(
      tester,
      plannedSkate,
      interact: () async {
        await tester.tap(find.byKey(addDistance));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(distance), '8000');
      },
    );
    expect(result!.actualDistanceMeters, 8000);
  });

  testWidgets('exercise with distance history opens expanded', (tester) async {
    await openAndSave(
      tester,
      plannedSkate,
      hasDistanceHistory: true,
      interact: () async {
        expect(find.byKey(distance), findsOneWidget);
        expect(find.byKey(addDistance), findsNothing);
      },
    );
  });

  testWidgets('a planned distance opens expanded and prefilled', (
    tester,
  ) async {
    const run = ExerciseSet(
      id: 's2',
      workoutExerciseId: 'we1',
      setNumber: 1,
      durationMinutes: 30,
      distanceMeters: 5000,
    );
    final result = await openAndSave(tester, run);
    expect(result!.actualDistanceMeters, 5000);
  });
}
