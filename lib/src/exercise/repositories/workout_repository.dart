import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/exercise_set.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';

// ---------------------------------------------------------------------------
// Rich result types
// ---------------------------------------------------------------------------

final class WorkoutWithDetails {
  final Workout workout;
  final List<ExerciseBlock> exercises;
  const WorkoutWithDetails({required this.workout, required this.exercises});
}

final class ExerciseBlock {
  final WorkoutExercise exercise;
  final List<ExerciseSet> sets;
  const ExerciseBlock({required this.exercise, required this.sets});
}

/// One workout's usage of an exercise, for the exercise detail/history screen.
/// The workout carries status/date; [sets] are that exercise's sets within it.
final class ExerciseHistoryEntry {
  final Workout workout;
  final List<ExerciseSet> sets;
  const ExerciseHistoryEntry({required this.workout, required this.sets});
}

/// Everything deleted by [WorkoutRepository.deleteWithSnapshot], captured
/// as raw Drift rows so [WorkoutRepository.restore] can re-insert the exact
/// same rows (ids + every column, including nullables like actuals/notes).
/// Local to this repository file — not part of the shared domain model.
final class WorkoutSnapshot {
  final db.Workout workout;
  final List<db.WorkoutExercise> workoutExercises;
  final List<db.ExerciseSet> exerciseSets;

