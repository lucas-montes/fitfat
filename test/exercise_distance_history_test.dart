import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cardio editors open with distance shown only for exercises that have
/// tracked one; skating (time only) stays behind "+ distance".
void main() {
  late db.AppDatabase database;
  late WorkoutRepository workouts;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(database);
  });

  tearDown(() => database.close());

  Future<String> seed(
    String exerciseId, {
    double? planned,
    double? logged,
  }) async {
    await database
        .into(database.exercises)
        .insert(
          db.ExercisesCompanion.insert(
            id: exerciseId,
            name: exerciseId,
            exerciseType: 'cardio',
            createdAt: 1,
          ),
        );
    final workout = newWorkout(name: exerciseId, date: DateTime(2026, 11, 1));
    final we = newWorkoutExercise(
      workoutId: workout.id,
      exerciseId: exerciseId,
      exerciseName: exerciseId,
      sortOrder: 0,
    );
    final set = newPlannedSet(
      workoutExerciseId: we.id,
      setNumber: 1,
      durationMinutes: 30,
      distanceMeters: planned,
    );
    await workouts.insert(
      workout: workout,
      exercises: [we],
      setGroups: [
        [set],
      ],
    );
    if (logged != null) {
      await workouts.updateSetActuals(
        setId: set.id,
        actualDurationMinutes: 30,
        actualDistanceMeters: logged,
      );
    }
    return workout.id;
  }

  test('lists exercises with a planned or logged distance only', () async {
    await seed('skate');
    await seed('run', logged: 5000);
    await seed('bike', planned: 20000);

    expect(await workouts.exerciseIdsWithDistance(), {'run', 'bike'});
  });

  test('ignores deleted workouts', () async {
    final id = await seed('run', logged: 5000);
    await workouts.delete(id);

    expect(await workouts.exerciseIdsWithDistance(), isEmpty);
  });
}
