import 'package:fitfat/src/exercise/repositories/workout_repository.dart';
import 'package:fitfat/src/exercise/services/workout_energy.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:fitfat/src/models/exercise_set.dart';
import 'package:flutter_test/flutter_test.dart';

/// kcal ≈ MET × kg × hours. Cardio brings its own duration; strength shares
/// what's left of the workout's elapsed time.
void main() {
  final start = DateTime(2026, 11, 23, 18);
  var n = 0;

  Exercise exercise(String id, String type, double? met) => Exercise(
    id: id,
    name: id,
    exerciseType: type,
    met: met,
    createdAt: start,
  );

  ExerciseBlock block(
    String workoutId,
    String exerciseId,
    List<ExerciseSet Function(String weId)> sets,
  ) {
    final we = newWorkoutExercise(
      workoutId: workoutId,
      exerciseId: exerciseId,
      exerciseName: exerciseId,
      sortOrder: 0,
    );
    return ExerciseBlock(exercise: we, sets: [for (final s in sets) s(we.id)]);
  }

  ExerciseSet Function(String) cardio(int minutes) =>
      (weId) => ExerciseSet(
        id: '$weId-c',
        workoutExerciseId: weId,
        setNumber: 1,
        actualDurationMinutes: minutes,
      );

  ExerciseSet Function(String) lift({bool done = true}) =>
      (weId) => ExerciseSet(
        id: '$weId-${n++}',
        workoutExerciseId: weId,
        setNumber: 1,
        reps: 10,
        actualReps: done ? 10 : null,
      );

  WorkoutWithDetails workout(
    Duration? elapsed,
    List<ExerciseBlock> Function(String id) blocks,
  ) {
    var w = newWorkout(name: 'W', date: start);
    if (elapsed != null) {
      w = w.copyWith(startedAt: start, completedAt: start.add(elapsed));
    }
    return WorkoutWithDetails(workout: w, exercises: blocks(w.id));
  }

  test('cardio uses its own duration', () {
    final catalogue = {'skate': exercise('skate', 'cardio', 7.0)};
    final energy = estimateWorkoutEnergy(
      detail: workout(
        null,
        (id) => [
          block(id, 'skate', [cardio(45)]),
        ],
      ),
      exerciseById: (id) => catalogue[id],
      weightKg: 70,
    )!;
    expect(energy.kcal, closeTo(7.0 * 70 * 0.75, 0.01)); // 367.5
    expect(energy.notCounted, isEmpty);
  });

  test('strength splits the remaining time by completed sets', () {
    final catalogue = {
      'run': exercise('run', 'cardio', 8.0),
      'bench': exercise('bench', 'weightlifting', 3.5),
      'pushup': exercise('pushup', 'weightlifting', 3.8),
    };
    // 60 min: 20 of running, 40 left; bench did 3 sets, push-ups 1 (one
    // planned set never done), so 30 and 10 minutes.
    final energy = estimateWorkoutEnergy(
      detail: workout(
        const Duration(minutes: 60),
        (id) => [
          block(id, 'run', [cardio(20)]),
          block(id, 'bench', [lift(), lift(), lift()]),
          block(id, 'pushup', [lift(), lift(done: false)]),
        ],
      ),
      exerciseById: (id) => catalogue[id],
      weightKg: 80,
    )!;
    final expected = 8.0 * 80 * 20 / 60 + 3.5 * 80 * 0.5 + 3.8 * 80 * 10 / 60;
    expect(energy.kcal, closeTo(expected, 0.01));
  });

  test('unrated exercises are named, not guessed', () {
    final catalogue = {
      'skate': exercise('skate', 'cardio', null),
      'bench': exercise('bench', 'weightlifting', 3.5),
    };
    final energy = estimateWorkoutEnergy(
      detail: workout(
        const Duration(minutes: 60),
        (id) => [
          block(id, 'skate', [cardio(30)]),
          block(id, 'bench', [lift()]),
        ],
      ),
      exerciseById: (id) => catalogue[id],
      weightKg: 70,
    )!;
    // The skating still takes its 30 minutes; bench only gets the rest.
    expect(energy.kcal, closeTo(3.5 * 70 * 0.5, 0.01));
    expect(energy.notCounted, ['skate']);
  });

  test('strength in an untimed workout is left out', () {
    final catalogue = {'bench': exercise('bench', 'weightlifting', 3.5)};
    final detail = workout(
      null,
      (id) => [
        block(id, 'bench', [lift()]),
      ],
    );
    expect(
      estimateWorkoutEnergy(
        detail: detail,
        exerciseById: (id) => catalogue[id],
        weightKg: 70,
      ),
      isNull,
    );
  });

  test('no body weight, no estimate', () {
    final catalogue = {'skate': exercise('skate', 'cardio', 7.0)};
    expect(
      estimateWorkoutEnergy(
        detail: workout(
          null,
          (id) => [
            block(id, 'skate', [cardio(45)]),
          ],
        ),
        exerciseById: (id) => catalogue[id],
        weightKg: null,
      ),
      isNull,
    );
  });
}
