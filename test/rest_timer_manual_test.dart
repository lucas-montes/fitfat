import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:fitfat/src/notifications/rest_timer.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rest is decided on the fly: a rest started by hand has no planned value,
/// so no target, no alarm, but the time taken must still be recorded on the
/// set it followed. Before, a rest without a target was silently dropped.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase database;
  late WorkoutRepository workouts;
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(database);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<String> seedSkateSet() async {
    await database
        .into(database.exercises)
        .insert(
          db.ExercisesCompanion.insert(
            id: 'skate',
            name: 'Skating',
            exerciseType: 'cardio',
            createdAt: 1,
          ),
        );
    final workout = newWorkout(name: 'Skate', date: DateTime(2026, 11, 23));
    final we = newWorkoutExercise(
      workoutId: workout.id,
      exerciseId: 'skate',
      exerciseName: 'Skating',
      sortOrder: 0,
    );
    // Duration only: no distance, no planned rest.
    final set = newPlannedSet(
      workoutExerciseId: we.id,
      setNumber: 1,
      durationMinutes: 45,
    );
    await workouts.insert(
      workout: workout,
      exercises: [we],
      setGroups: [
        [set],
      ],
    );
    return set.id;
  }

  Future<int?> recordedRest(String setId) async {
    final row = await (database.select(
      database.exerciseSets,
    )..where((t) => t.id.equals(setId))).getSingle();
    return row.actualRestSeconds;
  }

  test('a manual rest has no target and is recorded when stopped', () async {
    final setId = await seedSkateSet();
    final notifier = container.read(restTimerProvider.notifier);

    await notifier.startRest(setId: setId);
    final running = container.read(restTimerProvider);
    expect(running.isResting, isTrue);
    expect(running.setId, setId);
    expect(running.plannedSeconds, isNull);
    expect(
      running.isOverdue(DateTime.now().add(const Duration(hours: 1))),
      isFalse,
    );
    expect(prefs.getInt(restPlannedSecondsKey), isNull);

    await notifier.cancelRest();
    expect(container.read(restTimerProvider).isResting, isFalse);
    expect(await recordedRest(setId), isNotNull);
  });

  test('a planned rest keeps its target', () async {
    final setId = await seedSkateSet();
    final notifier = container.read(restTimerProvider.notifier);

    await notifier.startRest(
      planned: const Duration(seconds: 90),
      setId: setId,
    );
    expect(container.read(restTimerProvider).plannedSeconds, 90);
    expect(prefs.getInt(restPlannedSecondsKey), 90);

    await notifier.cancelRest();
    expect(await recordedRest(setId), isNotNull);
  });
}
