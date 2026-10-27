import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:fitfat/src/models/exercise_set.dart';
import 'package:flutter_test/flutter_test.dart';

/// Completed sessions are editable, but only their **actuals** may change.
/// This is the regression cover for the obvious wrong implementation: reusing
/// [WorkoutRepository.replaceExercises] would delete and recreate every row and
/// silently wipe what was logged.
void main() {
  late db.AppDatabase database;
  late WorkoutRepository workouts;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(database);
  });

  tearDown(() => database.close());

  Future<void> seedExercise(String id, {String type = 'weightlifting'}) async {
    await database
        .into(database.exercises)
        .insert(
          db.ExercisesCompanion.insert(
            id: id,
            name: 'Exercise $id',
            exerciseType: type,
            createdAt: 1,
          ),
        );
  }

  Future<
    ({String workoutId, String weId, ExerciseSet first, ExerciseSet second})
  >
  seedCompleted() async {
    await seedExercise('e1');
    final workout = newWorkout(name: 'Push', date: DateTime(2026, 1, 1));
    final we = newWorkoutExercise(
      workoutId: workout.id,
      exerciseId: 'e1',
      exerciseName: 'Bench',
      sortOrder: 0,
      notes: 'keep me',
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
    await workouts.updateSetActuals(
      setId: first.id,
      actualReps: 10,
      actualWeightKg: 60,
    );
    return (workoutId: workout.id, weId: we.id, first: first, second: second);
  }

  test('editing rewrites actuals and preserves the plan', () async {
    final seeded = await seedCompleted();
    final before = (await workouts.getWithDetails(seeded.workoutId))!;
    final completedAt = before.exercises.single.sets.first.completedAt;
    expect(completedAt, isNotNull);

    await workouts.saveCompletedWorkout(
      workout: before.workout.copyWith(name: 'Push day'),
      exercises: [before.exercises.single.exercise],
      setGroups: [
        [
          // Same id: this is an edit, not a new set.
          ExerciseSet(
            id: seeded.first.id,
            workoutExerciseId: seeded.weId,
            setNumber: 1,
            actualReps: 12,
            actualWeightKg: 62.5,
          ),
          // Same id but blanked: the user says it was not done after all.
          ExerciseSet(
            id: seeded.second.id,
            workoutExerciseId: seeded.weId,
            setNumber: 2,
          ),
          // Added after the session: no planned values exist for it.
          ExerciseSet(
            id: 'new-set',
            workoutExerciseId: seeded.weId,
            setNumber: 3,
            actualReps: 8,
            actualWeightKg: 70,
          ),
        ],
      ],
    );

    final after = (await workouts.getWithDetails(seeded.workoutId))!;
    expect(after.workout.name, 'Push day');
    expect(after.exercises.single.exercise.notes, 'keep me');
    final sets = after.exercises.single.sets;
    expect(sets.map((s) => s.id), [
      seeded.first.id,
      seeded.second.id,
      'new-set',
    ]);

    final first = sets[0];
    expect(first.actualReps, 12);
    expect(first.actualWeightKg, 62.5);
    expect(first.completedAt, completedAt, reason: 'an edit keeps its time');
    // Planned values survive untouched.
    expect(first.reps, 10);
    expect(first.weightKg, 60);
    expect(first.restSeconds, 90);

    final second = sets[1];
    expect(second.actualReps, isNull);
    expect(second.actualWeightKg, isNull);
    expect(second.completedAt, isNull);
    expect(second.isCompleted, isFalse);
    expect(second.reps, 8);
    expect(second.weightKg, 65);
    expect(second.restSeconds, 120);

    final added = sets[2];
    expect(added.actualReps, 8);
    expect(added.actualWeightKg, 70);
    expect(added.reps, isNull, reason: 'no plan for work added later');
    expect(added.weightKg, isNull);
  });

  test('a set removed from the completed list is deleted', () async {
    final seeded = await seedCompleted();
    final before = (await workouts.getWithDetails(seeded.workoutId))!;

    await workouts.saveCompletedWorkout(
      workout: before.workout,
      exercises: [before.exercises.single.exercise],
      setGroups: [
        [
          ExerciseSet(
            id: seeded.first.id,
            workoutExerciseId: seeded.weId,
            setNumber: 1,
            actualReps: 10,
            actualWeightKg: 60,
          ),
        ],
      ],
    );

    final after = (await workouts.getWithDetails(seeded.workoutId))!;
    expect(after.exercises.single.sets.map((s) => s.id), [seeded.first.id]);
    expect(
      await database.pendingSyncDeletes('exerciseSets'),
      contains(seeded.second.id),
    );
  });

  test('saveSetActuals clears a set back to not done', () async {
    final seeded = await seedCompleted();

    await workouts.saveSetActuals(setId: seeded.first.id);

    final after = (await workouts.getWithDetails(seeded.workoutId))!;
    final first = after.exercises.single.sets.first;
    expect(first.actualReps, isNull);
    expect(first.actualWeightKg, isNull);
    expect(first.completedAt, isNull);
    expect(first.isCompleted, isFalse);
    // The plan is still there, so the set can be logged again.
    expect(first.reps, 10);
    expect(first.weightKg, 60);
  });
}
