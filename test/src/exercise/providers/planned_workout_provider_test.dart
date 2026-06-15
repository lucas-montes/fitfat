import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/database/providers.dart';
import 'package:fitfat/src/exercise/providers/planned_workout_provider.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:fitfat/src/models/workout.dart' as domain;

void main() {
  group('PlannedWorkoutNotifier', () {
    late AppDatabase database;
    const uuid = Uuid();

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Clear seeded exercises so our known IDs are used
      await database.customUpdate('DELETE FROM exercises');

      // Seed an exercise that matches the template exercise name
      await database.customInsert(
        'INSERT INTO exercises (id, name, category, type, met) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable('ex-bench'),
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
          const Variable('ex-squat'),
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
          const Variable('ex-swim'),
          const Variable('Swimming'),
          const Variable('Cardio'),
          const Variable('cardio'),
          const Variable(6.0),
        ],
      );

      // Seed a template that matches the planned workout model
      const templateId = 'template-push-day';
      await database.customInsert(
        'INSERT INTO templates (id, name) VALUES (?, ?)',
        variables: [const Variable(templateId), const Variable('Push Day')],
      );

      // Template exercise: Bench Press (2 sets)
      const templateExId = 'te-bench';
      await database.customInsert(
        'INSERT INTO template_exercises (id, template_id, name) '
        'VALUES (?, ?, ?)',
        variables: [
          const Variable(templateExId),
          const Variable(templateId),
          const Variable('Bench Press'),
        ],
      );
      await database.customInsert(
        'INSERT INTO template_sets (id, template_exercise_id, reps, weight_kg, rest_seconds) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable('ts-bench-1'),
          const Variable(templateExId),
          const Variable(10),
          const Variable(60.0),
          const Variable(90),
        ],
      );
      await database.customInsert(
        'INSERT INTO template_sets (id, template_exercise_id, reps, weight_kg, rest_seconds) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable('ts-bench-2'),
          const Variable(templateExId),
          const Variable(8),
          const Variable(70.0),
          const Variable(90),
        ],
      );

      // Template exercise: Swimming (1 set, cardio)
      const templateExSwimId = 'te-swim';
      await database.customInsert(
        'INSERT INTO template_exercises (id, template_id, name) '
        'VALUES (?, ?, ?)',
        variables: [
          const Variable(templateExSwimId),
          const Variable(templateId),
          const Variable('Swimming'),
        ],
      );
      await database.customInsert(
        'INSERT INTO template_sets (id, template_exercise_id, reps, weight_kg, rest_seconds) '
        'VALUES (?, ?, ?, ?, ?)',
        variables: [
          const Variable('ts-swim-1'),
          const Variable(templateExSwimId),
          const Variable(0),
          const Variable(30.0), // weightKg → duration minutes for cardio
          const Variable(60),
        ],
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'createFromTemplate creates a planned workout from a template',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(database)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(plannedWorkoutProvider.notifier);

        const templateId = 'template-push-day';
        final scheduledDate = DateTime.utc(2026, 6, 17);

        final saved = await notifier.createFromTemplate(
          templateId: templateId,
          scheduledDate: scheduledDate,
        );

        // Should have entries: 2 bench press sets + 1 swimming set
        expect(saved.name, 'Push Day');
        expect(saved.entries, hasLength(3));
        expect(saved.source, 'from_template');
        expect(saved.templateId, templateId);

        // Verify bench press sets
        final benchEntries = saved.entries
            .where((e) => e.exercise.id == 'ex-bench')
            .toList();
        expect(benchEntries, hasLength(2));
        expect(benchEntries[0].plannedReps, 10);
        expect(benchEntries[0].plannedWeightKg, 60.0);
        expect(benchEntries[0].plannedRestSeconds, 90);
        expect(benchEntries[1].plannedReps, 8);
        expect(benchEntries[1].plannedWeightKg, 70.0);
        expect(benchEntries[1].plannedRestSeconds, 90);

        // Verify swimming (cardio) entry
        final swimEntries = saved.entries
            .where((e) => e.exercise.id == 'ex-swim')
            .toList();
        expect(swimEntries, hasLength(1));
        expect(swimEntries.first.plannedCardio, isNotNull);
        expect(
          swimEntries.first.plannedCardio!.plannedDurationMinutes,
          30, // weightKg → duration
        );

        // Verify state is refreshed
        final state = container.read(plannedWorkoutProvider);
        expect(state, hasLength(1));
      },
    );

    test('createFromTemplate with custom name', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(plannedWorkoutProvider.notifier);

      const templateId = 'template-push-day';
      final scheduledDate = DateTime.utc(2026, 6, 18);

      final saved = await notifier.createFromTemplate(
        templateId: templateId,
        scheduledDate: scheduledDate,
        name: 'Custom Push',
      );

      expect(saved.name, 'Custom Push');
    });

    test('createPlannedWorkout and CRUD through provider', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(plannedWorkoutProvider.notifier);

      // Create
      final created = await notifier.createPlannedWorkout(
        domain.PlannedWorkout(
          id: uuid.v4(),
          scheduledDate: DateTime.utc(2026, 6, 19),
          name: 'Leg Day',
          entries: [
            domain.PlannedEntry(
              id: uuid.v4(),
              exercise: const ExerciseDefinition(id: 'ex-squat', name: 'Squat'),
              plannedReps: 5,
              plannedWeightKg: 100.0,
              sortOrder: 0,
            ),
          ],
          source: 'manual',
        ),
      );
      expect(created.name, 'Leg Day');
      expect(container.read(plannedWorkoutProvider), hasLength(1));

      // Delete
      await notifier.deletePlannedWorkout(created.id);
      expect(container.read(plannedWorkoutProvider), hasLength(0));
    });
  });
}
