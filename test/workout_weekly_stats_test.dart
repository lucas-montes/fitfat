import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/dashboard/providers/dashboard.dart';
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Days trained" counts distinct calendar days, not workouts — two sessions on
/// one day are one day trained. That is easy to get wrong, and it is what the
/// dashboard's weekly card now shows, so it is pinned here.
///
/// The window is the current **calendar week**, Monday to Sunday. This file
/// previously encoded a rolling seven days and would have passed against the bug
/// it now guards: on a Thursday a rolling window reaches back into the previous
/// weekend, so last Friday's session is reported as this week's.
void main() {
  late db.AppDatabase database;
  late WorkoutRepository workouts;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(database);
  });

  tearDown(() => database.close());

  /// The Monday that starts the week containing [day].
  DateTime mondayOf(DateTime day) =>
      DateTime(day.year, day.month, day.day)
          .subtract(Duration(days: day.weekday - DateTime.monday));

  /// The window the dashboard uses, expressed from a reference day so the tests
  /// do not silently depend on the day they happen to run on.
  ({DateTime from, DateTime until}) windowFor(DateTime reference) {
    final from = mondayOf(reference);
    return (from: from, until: from.add(const Duration(days: 7)));
  }

  /// Inserts a completed workout on [day], starting [minutesBeforeEnd] before
  /// completion. No sets — this is about the day counting, not the volume join.
  Future<void> complete(
    String id,
    DateTime day, {
    int minutesBeforeEnd = 45,
    bool started = true,
  }) async {
    await database.into(database.workouts).insert(
      db.WorkoutsCompanion.insert(
        id: id,
        name: id,
        date: day.millisecondsSinceEpoch,
        startedAt: started
            ? Value(
                day.add(Duration(minutes: -minutesBeforeEnd))
                    .millisecondsSinceEpoch,
              )
            : const Value.absent(),
        completedAt: Value(day.millisecondsSinceEpoch),
        createdAt: day.millisecondsSinceEpoch,
      ),
    );
  }

  /// Adds a set with logged actuals to [workoutId], creating the exercise and
  /// the workout->exercise link the join needs.
  Future<void> addSet(
    String workoutId, {
    int? actualReps,
    double? actualWeightKg,
    int? actualMinutes,
  }) async {
    final workoutExId = 'we-$workoutId';
    await database
        .into(database.workoutExercises)
        .insert(
          db.WorkoutExercisesCompanion.insert(
            id: workoutExId,
            workoutId: workoutId,
            exerciseId: 'ex-$workoutId',
            sortOrder: 0,
          ),
        );
    await database.into(database.exerciseSets).insert(
      db.ExerciseSetsCompanion.insert(
        id: 'set-$workoutId',
        workoutExerciseId: workoutExId,
        setNumber: 1,
        actualReps: Value(actualReps),
        actualWeightKg: Value(actualWeightKg),
        actualDurationMinutes: Value(actualMinutes),
      ),
    );
  }

  group('days trained', () {
    test('one workout is one day', () async {
      final w = windowFor(DateTime.now());
      await complete('w1', w.from.add(const Duration(days: 1)));

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 1);
      expect(stats.minutes, 45);
    });

    test('two workouts on the same day count as one day', () async {
      final w = windowFor(DateTime.now());
      final day = w.from.add(const Duration(days: 2));
      await complete('w1', day);
      await complete('w2', day.add(const Duration(hours: 5)));

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(
        stats.daysTrained,
        1,
        reason: 'a second session the same day is not another day trained',
      );
      // Both still contribute their duration.
      expect(stats.minutes, 90);
    });

    test('workouts on different days count separately', () async {
      final w = windowFor(DateTime.now());
      await complete('w1', w.from.add(const Duration(days: 1)));
      await complete('w2', w.from.add(const Duration(days: 3)));
      await complete('w3', w.from.add(const Duration(days: 6)));

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 3);
    });

    test('no workouts is zero days', () async {
      final w = windowFor(DateTime.now());
      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 0);
      expect(stats.minutes, 0);
      expect(stats.volumeKg, 0);
    });
  });

  group('calendar-week boundaries', () {
    test('the previous week is excluded, including its weekend', () async {
      // The regression: on a Thursday the old rolling window reached back to
      // the previous Friday, reporting last weekend as this week.
      final now = DateTime.now();
      final w = windowFor(now);
      final previousWeekend = mondayOf(now).subtract(
        const Duration(days: 3), // the Friday before this week's Monday
      );
      await complete('lastFri', previousWeekend);
      await complete('lastSat', previousWeekend.add(const Duration(days: 1)));
      await complete('lastSun', previousWeekend.add(const Duration(days: 2)));

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(
        stats.daysTrained,
        0,
        reason: 'last week\'s weekend is not this week',
      );
    });

    test('every day of the current week counts, Monday through Sunday', () async {
      final w = windowFor(DateTime.now());
      for (var i = 0; i < 7; i++) {
        await complete('d$i', w.from.add(Duration(days: i)));
      }

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 7);
    });

    test('the next week is excluded by the upper bound', () async {
      final w = windowFor(DateTime.now());
      // A clock-skewed device could write a completedAt past the window.
      await complete('future', w.until.add(const Duration(days: 1)));

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 0);
    });

    test('Sunday the 11th and Monday the 12th fall in different weeks', () async {
      // Pins mondayOf itself rather than the aggregate: if the week started on
      // the wrong day, this is the boundary that would catch it.
      final sunday = DateTime(2026, 10, 11);
      final monday = DateTime(2026, 10, 12);
      expect(sunday.weekday, DateTime.sunday);
      expect(monday.weekday, DateTime.monday);

      final sundayWeek = windowFor(sunday);
      final mondayWeek = windowFor(monday);
      expect(mondayOf(sunday), DateTime(2026, 10, 5));
      expect(mondayOf(monday), DateTime(2026, 10, 12));
      expect(sundayWeek.until, mondayWeek.from);
    });
  });

  group('startOfCalendarWeek', () {
    // The helper the provider actually calls. Tested here rather than relying on
    // this file's own mondayOf, because the bug lived in the provider's window
    // and a test that recomputes the window locally would not catch it.
    test('returns the Monday of that week for every weekday', () {
      // 2026-10-05 is a Monday; 10-11 the Sunday of the same week.
      for (var day = 5; day <= 11; day++) {
        final date = DateTime(2026, 10, day);
        expect(
          startOfCalendarWeek(date),
          DateTime(2026, 10, 5),
          reason: '${date.toIso8601String()} (${date.weekday}) is not in the '
              'week beginning 2026-10-05',
        );
      }
    });

    test('Monday is its own week start', () {
      expect(startOfCalendarWeek(DateTime(2026, 10, 5)), DateTime(2026, 10, 5));
    });

    test('truncates to midnight, so the window cannot start mid-morning', () {
      final lateInTheDay = DateTime(2026, 10, 8, 23, 45, 30);
      final start = startOfCalendarWeek(lateInTheDay);
      expect(start, DateTime(2026, 10, 5));
      expect(start.hour, 0);
      expect(start.minute, 0);
    });

    test('rolls back into the previous month correctly', () {
      // 2026-10-01 is a Thursday, so its Monday is 2026-09-28.
      expect(startOfCalendarWeek(DateTime(2026, 10, 1)), DateTime(2026, 9, 28));
    });

    test('the window it produces excludes the previous weekend', () {
      // The exact shape of the reported bug: a Thursday whose rolling window
      // reached back to the previous Friday.
      final thursday = DateTime(2026, 10, 8);
      expect(thursday.weekday, DateTime.thursday);
      final from = startOfCalendarWeek(thursday);
      final previousFriday = DateTime(2026, 10, 2);
      expect(
        previousFriday.isBefore(from),
        isTrue,
        reason: 'the previous Friday must fall outside the calendar week',
      );
      // Under a rolling seven-day window it would have been inside.
      final rolling = thursday.subtract(const Duration(days: 6));
      expect(previousFriday.isAfter(rolling), isFalse);
    });
  });

  group('volume', () {
    test('sums logged actuals within the window', () async {
      final w = windowFor(DateTime.now());
      await complete('w1', w.from.add(const Duration(days: 1)));
      await addSet('w1', actualReps: 5, actualWeightKg: 100);

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.volumeKg, 500);
    });

    test('unlogged sets contribute no volume', () async {
      final w = windowFor(DateTime.now());
      await complete('w1', w.from.add(const Duration(days: 1)));
      await addSet('w1');

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.volumeKg, 0);
    });

    test('sets outside the window are ignored', () async {
      final w = windowFor(DateTime.now());
      await complete('w1', w.from.subtract(const Duration(days: 1)));
      await addSet('w1', actualReps: 5, actualWeightKg: 100);

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.volumeKg, 0);
    });

    test('cardio contributes time but no volume', () async {
      // Volume is reps x weight, so a cardio-only week is legitimately zero —
      // which is why the empty-week test keys off days, not volume.
      final w = windowFor(DateTime.now());
      await complete('run', w.from.add(const Duration(days: 1)));
      await addSet('run', actualMinutes: 30);

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 1);
      expect(stats.volumeKg, 0);
      expect(stats.minutes, 45, reason: 'from the started/completed pair');
    });
  });

  group('minutes without startedAt', () {
    test('falls back to logged set minutes', () async {
      // complete() never sets startedAt, so a session finished outside the
      // active-workout flow has no duration at all.
      final w = windowFor(DateTime.now());
      await complete('noStart', w.from.add(const Duration(days: 1)),
          started: false);
      await addSet('noStart', actualMinutes: 20);
      await addSet('noStart2', actualMinutes: 0);

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.daysTrained, 1);
      expect(stats.minutes, 20);
    });

    test('is zero when nothing was logged', () async {
      final w = windowFor(DateTime.now());
      await complete('noStart', w.from.add(const Duration(days: 1)),
          started: false);

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.minutes, 0);
    });

    test('prefers the started/completed pair over set minutes', () async {
      final w = windowFor(DateTime.now());
      await complete('started', w.from.add(const Duration(days: 1)));
      await addSet('started', actualMinutes: 5);

      final stats = await workouts.getVolumeAndMinutesBetween(w.from, w.until);
      expect(stats.minutes, 45, reason: 'the authoritative pair, not the set');
    });
  });
}