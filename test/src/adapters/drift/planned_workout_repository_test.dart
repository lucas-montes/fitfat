import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/adapters/drift/planned_workout_repository.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:fitfat/src/models/workout.dart' as domain;

void main() {
  group('DriftPlannedWorkoutRepository', () {
    late AppDatabase database;
    late DriftPlannedWorkoutRepository repository;
    const uuid = Uuid();

    // Shared exercise IDs
    const benchPressId = 'ex-bench';
    const squatId = 'ex-squat';
    const swimmingId = 'ex-swim';

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftPlannedWorkoutRepository(database);

      // Clear seeded exercises and insert our own with known IDs
      await database.customUpdate('DELETE FROM exercises');
      await database.customInsert(
        'INSERT INTO exercises (id, name, category, type, met) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable(benchPressId),
          const Variable('Bench Press'),
          const Variable('Chest'),
          const Variable('weightlifting'),
          const Variable(5.0),
        ],
      );
      await database.customInsert(
        'INSERT INTO exercises (id, name, category, type, met) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable(squatId),
          const Variable('Squat'),
          const Variable('Legs'),
          const Variable('weightlifting'),
          const Variable(5.0),
        ],
      );
      await database.customInsert(
        'INSERT INTO exercises (id, name, category, type, met) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable(swimmingId),
          const Variable('Swimming'),
          const Variable('Cardio'),
          const Variable('cardio'),
          const Variable(6.0),
        ],
      );
    });

    tearDown(() async {
      await database.close();
    });

    group('create and read', () {
      test(
        'creates and reads back a planned workout with weightlifting entries',
        () async {
          final plan = domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 15),
            name: 'Push Day',
            entries: [
              domain.PlannedEntry(
                id: uuid.v4(),
                exercise: const ExerciseDefinition(
                  id: benchPressId,
                  name: 'Bench Press',
                  category: 'Chest',
                ),
                plannedReps: 10,
                plannedWeightKg: 60.0,
                plannedRestSeconds: 90,
                sortOrder: 0,
              ),
              domain.PlannedEntry(
                id: uuid.v4(),
                exercise: const ExerciseDefinition(
                  id: benchPressId,
                  name: 'Bench Press',
                  category: 'Chest',
                ),
                plannedReps: 8,
                plannedWeightKg: 70.0,
                plannedRestSeconds: 90,
                sortOrder: 1,
              ),
            ],
            source: 'manual',
          );

          final saved = await repository.create(plan);
          expect(saved.id, plan.id);

          final all = await repository.listAll();
          expect(all, hasLength(1));

          final loaded = all.first;
          expect(loaded.id, plan.id);
          expect(loaded.name, 'Push Day');
          expect(loaded.scheduledDate, DateTime.utc(2026, 6, 15));
          expect(loaded.entries, hasLength(2));
          expect(loaded.entries[0].plannedReps, 10);
          expect(loaded.entries[0].plannedWeightKg, 60.0);
          expect(loaded.entries[0].plannedRestSeconds, 90);
          expect(loaded.entries[1].plannedReps, 8);
          expect(loaded.entries[1].plannedWeightKg, 70.0);
          expect(loaded.isCompleted, false);
        },
      );

      test(
        'creates and reads back a planned workout with cardio entry',
        () async {
          final plan = domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 16),
            name: 'Cardio Day',
            entries: [
              domain.PlannedEntry(
                id: uuid.v4(),
                exercise: const ExerciseDefinition(
                  id: swimmingId,
                  name: 'Swimming',
                  category: 'Cardio',
                  type: 'cardio',
                ),
                plannedReps: 0,
                plannedWeightKg: 0,
                sortOrder: 0,
                plannedCardio: const domain.PlannedCardio(
                  plannedDurationMinutes: 30,
                ),
              ),
            ],
            source: 'manual',
          );

          final saved = await repository.create(plan);
          expect(saved.id, plan.id);

          final all = await repository.listAll();
          expect(all, hasLength(1));

          final loaded = all.first;
          expect(loaded.entries, hasLength(1));
          final cardioEntry = loaded.entries.first;
          expect(cardioEntry.plannedCardio, isNotNull);
          expect(cardioEntry.plannedCardio!.plannedDurationMinutes, 30);
        },
      );
    });

    group('update', () {
      test('updates a planned workout name and entries', () async {
        final plan = domain.PlannedWorkout(
          id: uuid.v4(),
          scheduledDate: DateTime.utc(2026, 6, 15),
          name: 'Original Name',
          entries: [
            domain.PlannedEntry(
              id: uuid.v4(),
              exercise: const ExerciseDefinition(
                id: benchPressId,
                name: 'Bench Press',
              ),
              plannedReps: 10,
              plannedWeightKg: 60.0,
              sortOrder: 0,
            ),
          ],
          source: 'manual',
        );
        await repository.create(plan);

        // Update name and entries
        final updated = plan.copyWith(
          name: 'Updated Name',
          entries: [
            domain.PlannedEntry(
              id: uuid.v4(),
              exercise: const ExerciseDefinition(
                id: squatId,
                name: 'Squat',
                category: 'Legs',
              ),
              plannedReps: 5,
              plannedWeightKg: 100.0,
              sortOrder: 0,
            ),
          ],
        );
        await repository.update(updated);

        final all = await repository.listAll();
        expect(all, hasLength(1));
        expect(all.first.name, 'Updated Name');
        expect(all.first.entries, hasLength(1));
        expect(all.first.entries.first.plannedReps, 5);
        expect(all.first.entries.first.plannedWeightKg, 100.0);
      });
    });

    group('delete', () {
      test('deletes a planned workout and its entries', () async {
        final plan = domain.PlannedWorkout(
          id: uuid.v4(),
          scheduledDate: DateTime.utc(2026, 6, 15),
          name: 'To Delete',
          entries: [
            domain.PlannedEntry(
              id: uuid.v4(),
              exercise: const ExerciseDefinition(
                id: benchPressId,
                name: 'Bench Press',
              ),
              plannedReps: 10,
              plannedWeightKg: 60.0,
              sortOrder: 0,
            ),
          ],
          source: 'manual',
        );
        await repository.create(plan);
        expect(await repository.listAll(), hasLength(1));

        await repository.delete(plan.id);
        expect(await repository.listAll(), hasLength(0));

        // Verify entries are also deleted
        final entryRows = await database
            .customSelect(
              'SELECT id FROM planned_entries WHERE planned_workout_id = ?',
              variables: [Variable(plan.id)],
            )
            .get();
        expect(entryRows, hasLength(0));
      });
    });

    group('loadByWeek', () {
      test('returns only planned workouts in the given week', () async {
        // Monday June 8, 2026
        final monday = DateTime.utc(2026, 6, 8);

        // In week (June 8-14): June 10
        await repository.create(
          domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 10),
            name: 'In Week',
            entries: [],
            source: 'manual',
          ),
        );
        // Before week: June 5
        await repository.create(
          domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 5),
            name: 'Before Week',
            entries: [],
            source: 'manual',
          ),
        );
        // After week: June 16
        await repository.create(
          domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 16),
            name: 'After Week',
            entries: [],
            source: 'manual',
          ),
        );

        final weekPlans = await repository.loadByWeek(monday);
        expect(weekPlans, hasLength(1));
        expect(weekPlans.first.name, 'In Week');
      });

      test('Monday boundary includes Sunday', () async {
        // Week: June 8 (Mon) to June 14 (Sun)
        final monday = DateTime.utc(2026, 6, 8);

        await repository.create(
          domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 14), // Sunday (last day)
            name: 'Sunday Workout',
            entries: [],
            source: 'manual',
          ),
        );
        await repository.create(
          domain.PlannedWorkout(
            id: uuid.v4(),
            scheduledDate: DateTime.utc(2026, 6, 15), // Monday next week
            name: 'Next Week',
            entries: [],
            source: 'manual',
          ),
        );

        final weekPlans = await repository.loadByWeek(monday);
        expect(weekPlans, hasLength(1));
        expect(weekPlans.first.name, 'Sunday Workout');
      });
    });

    group('markCompleted', () {
      test('marks a planned workout as completed with a workout ID', () async {
        final plan = domain.PlannedWorkout(
          id: uuid.v4(),
          scheduledDate: DateTime.utc(2026, 6, 15),
          name: 'Complete Me',
          entries: [],
          source: 'manual',
        );
        await repository.create(plan);

        const completedWorkoutId = 'workout-completed-123';
        await repository.markCompleted(plan.id, completedWorkoutId);

        final all = await repository.listAll();
        expect(all, hasLength(1));
        expect(all.first.isCompleted, true);
        expect(all.first.completedWorkoutId, completedWorkoutId);
      });
    });

    group('findExerciseByName', () {
      test('finds an exercise by case-insensitive name', () async {
        final found = await repository.findExerciseByName('bench press');
        expect(found, isNotNull);
        expect(found!.id, benchPressId);
        expect(found.name, 'Bench Press');
        expect(found.type, 'weightlifting');
      });

      test('finds an exercise with different case', () async {
        final found = await repository.findExerciseByName('BENCH PRESS');
        expect(found, isNotNull);
        expect(found!.id, benchPressId);
      });

      test('returns null for unknown exercise', () async {
        final found = await repository.findExerciseByName('Does Not Exist');
        expect(found, isNull);
      });

      test('finds a cardio exercise', () async {
        final found = await repository.findExerciseByName('Swimming');
        expect(found, isNotNull);
        expect(found!.type, 'cardio');
        expect(found.met, 6.0);
      });
    });
  });
}
