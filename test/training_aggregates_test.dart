import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/exercise/providers/training.dart';
import 'package:fitfat/src/exercise/repositories/training_summaries.dart';
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late TrainingSummaries summaries;
  var n = 0;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    summaries = TrainingSummaries(database);
  });

  tearDown(() => database.close());

  Future<void> exercise(String id) => database
      .into(database.exercises)
      .insertOnConflictUpdate(
        db.ExercisesCompanion.insert(
          id: id,
          name: id,
          exerciseType: 'weightlifting',
          createdAt: 0,
        ),
      );

  Future<void> workout(
    String id,
    DateTime day, {
    String? name,
    String? routineId,
    String? templateId,
    bool completed = true,
  }) => database
      .into(database.workouts)
      .insert(
        db.WorkoutsCompanion.insert(
          id: id,
          name: name ?? id,
          date: day.millisecondsSinceEpoch,
          startedAt: Value(
            day.subtract(const Duration(minutes: 50)).millisecondsSinceEpoch,
          ),
          completedAt: completed
              ? Value(day.millisecondsSinceEpoch)
              : const Value.absent(),
          routineId: Value(routineId),
          templateId: Value(templateId),
          createdAt: day.millisecondsSinceEpoch,
        ),
      );

  Future<void> set(
    String workoutId,
    String exerciseId, {
    int? reps,
    double? kg,
    double? meters,
    int? minutes,
  }) async {
    final weId = 'we-$workoutId-$exerciseId';
    await database
        .into(database.workoutExercises)
        .insertOnConflictUpdate(
          db.WorkoutExercisesCompanion.insert(
            id: weId,
            workoutId: workoutId,
            exerciseId: exerciseId,
            sortOrder: 0,
          ),
        );
    await database
        .into(database.exerciseSets)
        .insert(
          db.ExerciseSetsCompanion.insert(
            id: 's${n++}',
            workoutExerciseId: weId,
            setNumber: n,
            actualReps: Value(reps),
            actualWeightKg: Value(kg),
            actualDistanceMeters: Value(meters),
            actualDurationMinutes: Value(minutes),
          ),
        );
  }

  final d0 = DateTime(2026, 11, 12, 19);
  final d1 = DateTime(2026, 11, 24, 19);

  test(
    'row summaries: volume, sets, minutes, cardio distance and PRs',
    () async {
      await exercise('bench');
      await exercise('skate');
      await workout('w0', d0);
      await set('w0', 'bench', reps: 8, kg: 80);
      await set('w0', 'bench', reps: 8, kg: 80);
      await workout('w1', d1);
      await set('w1', 'bench', reps: 5, kg: 85); // heavier than ever: PR
      await set('w1', 'bench', reps: 8, kg: 80);
      await workout('s1', d1.add(const Duration(days: 1)));
      await set('s1', 'skate', meters: 11200, minutes: 42);

      final rows = await summaries.rowSummaries();
      expect(rows['w0']!.hasPr, isFalse, reason: 'first session is no PR');
      expect(rows['w0']!.volumeKg, 1280);
      expect(rows['w0']!.setCount, 2);
      expect(rows['w0']!.minutes, 50);
      expect(rows['w1']!.hasPr, isTrue);
      expect(rows['s1']!.isCardio, isTrue);
      expect(rows['s1']!.distanceKm, closeTo(11.2, 1e-9));
    },
  );

  test('last set per exercise is the latest logged one', () async {
    await exercise('bench');
    await workout('w0', d0);
    await set('w0', 'bench', reps: 8, kg: 77.5);
    await workout('w1', d1);
    await set('w1', 'bench', reps: 8, kg: 80);
    final last = await summaries.lastSetPerExercise();
    expect(last['bench']!.weightKg, 80);
  });

  test('routines group replays and keep the most recent per name', () async {
    await workout('a', d0, name: 'Bench day', routineId: 'r1');
    await workout('b', d1, name: 'Bench day', routineId: 'r1');
    await workout('c', d1.add(const Duration(days: 2)), name: 'Skate');
    await workout(
      'd',
      d1.add(const Duration(days: 3)),
      name: 'Legs',
      completed: false,
    );
    final list = await WorkoutRepository(database).getAll();
    final routines = groupRoutines(list, await summaries.rowSummaries());
    expect(routines.map((r) => r.latest.name), ['Skate', 'Bench day']);
    expect(routines.last.count, 2);
  });

  test('weeks group by calendar week and filter by range', () async {
    await workout('a', DateTime(2026, 11, 17, 18)); // Tue, week of 16 Nov
    await workout('b', DateTime(2026, 11, 22, 18)); // Sun, same week
    await workout('c', DateTime(2026, 11, 24, 18)); // next week
    final list = await WorkoutRepository(database).getAll();
    final rows = await summaries.rowSummaries();
    final weeks = groupWeeks(list, rows);
    expect(weeks.length, 2);
    expect(weeks.first.start, DateTime(2026, 11, 23));
    expect(weeks.last.days, {1, 6});
    final filtered = groupWeeks(
      list,
      rows,
      from: DateTime(2026, 11, 20),
      until: DateTime(2026, 11, 23),
    );
    expect(filtered.single.workouts.single.$1.id, 'b');
  });

  test('template cards: exercises, last done and New', () async {
    await exercise('bench');
    final now = DateTime.now();
    for (final (id, created) in [
      ('t-new', now.subtract(const Duration(days: 2))),
      ('t-used', now.subtract(const Duration(days: 60))),
    ]) {
      await database
          .into(database.workoutTemplates)
          .insert(
            db.WorkoutTemplatesCompanion.insert(
              id: id,
              name: id,
              startDate: created.millisecondsSinceEpoch,
              createdAt: created.millisecondsSinceEpoch,
              updatedAt: created.millisecondsSinceEpoch,
            ),
          );
      await database
          .into(database.workoutTemplateExercises)
          .insert(
            db.WorkoutTemplateExercisesCompanion.insert(
              id: 'te-$id',
              templateId: id,
              exerciseId: 'bench',
              sortOrder: 0,
            ),
          );
      for (var i = 1; i <= 4; i++) {
        await database
            .into(database.workoutTemplateSets)
            .insert(
              db.WorkoutTemplateSetsCompanion.insert(
                id: 'ts-$id-$i',
                templateExerciseId: 'te-$id',
                setNumber: i,
                reps: const Value(5),
                weightKg: const Value(85),
              ),
            );
      }
    }
    await workout('w', d1, templateId: 't-used');
    final cards = {for (final c in await summaries.templateCards()) c.id: c};
    expect(cards['t-new']!.isNew(now), isTrue);
    expect(cards['t-used']!.isNew(now), isFalse);
    expect(cards['t-used']!.lastDone, d1);
    expect(cards['t-new']!.exercises.single.sets, 4);
    expect(cards['t-new']!.setCount, 4);
  });

  test('same-day workouts sort by time of day, newest first', () async {
    final day = DateTime(2026, 11, 20);
    Future<void> at(String id, int hour) => database
        .into(database.workouts)
        .insert(
          db.WorkoutsCompanion.insert(
            id: id,
            name: id,
            // `date` is stored as the day only.
            date: day.millisecondsSinceEpoch,
            startedAt: Value(
              day.add(Duration(hours: hour)).millisecondsSinceEpoch,
            ),
            completedAt: Value(
              day
                  .add(Duration(hours: hour, minutes: 45))
                  .millisecondsSinceEpoch,
            ),
            createdAt: day.millisecondsSinceEpoch,
          ),
        );
    // Inserted out of order: the evening session first.
    await at('evening', 19);
    await at('morning', 7);
    await at('noon', 12);
    await workout('yesterday', DateTime(2026, 11, 19, 21));

    final all = await WorkoutRepository(database).getAll();
    expect(all.map((w) => w.id), ['evening', 'noon', 'morning', 'yesterday']);
    final routines = groupRoutines(all, const {});
    expect(routines.first.latest.id, 'evening');
  });
}
