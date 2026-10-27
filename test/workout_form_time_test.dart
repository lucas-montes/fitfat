import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:fitfat/src/exercise/screens/workout_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pencil on a completed workout opens this form to edit actuals. A session
/// logged without the rest timer has no recorded rest, so the form lets the user
/// correct when each set was finished and derives the rest from those times.
void main() {
  late db.AppDatabase database;
  late WorkoutRepository workouts;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(database);
  });

  tearDown(() => database.close());

  /// A completed session with two bench sets finished at 10:30 and 10:35.
  /// [firstRest] is what the rest timer recorded after set 1, if it ran.
  Future<WorkoutWithDetails> seedCompleted({int? firstRest}) async {
    await database
        .into(database.exercises)
        .insert(
          db.ExercisesCompanion.insert(
            id: 'e1',
            name: 'Bench Press',
            exerciseType: 'weightlifting',
            createdAt: 1,
          ),
        );
    final workout = newWorkout(name: 'Push', date: DateTime(2026, 1, 1));
    final we = newWorkoutExercise(
      workoutId: workout.id,
      exerciseId: 'e1',
      exerciseName: 'Bench Press',
      sortOrder: 0,
    );
    final first = newPlannedSet(
      workoutExerciseId: we.id,
      setNumber: 1,
      reps: 10,
      weightKg: 60,
      restSeconds: 90,
    );
    final second = newPlannedSet(
      workoutExerciseId: we.id,
      setNumber: 2,
      reps: 8,
      weightKg: 65,
      restSeconds: 120,
    );
    await workouts.insert(
      workout: workout,
      exercises: [we],
      setGroups: [
        [first, second],
      ],
    );
    await workouts.start(workout.id);
    await workouts.complete(workout.id);

    Future<void> stamp(
      String id,
      int reps,
      double kg,
      DateTime at, {
      int? rest,
    }) async {
      await (database.update(
        database.exerciseSets,
      )..where((t) => t.id.equals(id))).write(
        db.ExerciseSetsCompanion(
          actualReps: Value(reps),
          actualWeightKg: Value(kg),
          actualRestSeconds: Value(rest),
          completedAt: Value(at.millisecondsSinceEpoch),
        ),
      );
    }

    await stamp(
      first.id,
      10,
      60,
      DateTime(2026, 1, 1, 10, 30),
      rest: firstRest,
    );
    await stamp(second.id, 8, 65, DateTime(2026, 1, 1, 10, 35));
    return (await workouts.getWithDetails(workout.id))!;
  }

  Future<void> pumpForm(WidgetTester tester, WorkoutWithDetails detail) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: WorkoutFormScreen(initial: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows when each set was finished and the rest between them', (
    tester,
  ) async {
    final detail = await seedCompleted();
    await pumpForm(tester, detail);

    expect(find.textContaining('10:30'), findsOneWidget);
    expect(find.textContaining('10:35'), findsOneWidget);
    // Set 2's row shows the gap from set 1, which is the rest that was taken
    // before it — 5 minutes here.
    expect(find.text('rest 05:00'), findsOneWidget);
    // A completed edit has no plan-rest field to confuse this with.
    expect(find.text('Rest (min)'), findsNothing);
  });

  testWidgets('saving derives the missing rest from the set times', (
    tester,
  ) async {
    final detail = await seedCompleted();
    await pumpForm(tester, detail);
    await save(tester);

    final after = (await workouts.getWithDetails(detail.workout.id))!;
    final sets = after.exercises.single.sets;
    expect(sets[0].actualRestSeconds, 300, reason: '10:30 → 10:35');
    expect(sets[1].actualRestSeconds, isNull, reason: 'nothing follows it');
    // Times are left exactly as they were.
    expect(sets[0].completedAt, DateTime(2026, 1, 1, 10, 30));
    expect(sets[1].completedAt, DateTime(2026, 1, 1, 10, 35));
  });

  testWidgets('saving keeps a rest the timer recorded', (tester) async {
    final detail = await seedCompleted(firstRest: 120);
    await pumpForm(tester, detail);

    // The preview shows what will be stored, not a recomputed 5 minutes.
    expect(find.text('rest 02:00'), findsOneWidget);

    await save(tester);

    final after = (await workouts.getWithDetails(detail.workout.id))!;
    expect(after.exercises.single.sets[0].actualRestSeconds, 120);
  });

  testWidgets('picking a new time recalculates the rest', (tester) async {
    final detail = await seedCompleted();
    await pumpForm(tester, detail);

    await tester.tap(find.textContaining('10:30'));
    await tester.pumpAndSettle();
    // Type the time instead of dragging the dial: the point of the test is the
    // form's wiring, not the picker's own interaction.
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '10');
    await tester.enterText(fields.at(1), '20');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('10:20'), findsOneWidget);
    expect(find.text('rest 15:00'), findsOneWidget);

    await save(tester);

    final after = (await workouts.getWithDetails(detail.workout.id))!;
    final sets = after.exercises.single.sets;
    expect(sets[0].completedAt, DateTime(2026, 1, 1, 10, 20));
    expect(sets[0].actualRestSeconds, 900, reason: '10:20 → 10:35');
    expect(sets[1].completedAt, DateTime(2026, 1, 1, 10, 35));
  });
}
