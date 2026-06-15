import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../exercise/services/seance_converter.dart';
import '../../models/exercise.dart' as domain;
import '../../models/workout.dart' as domain;
import '../app_database.dart';

/// One-time data migration: reads from old tables (`seances`,
/// `exercise_entries`, `exercise_sets`) and inserts into new tables
/// (`workouts`, `workout_entries`, `workout_sets`, `cardio_details`).
///
/// Cardio-type exercises get a [domain.CardioDetail] with 0 minutes (the user
/// can update the duration later via the new UI). Old tables are preserved.
///
/// Safe to call multiple times — skips workouts whose ID already exists
/// in the new [workouts] table.
Future<void> migrateLegacySeances(AppDatabase db) async {
  await db.transaction(() async {
    // Get existing new workout IDs to skip already-migrated rows
    final existingIds = await db
        .customSelect('SELECT id FROM workouts')
        .get()
        .then((rows) => rows.map((r) => r.data['id'] as String).toSet());

    // Query old seances with their entries and sets via raw SQL
    final seanceRows = await db
        .customSelect(
          'SELECT id, name, started_at, completed_at, rest_between_sets_millis '
          'FROM seances',
        )
        .get();

    for (final seanceRow in seanceRows) {
      final seanceId = seanceRow.data['id'] as String;

      // Skip if already migrated
      if (existingIds.contains(seanceId)) continue;

      final seanceName = (seanceRow.data['name'] as String?) ?? '';
      final seanceStartedAt = seanceRow.data['started_at'] as DateTime;
      final seanceCompletedAt = seanceRow.data['completed_at'] as DateTime?;

      // Load exercise entries for this seance
      final entryRows = await db
          .customSelect(
            'SELECT ee.id, ee.exercise_id, ee.started_at, ee.completed_at, '
            'e.name as ex_name, e.category as ex_category, '
            'e.type as ex_type, e.met as ex_met '
            'FROM exercise_entries ee '
            'JOIN exercises e ON e.id = ee.exercise_id '
            'WHERE ee.seance_id = ? '
            'ORDER BY ee.started_at',
            variables: [Variable(seanceId)],
          )
          .get();

      final exercises = <domain.ExerciseEntry>[];
      for (final entryRow in entryRows) {
        final entryId = entryRow.data['id'] as String;
        final exerciseId = entryRow.data['exercise_id'] as String;
        final exName = entryRow.data['ex_name'] as String;
        final exCategory =
            (entryRow.data['ex_category'] as String?) ?? 'General';
        final exType = (entryRow.data['ex_type'] as String?) ?? 'weightlifting';
        final exMet = (entryRow.data['ex_met'] as num?)?.toDouble() ?? 5.0;

        // Load sets for this entry
        final setRows = await db
            .customSelect(
              'SELECT reps, weight, completed_at '
              'FROM exercise_sets '
              'WHERE entry_id = ?',
              variables: [Variable(entryId)],
            )
            .get();

        final sets = setRows.map((setRow) {
          final completedAt = setRow.data['completed_at'] as DateTime?;
          return domain.ExerciseSet(
            reps: setRow.data['reps'] as int,
            weight: (setRow.data['weight'] as num).toDouble(),
            completedAt: completedAt,
          );
        }).toList();

        exercises.add(
          domain.ExerciseEntry(
            id: entryId,
            exercise: domain.ExerciseDefinition(
              id: exerciseId,
              name: exName,
              category: exCategory,
              type: exType,
              met: exMet,
            ),
            sets: sets,
            startedAt: entryRow.data['started_at'] as DateTime,
            completedAt: entryRow.data['completed_at'] as DateTime?,
          ),
        );
      }

      // Build domain Seance and convert to Workout
      final seance = domain.Seance(
        id: seanceId,
        name: seanceName,
        startedAt: seanceStartedAt,
        exercises: exercises,
        completedAt: seanceCompletedAt,
      );

      final workout = convertSeanceToWorkout(seance);

      // Insert workout
      await _insertWorkout(db, workout);

      // Insert entries + sets/cardio
      for (final entry in workout.entries) {
        await _insertEntry(db, workout.id, entry);
      }
    }
  });
}

Future<void> _insertWorkout(AppDatabase db, domain.Workout workout) async {
  await db.customInsert(
    'INSERT INTO workouts '
    '(id, name, start_time, end_time, notes, source, is_guided) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable(workout.id),
      Variable(workout.name),
      Variable(workout.startTime),
      Variable(workout.endTime),
      Variable(workout.notes),
      const Variable('manual'),
      Variable(workout.isGuided ? 1 : 0),
    ],
  );
}

Future<void> _insertEntry(
  AppDatabase db,
  String workoutId,
  domain.WorkoutEntry entry,
) async {
  await db.customInsert(
    'INSERT INTO workout_entries '
    '(id, sort_order, exercise_id, workout_id, note, effort) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    variables: [
      Variable(entry.id),
      Variable(entry.sortOrder),
      Variable(entry.exercise.id),
      Variable(workoutId),
      Variable(entry.note),
      Variable(entry.effort),
    ],
  );

  // Insert weight sets
  for (final set in entry.sets) {
    await db.customInsert(
      'INSERT INTO workout_sets '
      '(id, entry_id, reps, weight_kg, completed_at) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable(const Uuid().v4()),
        Variable(entry.id),
        Variable(set.reps),
        Variable(set.weightKg),
        Variable(set.completedAt),
      ],
    );
  }

  // Insert cardio detail if present
  final cardio = entry.cardioDetail;
  if (cardio != null) {
    await db.customInsert(
      'INSERT INTO cardio_details '
      '(id, entry_id, duration_minutes) '
      'VALUES (?, ?, ?)',
      variables: [
        Variable(const Uuid().v4()),
        Variable(entry.id),
        Variable(cardio.durationMinutes),
      ],
    );
  }
}