  const WorkoutSnapshot({
    required this.workout,
    required this.workoutExercises,
    required this.exerciseSets,
  });
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final class WorkoutRepository {
  final db.AppDatabase _database;
  const WorkoutRepository(this._database);

  // -- Workout CRUD ---------------------------------------------------------

  Future<List<Workout>> getAll() async {
    final rows =
        await (_database.select(_database.workouts)..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<WorkoutWithDetails?> getWithDetails(String id) async {
    final row = await (_database.select(
      _database.workouts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;

    final workout = _toDomain(row);
    final exercises = await _getExerciseBlocks(id);
    return WorkoutWithDetails(workout: workout, exercises: exercises);
  }

  Future<void> insert({
    required Workout workout,
    required List<WorkoutExercise> exercises,
    required List<List<ExerciseSet>> setGroups,
  }) async {
    await _database.transaction(() async {
      await _database
          .into(_database.workouts)
          .insert(
            db.WorkoutsCompanion.insert(
              id: workout.id,
              name: workout.name,
              date: workout.date.millisecondsSinceEpoch,
              createdAt: workout.createdAt.millisecondsSinceEpoch,
            ),
          );
      for (var i = 0; i < exercises.length; i++) {
        final we = exercises[i];
        await _database
            .into(_database.workoutExercises)
            .insert(
              db.WorkoutExercisesCompanion.insert(
                id: we.id,
                workoutId: we.workoutId,
                exerciseId: we.exerciseId,
                sortOrder: we.sortOrder,
              ),
            );
        if (i < setGroups.length) {
          for (final set in setGroups[i]) {
            await _database
                .into(_database.exerciseSets)
                .insert(
                  db.ExerciseSetsCompanion.insert(
                    id: set.id,
                    workoutExerciseId: set.workoutExerciseId,
                    setNumber: set.setNumber,
                    reps: Value(set.reps),
                    weightKg: Value(set.weightKg),
                    restSeconds: Value(set.restSeconds),
                    durationMinutes: Value(set.durationMinutes),
                    distanceMeters: Value(set.distanceMeters),
                  ),
                );
          }
        }
      }
    });
  }

  /// Rewrites a pending (not-yet-started) workout's exercises and sets: the
  /// existing `workout_exercises` + `exercise_sets` are deleted and the
  /// supplied [exercises]/[setGroups] re-inserted (fresh ids). Safe only for
  /// pending workouts, where nothing has been logged yet.
  Future<void> replaceExercises({
    required String workoutId,
    required List<WorkoutExercise> exercises,
    required List<List<ExerciseSet>> setGroups,
  }) async {
    await _database.transaction(() async {
      final weRows = await (_database.select(
        _database.workoutExercises,
      )..where((t) => t.workoutId.equals(workoutId))).get();
      for (final we in weRows) {
        await (_database.delete(
          _database.exerciseSets,
        )..where((t) => t.workoutExerciseId.equals(we.id))).go();
      }
      await (_database.delete(
        _database.workoutExercises,
      )..where((t) => t.workoutId.equals(workoutId))).go();

      for (var i = 0; i < exercises.length; i++) {
        final we = exercises[i];
        await _database
            .into(_database.workoutExercises)
            .insert(
              db.WorkoutExercisesCompanion.insert(
                id: we.id,
                workoutId: we.workoutId,
                exerciseId: we.exerciseId,
                sortOrder: we.sortOrder,
              ),
            );
        if (i < setGroups.length) {
          for (final set in setGroups[i]) {
            await _database
                .into(_database.exerciseSets)
                .insert(
                  db.ExerciseSetsCompanion.insert(
                    id: set.id,
                    workoutExerciseId: set.workoutExerciseId,
                    setNumber: set.setNumber,
                    reps: Value(set.reps),
                    weightKg: Value(set.weightKg),
                    restSeconds: Value(set.restSeconds),
                    durationMinutes: Value(set.durationMinutes),
                    distanceMeters: Value(set.distanceMeters),
                  ),
                );
          }
        }
      }
    });
  }

  /// Updates the editable fields of a workout row (name, date). Safe to call
  /// on any workout; only the top-level `workouts` row is written, exercises
  /// and sets are left untouched.
  Future<void> updateWorkout({
    required String id,
    required String name,
    required DateTime date,
  }) async {
    await (_database.update(
      _database.workouts,
    )..where((t) => t.id.equals(id))).write(
      db.WorkoutsCompanion(
        name: Value(name),
        date: Value(date.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(String id) async {
    await _database.transaction(() async {
      // Delete sets for all workout_exercises of this workout
      final weIds = await (_database.select(
        _database.workoutExercises,
      )..where((t) => t.workoutId.equals(id))).get();
      for (final we in weIds) {
        await (_database.delete(
          _database.exerciseSets,
        )..where((t) => t.workoutExerciseId.equals(we.id))).go();
      }
      await (_database.delete(
        _database.workoutExercises,
      )..where((t) => t.workoutId.equals(id))).go();
      await (_database.delete(
        _database.workouts,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  // -- Workflow -------------------------------------------------------------

  Future<void> start(String id) async {
    await (_database.update(
      _database.workouts,
    )..where((t) => t.id.equals(id))).write(
      db.WorkoutsCompanion(
        startedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> complete(String id) async {
    await (_database.update(
      _database.workouts,
    )..where((t) => t.id.equals(id))).write(
      db.WorkoutsCompanion(
        completedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // -- Sets -----------------------------------------------------------------

  Future<void> updateSetActuals({
    required String setId,
    int? actualReps,
    double? actualWeightKg,
    int? actualDurationMinutes,
    double? actualDistanceMeters,
    String? notes,
  }) async {
    // Cardio actuals map to the dedicated actual columns; the planned
    // duration/distance columns are kept intact.
    final hasActual =
        actualReps != null ||
        actualWeightKg != null ||
        actualDurationMinutes != null ||
        actualDistanceMeters != null;
    await (_database.update(
      _database.exerciseSets,
    )..where((t) => t.id.equals(setId))).write(
      db.ExerciseSetsCompanion(
        actualReps: actualReps != null
            ? Value(actualReps)
            : const Value.absent(),
        actualWeightKg: actualWeightKg != null
            ? Value(actualWeightKg)
            : const Value.absent(),
        actualDurationMinutes: actualDurationMinutes != null
            ? Value(actualDurationMinutes)
            : const Value.absent(),
        actualDistanceMeters: actualDistanceMeters != null
            ? Value(actualDistanceMeters)
            : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        completedAt: hasActual
            ? Value(DateTime.now().millisecondsSinceEpoch)
            : const Value.absent(),
      ),
    );
  }

  // -- Internal helpers -----------------------------------------------------

  Future<List<ExerciseBlock>> _getExerciseBlocks(String workoutId) async {
    // Load workout_exercises joined with exercises to get exercise name
    final weRows =
        await (_database.select(_database.workoutExercises)
              ..where((t) => t.workoutId.equals(workoutId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();

    if (weRows.isEmpty) return [];

    // Load exercise names
    final exerciseIds = weRows.map((r) => r.exerciseId).toList();
    final exercises = await (_database.select(
      _database.exercises,
    )..where((t) => t.id.isIn(exerciseIds))).get();
    final exerciseNameMap = {for (final ex in exercises) ex.id: ex.name};

    final blocks = <ExerciseBlock>[];
    for (final we in weRows) {
      final sets =
          await (_database.select(_database.exerciseSets)
                ..where((t) => t.workoutExerciseId.equals(we.id))
                ..orderBy([(t) => OrderingTerm(expression: t.setNumber)]))
              .get();

      blocks.add(
        ExerciseBlock(
          exercise: WorkoutExercise(
            id: we.id,
            workoutId: we.workoutId,
            exerciseId: we.exerciseId,
            exerciseName: exerciseNameMap[we.exerciseId] ?? '',
            sortOrder: we.sortOrder,
          ),
          sets: sets.map(_toSetDomain).toList(),
        ),
      );
    }
    return blocks;
  }

  ExerciseSet _toSetDomain(db.ExerciseSet s) => ExerciseSet(
    id: s.id,
    workoutExerciseId: s.workoutExerciseId,
    setNumber: s.setNumber,
    reps: s.reps,
    weightKg: s.weightKg,
    restSeconds: s.restSeconds,
    actualReps: s.actualReps,
    actualWeightKg: s.actualWeightKg,
    actualRestSeconds: s.actualRestSeconds,
    completedAt: s.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(s.completedAt!)
        : null,
    durationMinutes: s.durationMinutes,
    distanceMeters: s.distanceMeters,
    actualDurationMinutes: s.actualDurationMinutes,
    actualDistanceMeters: s.actualDistanceMeters,
    notes: s.notes,
  );

  /// Every workout that has used [exerciseId], newest first, with that
  /// exercise's sets per workout. Backs the exercise detail history screen.
  Future<List<ExerciseHistoryEntry>> getExerciseHistory(
    String exerciseId,
  ) async {
    final weRows = await (_database.select(
      _database.workoutExercises,
    )..where((t) => t.exerciseId.equals(exerciseId))).get();
    if (weRows.isEmpty) return [];

    final workoutIds = weRows.map((r) => r.workoutId).toList();
    final workoutRows = await (_database.select(
      _database.workouts,
    )..where((t) => t.id.isIn(workoutIds))).get();
    final workoutMap = {for (final row in workoutRows) row.id: _toDomain(row)};

    final entries = <ExerciseHistoryEntry>[];
    for (final we in weRows) {
      final workout = workoutMap[we.workoutId];
      if (workout == null) continue;
      final setRows =
          await (_database.select(_database.exerciseSets)
                ..where((t) => t.workoutExerciseId.equals(we.id))
                ..orderBy([(t) => OrderingTerm(expression: t.setNumber)]))
              .get();
      entries.add(
        ExerciseHistoryEntry(
          workout: workout,
          sets: setRows.map(_toSetDomain).toList(),
        ),
      );
    }
    entries.sort((a, b) => b.workout.date.compareTo(a.workout.date));
    return entries;
  }

  /// Deletes a workout and all its rows (exercise_sets → workout_exercises →
  /// workouts) inside one transaction, returning a [WorkoutSnapshot] of every
  /// row removed so [restore] can put them back exactly.
  Future<WorkoutSnapshot> deleteWithSnapshot(String id) async {
    return _database.transaction(() async {
      final workoutRow = await (_database.select(
        _database.workouts,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (workoutRow == null) {
        throw StateError('Cannot delete workout "$id": row not found.');
      }

      final weRows = await (_database.select(
        _database.workoutExercises,
      )..where((t) => t.workoutId.equals(id))).get();
      final weIds = weRows.map((r) => r.id).toList();

      final setRows = weIds.isEmpty
          ? <db.ExerciseSet>[]
          : await (_database.select(
              _database.exerciseSets,
            )..where((t) => t.workoutExerciseId.isIn(weIds))).get();

      for (final weId in weIds) {
        await (_database.delete(
          _database.exerciseSets,
        )..where((t) => t.workoutExerciseId.equals(weId))).go();
      }
      await (_database.delete(
        _database.workoutExercises,
      )..where((t) => t.workoutId.equals(id))).go();
      await (_database.delete(
        _database.workouts,
      )..where((t) => t.id.equals(id))).go();

      return WorkoutSnapshot(
        workout: workoutRow,
        workoutExercises: weRows,
        exerciseSets: setRows,
      );
    });
  }

  /// Re-inserts a [WorkoutSnapshot] taken by [deleteWithSnapshot], restoring
  /// every row with its original ids and column values (including nullable
  /// started_at / completed_at / notes and set actuals).
  Future<void> restore(WorkoutSnapshot snapshot) async {
    await _database.transaction(() async {
      final w = snapshot.workout;
      await _database
          .into(_database.workouts)
          .insert(
            db.WorkoutsCompanion.insert(
              id: w.id,
              name: w.name,
              date: w.date,
              startedAt: Value(w.startedAt),
              completedAt: Value(w.completedAt),
              notes: Value(w.notes),
              createdAt: w.createdAt,
            ),
          );
      for (final we in snapshot.workoutExercises) {
        await _database
            .into(_database.workoutExercises)
            .insert(
              db.WorkoutExercisesCompanion.insert(
                id: we.id,
                workoutId: we.workoutId,
                exerciseId: we.exerciseId,
                sortOrder: we.sortOrder,
              ),
            );
      }
      for (final s in snapshot.exerciseSets) {
        await _database
            .into(_database.exerciseSets)
            .insert(
              db.ExerciseSetsCompanion.insert(
                id: s.id,
                workoutExerciseId: s.workoutExerciseId,
                setNumber: s.setNumber,
                reps: Value(s.reps),
                weightKg: Value(s.weightKg),
                restSeconds: Value(s.restSeconds),
                actualReps: Value(s.actualReps),
                actualWeightKg: Value(s.actualWeightKg),
                actualRestSeconds: Value(s.actualRestSeconds),
                completedAt: Value(s.completedAt),
                durationMinutes: Value(s.durationMinutes),
                distanceMeters: Value(s.distanceMeters),
                actualDurationMinutes: Value(s.actualDurationMinutes),
                actualDistanceMeters: Value(s.actualDistanceMeters),
                notes: Value(s.notes),
              ),
            );
      }
    });
  }

  /// Records the actual rest (seconds) taken after a set, when its rest
  /// period ends or is cancelled. Only ever called with a recorded value.
  Future<void> recordSetRest({
    required String setId,
    required int actualRestSeconds,
  }) async {
    await (_database.update(
      _database.exerciseSets,
    )..where((t) => t.id.equals(setId))).write(
      db.ExerciseSetsCompanion(actualRestSeconds: Value(actualRestSeconds)),
    );
  }

  /// Adds an exercise to an active workout with default empty sets.
  Future<void> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
  }) async {
    // Get the exercise name
    final exerciseRow = await (_database.select(
      _database.exercises,
    )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
    if (exerciseRow == null) return;

    // Determine the next sort order
    final existingWE =
        await (_database.select(_database.workoutExercises)
              ..where((t) => t.workoutId.equals(workoutId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    final nextSortOrder = existingWE.isEmpty
        ? 0
        : existingWE.first.sortOrder + 1;

    // Create the workout exercise
    final we = WorkoutExercise(
      id: const Uuid().v7(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      exerciseName: exerciseRow.name,
      sortOrder: nextSortOrder,
    );

    await _database.transaction(() async {
      await _database
          .into(_database.workoutExercises)
          .insert(
            db.WorkoutExercisesCompanion.insert(
              id: we.id,
              workoutId: we.workoutId,
              exerciseId: we.exerciseId,
              sortOrder: we.sortOrder,
            ),
          );
      // Add one empty planned set
      await _database
          .into(_database.exerciseSets)
          .insert(
            db.ExerciseSetsCompanion.insert(
              id: const Uuid().v7(),
              workoutExerciseId: we.id,
              setNumber: 1,
            ),
          );
    });
  }

  /// Creates a copy of an existing workout with new IDs and today's date.
  /// Copies all exercises and sets from the source workout.
  Future<Workout> copyWorkout({
    required String sourceWorkoutId,
    String? newName,
    DateTime? newDate,
  }) async {
    final source = await getWithDetails(sourceWorkoutId);
    if (source == null) {
      throw StateError('Source workout not found: $sourceWorkoutId');
    }

    final date = newDate ?? DateTime.now();
    final name = newName ?? '${source.workout.name} (Copy)';
    final newWorkout = Workout(
      id: const Uuid().v7(),
      name: name,
      date: date,
      createdAt: DateTime.now(),
    );

    // Create new workout exercises and sets
    final newExercises = <WorkoutExercise>[];
    final newSetGroups = <List<ExerciseSet>>[];

    for (int i = 0; i < source.exercises.length; i++) {
      final block = source.exercises[i];
      final newWe = WorkoutExercise(
        id: const Uuid().v7(),
        workoutId: newWorkout.id,
        exerciseId: block.exercise.exerciseId,
        exerciseName: block.exercise.exerciseName,
        sortOrder: block.exercise.sortOrder,
      );
      newExercises.add(newWe);

      final newSets = block.sets
          .map(
            (set) => ExerciseSet(
              id: const Uuid().v7(),
              workoutExerciseId: newWe.id,
              setNumber: set.setNumber,
              reps: set.reps,
              weightKg: set.weightKg,
              restSeconds: set.restSeconds,
              durationMinutes: set.durationMinutes,
              distanceMeters: set.distanceMeters,
            ),
          )
          .toList();
      newSetGroups.add(newSets);
    }

    await insert(
      workout: newWorkout,
      exercises: newExercises,
      setGroups: newSetGroups,
    );

    return newWorkout;
  }

  Workout _toDomain(db.Workout row) => Workout(
    id: row.id,
    name: row.name,
    date: DateTime.fromMillisecondsSinceEpoch(row.date),
    startedAt: row.startedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.startedAt!)
        : null,
    completedAt: row.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.completedAt!)
        : null,
    notes: row.notes,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------

/// Creates a new [Workout] with a fresh UUID v7 and the current timestamp.
Workout newWorkout({required String name, required DateTime date}) => Workout(
  id: const Uuid().v7(),
  name: name,
  date: date,
  createdAt: DateTime.now(),
);

/// Creates a new [WorkoutExercise] with a fresh UUID v7.
WorkoutExercise newWorkoutExercise({
  required String workoutId,
  required String exerciseId,
  required String exerciseName,
  required int sortOrder,
}) => WorkoutExercise(
  id: const Uuid().v7(),
  workoutId: workoutId,
  exerciseId: exerciseId,
  exerciseName: exerciseName,
  sortOrder: sortOrder,
);

/// Creates a new planned [ExerciseSet] with a fresh UUID v7.
ExerciseSet newPlannedSet({
  required String workoutExerciseId,
  required int setNumber,
  int? reps,
  double? weightKg,
  int? restSeconds,
  int? durationMinutes,
  double? distanceMeters,
}) => ExerciseSet(
  id: const Uuid().v7(),
  workoutExerciseId: workoutExerciseId,
  setNumber: setNumber,
  reps: reps,
  weightKg: weightKg,
  restSeconds: restSeconds,
  durationMinutes: durationMinutes,
  distanceMeters: distanceMeters,
);
