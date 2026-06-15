import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/exercise/services/seance_converter.dart';
import 'package:fitfat/src/models/exercise.dart';

void main() {
  const uuid = Uuid();

  test('converts empty seance to empty workout', () {
    final seance = Seance(
      id: uuid.v7(),
      startedAt: DateTime(2026, 6, 4, 10, 0),
      exercises: [],
    );
    final workout = convertSeanceToWorkout(seance);

    expect(workout.id, seance.id);
    expect(workout.name, '');
    expect(workout.startTime, seance.startedAt);
    expect(workout.endTime, isNull);
    expect(workout.entries, isEmpty);
    expect(workout.source, 'manual');
    expect(workout.isGuided, false);
  });

  test('converts guided seance with completed sets', () {
    final seance = Seance(
      id: uuid.v7(),
      name: 'Push Day',
      startedAt: DateTime(2026, 6, 4, 10, 0),
      completedAt: DateTime(2026, 6, 4, 11, 0),
      isGuided: true,
      exercises: [
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(
            id: 'e1',
            name: 'Bench Press',
            category: 'Chest',
            type: 'weightlifting',
            met: 5.5,
          ),
          startedAt: DateTime(2026, 6, 4, 10, 0),
          completedAt: DateTime(2026, 6, 4, 10, 30),
          sets: [
            const ExerciseSet(reps: 10, weight: 50),
            const ExerciseSet(reps: 10, weight: 50),
            ExerciseSet(
              reps: 10,
              weight: 50,
              completedAt: DateTime(2026, 6, 4, 10, 5),
            ),
          ],
        ),
      ],
    );

    final workout = convertSeanceToWorkout(seance);

    expect(workout.name, 'Push Day');
    expect(workout.endTime, seance.completedAt);
    expect(workout.isGuided, true);
    expect(workout.entries.length, 1);

    final entry = workout.entries[0];
    expect(entry.sets.length, 1); // Only completed sets are migrated
    expect(entry.sets[0].reps, 10);
    expect(entry.sets[0].weightKg, 50);
    expect(entry.sets[0].completedAt, DateTime(2026, 6, 4, 10, 5));
    expect(entry.cardioDetail, isNull);
    expect(entry.sortOrder, 0);
  });

  test('converts freeform seance with partial completion', () {
    final seance = Seance(
      id: uuid.v7(),
      name: 'Quick Session',
      startedAt: DateTime(2026, 6, 4, 14, 0),
      completedAt: DateTime(2026, 6, 4, 14, 45),
      isGuided: false,
      exercises: [
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(id: 'e2', name: 'Squat'),
          startedAt: DateTime(2026, 6, 4, 14, 0),
          sets: [
            ExerciseSet(
              reps: 5,
              weight: 80,
              completedAt: DateTime(2026, 6, 4, 14, 5),
            ),
            ExerciseSet(
              reps: 5,
              weight: 85,
              completedAt: DateTime(2026, 6, 4, 14, 10),
            ),
            const ExerciseSet(reps: 3, weight: 90), // Not completed
          ],
        ),
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(id: 'e3', name: 'Pull-ups'),
          startedAt: DateTime(2026, 6, 4, 14, 15),
          sets: [], // Empty entry — edge case
        ),
      ],
    );

    final workout = convertSeanceToWorkout(seance);

    expect(workout.name, 'Quick Session');
    expect(workout.source, 'manual');
    expect(workout.entries.length, 2);

    // First entry: only completed sets migrated
    expect(workout.entries[0].sets.length, 2);
    expect(workout.entries[0].sets[1].weightKg, 85);
    expect(workout.entries[0].cardioDetail, isNull);
    expect(workout.entries[0].sortOrder, 0);

    // Second entry: no completed sets → empty list
    expect(workout.entries[1].sets, isEmpty);
    expect(workout.entries[1].cardioDetail, isNull);
    expect(workout.entries[1].sortOrder, 1);
  });

  test('converts active seance (no end time)', () {
    final seance = Seance(
      id: uuid.v7(),
      startedAt: DateTime.now(),
      exercises: [
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(id: 'e1', name: 'Bench Press'),
          startedAt: DateTime.now(),
          sets: [
            ExerciseSet(reps: 10, weight: 50, completedAt: DateTime.now()),
          ],
        ),
      ],
    );

    final workout = convertSeanceToWorkout(seance);

    expect(workout.endTime, isNull);
    expect(workout.isActive, true);
    expect(workout.entries.length, 1);
    expect(workout.entries[0].sets.length, 1);
  });

  test('converts cardio-type exercise to CardioDetail with 0 duration', () {
    final seance = Seance(
      id: uuid.v7(),
      name: 'Cardio Session',
      startedAt: DateTime(2026, 6, 4, 16, 0),
      completedAt: DateTime(2026, 6, 4, 16, 30),
      exercises: [
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(
            id: 'c1',
            name: 'Swimming',
            category: 'Cardio',
            type: 'cardio',
            met: 6.0,
          ),
          startedAt: DateTime(2026, 6, 4, 16, 0),
          sets: [
            // Cardio exercises in old model might have dummy sets — ignore them
            const ExerciseSet(reps: 1, weight: 0),
          ],
        ),
      ],
    );

    final workout = convertSeanceToWorkout(seance);

    expect(workout.entries.length, 1);
    final entry = workout.entries[0];

    // Sets from cardio exercises are not migrated (they're dummy/warmup data)
    expect(entry.sets, isEmpty);
    expect(entry.cardioDetail, isNotNull);
    expect(entry.cardioDetail!.durationMinutes, 0);
    expect(entry.exercise.type, 'cardio');
    expect(entry.sortOrder, 0);
  });

  test('converts mixed weightlifting and cardio exercises in same session', () {
    final seance = Seance(
      id: uuid.v7(),
      name: 'Mixed Session',
      startedAt: DateTime(2026, 6, 4, 9, 0),
      completedAt: DateTime(2026, 6, 4, 10, 0),
      exercises: [
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(
            id: 'e1',
            name: 'Bench Press',
            type: 'weightlifting',
          ),
          startedAt: DateTime(2026, 6, 4, 9, 0),
          sets: [
            ExerciseSet(
              reps: 10,
              weight: 50,
              completedAt: DateTime(2026, 6, 4, 9, 5),
            ),
          ],
        ),
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(
            id: 'c1',
            name: 'Swimming',
            category: 'Cardio',
            type: 'cardio',
            met: 6.0,
          ),
          startedAt: DateTime(2026, 6, 4, 9, 30),
          sets: [],
        ),
        ExerciseEntry(
          id: uuid.v7(),
          exercise: const ExerciseDefinition(
            id: 'e2',
            name: 'Squat',
            type: 'weightlifting',
          ),
          startedAt: DateTime(2026, 6, 4, 9, 40),
          sets: [
            ExerciseSet(
              reps: 5,
              weight: 100,
              completedAt: DateTime(2026, 6, 4, 9, 45),
            ),
          ],
        ),
      ],
    );

    final workout = convertSeanceToWorkout(seance);

    expect(workout.entries.length, 3);

    // Weightlifting entry
    expect(workout.entries[0].cardioDetail, isNull);
    expect(workout.entries[0].sets.length, 1);

    // Cardio entry
    expect(workout.entries[1].cardioDetail, isNotNull);
    expect(workout.entries[1].sets, isEmpty);

    // Weightlifting entry
    expect(workout.entries[2].cardioDetail, isNull);
    expect(workout.entries[2].sets.length, 1);

    // Sort order preserved
    expect(workout.entries[0].sortOrder, 0);
    expect(workout.entries[1].sortOrder, 1);
    expect(workout.entries[2].sortOrder, 2);
  });

  test('batch conversion preserves order', () {
    final seance1 = Seance(
      id: uuid.v7(),
      name: 'First',
      startedAt: DateTime(2026, 6, 4),
      completedAt: DateTime(2026, 6, 4),
      exercises: [],
    );
    final seance2 = Seance(
      id: uuid.v7(),
      name: 'Second',
      startedAt: DateTime(2026, 6, 5),
      completedAt: DateTime(2026, 6, 5),
      exercises: [],
    );

    final workouts = convertSeancesToWorkouts([seance1, seance2]);

    expect(workouts.length, 2);
    expect(workouts[0].name, 'First');
    expect(workouts[1].name, 'Second');
    expect(workouts[0].id, seance1.id);
    expect(workouts[1].id, seance2.id);
  });
}
