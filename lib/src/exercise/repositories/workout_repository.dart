import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/exercise_set.dart';
import '../../models/task.dart' show Task, TaskStatus, TaskStatusStorage;
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_template.dart';
import '../../planner/repositories/task_repository.dart'
    show newTask, taskFromRow;

/// Planned set values to seed when adding an exercise to a workout. Every field
/// is optional; nulls become empty planned values (actuals stay null until the
/// set is logged later via the set-actuals dialog).
final class PlannedSet {
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final double? distanceMeters;
  final int? restSeconds;

  const PlannedSet({
    this.reps,
    this.weightKg,
    this.durationMinutes,
    this.distanceMeters,
    this.restSeconds,
  });
}

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
              routineId: Value(workout.routineId),
              templateId: Value(workout.templateId),
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
                notes: Value(we.notes),
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
                notes: Value(we.notes),
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

  /// Sets (or clears, with null) the free-text note on one workout exercise.
  Future<void> updateExerciseNotes({
    required String workoutExerciseId,
    String? notes,
  }) async {
    final trimmed = notes?.trim();
    await (_database.update(
      _database.workoutExercises,
    )..where((t) => t.id.equals(workoutExerciseId))).write(
      db.WorkoutExercisesCompanion(
        notes: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
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

    // Load every set for the block in one bulk query, grouped in memory
    // (perf T03 — was one query per workout_exercise).
    final weIds = weRows.map((r) => r.id).toList();
    final setRows =
        await (_database.select(_database.exerciseSets)
              ..where((t) => t.workoutExerciseId.isIn(weIds))
              ..orderBy([
                (t) => OrderingTerm(expression: t.workoutExerciseId),
                (t) => OrderingTerm(expression: t.setNumber),
              ]))
            .get();
    final setsByWe = <String, List<ExerciseSet>>{};
    for (final row in setRows) {
      setsByWe
          .putIfAbsent(row.workoutExerciseId, () => [])
          .add(_toSetDomain(row));
    }

    final blocks = <ExerciseBlock>[];
    for (final we in weRows) {
      blocks.add(
        ExerciseBlock(
          exercise: WorkoutExercise(
            id: we.id,
            workoutId: we.workoutId,
            exerciseId: we.exerciseId,
            exerciseName: exerciseNameMap[we.exerciseId] ?? '',
            sortOrder: we.sortOrder,
            notes: we.notes,
          ),
          sets: setsByWe[we.id] ?? const [],
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

  /// Every **completed** workout that used [exerciseId], newest first, with
  /// that exercise's completed sets per workout. Pending/active workouts and
  /// planned-only sets are excluded (they would pollute totals and the
  /// "times done" signal); entries with zero completed sets are dropped.
  /// Backs the exercise detail history and the active-workout history sheet.
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
    )..where((t) => t.id.isIn(workoutIds) & t.completedAt.isNotNull())).get();
    final workoutMap = {for (final row in workoutRows) row.id: _toDomain(row)};

    // Load every set across all of the exercise's workout_exercises in one
    // bulk query, grouped in memory (perf T03 — was one query per entry).
    // Planned-only rows never enter the map.
    final weIds = weRows.map((r) => r.id).toList();
    final setRows =
        await (_database.select(_database.exerciseSets)
              ..where((t) => t.workoutExerciseId.isIn(weIds))
              ..orderBy([
                (t) => OrderingTerm(expression: t.workoutExerciseId),
                (t) => OrderingTerm(expression: t.setNumber),
              ]))
            .get();
    final setsByWe = <String, List<ExerciseSet>>{};
    for (final row in setRows) {
      final set = _toSetDomain(row);
      if (!set.isCompleted) continue;
      setsByWe.putIfAbsent(row.workoutExerciseId, () => []).add(set);
    }

    final entries = <ExerciseHistoryEntry>[];
    for (final we in weRows) {
      final workout = workoutMap[we.workoutId];
      if (workout == null) continue;
      final sets = setsByWe[we.id] ?? const [];
      if (sets.isEmpty) continue;
      entries.add(ExerciseHistoryEntry(workout: workout, sets: sets));
    }
    entries.sort((a, b) => b.workout.date.compareTo(a.workout.date));
    return entries;
  }

  /// Total lifted volume (kg) and total minutes across completed workouts
  /// completed on/after [fromDay] (start-of-day). Exactly two queries (a
  /// workouts→workout_exercises→exercise_sets join for volume, a workouts
  /// scan for duration) regardless of the number of workouts — the dashboard's
  /// weekly stats used to resolve `workoutDetailProvider` per workout
  /// (perf T03).
  Future<({double volumeKg, int minutes})> getVolumeAndMinutesSince(
    DateTime fromDay,
  ) async {
    final fromMillis = fromDay.millisecondsSinceEpoch;

    final joined =
        await (_database.select(_database.exerciseSets).join([
              innerJoin(
                _database.workoutExercises,
                _database.workoutExercises.id.equalsExp(
                  _database.exerciseSets.workoutExerciseId,
                ),
              ),
              innerJoin(
                _database.workouts,
                _database.workouts.id.equalsExp(
                  _database.workoutExercises.workoutId,
                ),
              ),
            ])..where(
              _database.workouts.completedAt.isBiggerOrEqualValue(fromMillis),
            ))
            .get();

    var volumeKg = 0.0;
    for (final row in joined) {
      final set = row.readTable(_database.exerciseSets);
      volumeKg += (set.actualReps ?? 0) * (set.actualWeightKg ?? 0);
    }

    final workoutRows = await (_database.select(
      _database.workouts,
    )..where((t) => t.completedAt.isBiggerOrEqualValue(fromMillis))).get();
    var minutes = 0;
    for (final row in workoutRows) {
      minutes += _toDomain(row).duration.inMinutes;
    }

    return (volumeKg: volumeKg, minutes: minutes);
  }

  /// Completed-workout volume (kg) per day, oldest first, for workouts
  /// completed on or after [fromDay]. Used by experiments charts.
  Future<List<({DateTime day, double volumeKg})>> getDailyVolumes(
    DateTime fromDay,
  ) async {
    final fromMillis = fromDay.millisecondsSinceEpoch;

    final joined =
        await (_database.select(_database.exerciseSets).join([
              innerJoin(
                _database.workoutExercises,
                _database.workoutExercises.id.equalsExp(
                  _database.exerciseSets.workoutExerciseId,
                ),
              ),
              innerJoin(
                _database.workouts,
                _database.workouts.id.equalsExp(
                  _database.workoutExercises.workoutId,
                ),
              ),
            ])..where(
              _database.workouts.completedAt.isBiggerOrEqualValue(fromMillis),
            ))
            .get();

    final totals = <String, double>{};
    for (final row in joined) {
      final set = row.readTable(_database.exerciseSets);
      final setVolume = (set.actualReps ?? 0) * (set.actualWeightKg ?? 0);
      if (setVolume == 0) continue;
      final workout = row.readTable(_database.workouts);
      final day = _startOfDay(
        DateTime.fromMillisecondsSinceEpoch(workout.completedAt!),
      );
      final key = day.millisecondsSinceEpoch.toString();
      totals[key] = (totals[key] ?? 0) + setVolume;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    return entries
        .map(
          (e) => (
            day: DateTime.fromMillisecondsSinceEpoch(int.parse(e.key)),
            volumeKg: e.value,
          ),
        )
        .toList();
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
              routineId: Value(w.routineId),
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
                notes: Value(we.notes),
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

  /// Adds an exercise to an active workout. When [plannedSets] is omitted or
  /// empty, a single empty planned set is created (legacy behavior). Otherwise
  /// the provided planned sets (reps/weight/duration/distance/rest) are inserted
  /// in order, numbered 1..n.
  Future<void> addExerciseToWorkout({
    required String workoutId,
    required String exerciseId,
    List<PlannedSet>? plannedSets,
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

    final seeds = plannedSets ?? const <PlannedSet>[];
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
      if (seeds.isEmpty) {
        // Legacy fallback: a single empty planned set.
        await _database
            .into(_database.exerciseSets)
            .insert(
              db.ExerciseSetsCompanion.insert(
                id: const Uuid().v7(),
                workoutExerciseId: we.id,
                setNumber: 1,
              ),
            );
        return;
      }
      for (var i = 0; i < seeds.length; i++) {
        final s = seeds[i];
        await _database
            .into(_database.exerciseSets)
            .insert(
              db.ExerciseSetsCompanion.insert(
                id: const Uuid().v7(),
                workoutExerciseId: we.id,
                setNumber: i + 1,
                reps: Value(s.reps),
                weightKg: Value(s.weightKg),
                restSeconds: Value(s.restSeconds),
                durationMinutes: Value(s.durationMinutes),
                distanceMeters: Value(s.distanceMeters),
              ),
            );
      }
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
        notes: block.exercise.notes,
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

  /// Creates the next replay occurrence of [sourceWorkoutId]: a pending
  /// workout with the same exercises, planned sets prefilled from the source's
  /// **actuals** (progressive overload) or its planned values per [prefill]
  /// ('actuals' | 'planned'; actuals fall back to planned when a set was never
  /// logged). Trailing " #N" / " (Copy)" is stripped from the name, the date is
  /// today (or [date]), and the occurrence joins the source's replay lineage —
  /// its `routineId`, or a fresh UUID when the source has none. Unlike
  /// [copyWorkout] this links occurrences instead of making an independent
  /// copy.
  Future<Workout> replayWorkout({
    required String sourceWorkoutId,
    String? prefill,
    DateTime? date,
  }) async {
    final source = await getWithDetails(sourceWorkoutId);
    if (source == null) {
      throw StateError('Source workout not found: $sourceWorkoutId');
    }

    final useActuals = prefill != 'planned';
    final newWorkout = Workout(
      id: const Uuid().v7(),
      name: _baseName(source.workout.name),
      date: date ?? DateTime.now(),
      routineId: source.workout.routineId ?? const Uuid().v7(),
      createdAt: DateTime.now(),
    );

    final newExercises = <WorkoutExercise>[];
    final newSetGroups = <List<ExerciseSet>>[];

    for (final block in source.exercises) {
      final newWe = WorkoutExercise(
        id: const Uuid().v7(),
        workoutId: newWorkout.id,
        exerciseId: block.exercise.exerciseId,
        exerciseName: block.exercise.exerciseName,
        sortOrder: block.exercise.sortOrder,
        notes: block.exercise.notes,
      );
      newExercises.add(newWe);

      final newSets = block.sets
          .map(
            (set) => ExerciseSet(
              id: const Uuid().v7(),
              workoutExerciseId: newWe.id,
              setNumber: set.setNumber,
              // Prefill from what was actually lifted last time; sets that
              // were never logged keep their planned values.
              reps: switch ((useActuals, set.actualReps)) {
                (true, final r?) => r,
                _ => set.reps,
              },
              weightKg: switch ((useActuals, set.actualWeightKg)) {
                (true, final w?) => w,
                _ => set.weightKg,
              },
              restSeconds: set.restSeconds,
              durationMinutes: switch ((
                useActuals,
                set.actualDurationMinutes,
              )) {
                (true, final d?) => d,
                _ => set.durationMinutes,
              },
              distanceMeters: switch ((useActuals, set.actualDistanceMeters)) {
                (true, final d?) => d,
                _ => set.distanceMeters,
              },
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

    // Carry over the "do this workout" planner task so every occurrence of
    // the routine regenerates its planner entry automatically (1:1 via
    // tasks.workout_id). Schedule fields and tags follow the source task.
    final sourceTask = await findTaskForWorkout(sourceWorkoutId);
    if (sourceTask != null) {
      final carried = sourceTask
          .copyWith(
            id: const Uuid().v7(),
            day: newWorkout.date,
            workoutId: newWorkout.id,
            seriesId: null,
            recurrence: null,
          )
          .withTaskStatus(TaskStatus.pending);
      await upsertLinkedWorkoutTask(carried);
    }

    return newWorkout;
  }

  /// Creates the next session from [details.template] on [day]: planned sets
  /// snapshotted from the blueprint, `workouts.template_id` stamped, and the
  /// routine lineage kept continuous when the template was auto-promoted
  /// (so per-template "times done" history keeps counting). When
  /// [addPlannerTask] is set, the matching "do this workout" task is created
  /// for [day] as well.
  Future<Workout> instantiateTemplate(
    WorkoutTemplateDetails details, {
    required DateTime day,
    bool addPlannerTask = true,
  }) async {
    final template = details.template;
    final session = Workout(
      id: const Uuid().v7(),
      name: template.name,
      date: DateTime(day.year, day.month, day.day),
      // Lineage continuity: sessions of one template share its provenance
      // lineage (auto-promoted routines keep counting; fresh templates group
      // under the template id).
      routineId: template.sourceRoutineId ?? template.id,
      templateId: template.id,
      createdAt: DateTime.now(),
    );

    final exercises = <WorkoutExercise>[];
    final setGroups = <List<ExerciseSet>>[];
    for (final (i, block) in details.blocks.indexed) {
      final we = newWorkoutExercise(
        workoutId: session.id,
        exerciseId: block.exercise.exerciseId,
        exerciseName: '',
        sortOrder: i,
        notes: block.exercise.notes,
      );
      exercises.add(we);
      setGroups.add([
        for (final (j, set) in block.sets.indexed)
          newPlannedSet(
            workoutExerciseId: we.id,
            setNumber: j + 1,
            reps: set.reps,
            weightKg: set.weightKg,
            restSeconds: set.restSeconds,
            durationMinutes: set.durationMinutes,
            distanceMeters: set.distanceMeters,
          ),
      ]);
    }

    await insert(workout: session, exercises: exercises, setGroups: setGroups);
    if (addPlannerTask) {
      await upsertLinkedWorkoutTask(
        newTask(day: session.date, title: session.name, workoutId: session.id),
      );
    }
    return session;
  }

  /// Creates a template from an existing session's current plan (the
  /// explicit "save this as a template" action). Returns the new template id.
  Future<String> saveAsTemplate({
    required String workoutId,
    String? name,
  }) async {
    final source = await getWithDetails(workoutId);
    if (source == null) {
      throw StateError('Workout not found: $workoutId');
    }
    final now = DateTime.now();
    final templateId = const Uuid().v7();
    await _database
        .into(_database.workoutTemplates)
        .insert(
          db.WorkoutTemplatesCompanion.insert(
            id: templateId,
            name: name?.trim().isNotEmpty == true
                ? name!.trim()
                : _baseName(source.workout.name),
            startDate: _startOfDay(source.workout.date).millisecondsSinceEpoch,
            sourceRoutineId: Value(source.workout.routineId),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
          ),
        );
    await replaceTemplateBlueprint(templateId, [
      for (final block in source.exercises)
        TemplateBlock(
          exercise: WorkoutTemplateExercise(
            id: 'adhoc',
            templateId: templateId,
            exerciseId: block.exercise.exerciseId,
            sortOrder: block.exercise.sortOrder,
            notes: block.exercise.notes,
          ),
          sets: [
            for (final set in block.sets)
              WorkoutTemplateSet(
                id: 'adhoc',
                templateExerciseId: 'adhoc',
                setNumber: set.setNumber,
                reps: set.reps,
                weightKg: set.weightKg,
                restSeconds: set.restSeconds,
                durationMinutes: set.durationMinutes,
                distanceMeters: set.distanceMeters,
              ),
          ],
        ),
    ]);
    return templateId;
  }

  /// Replace-style blueprint write shared with the editor; thin wrapper so
  /// callers of this repository don't need the template repository too.
  Future<void> replaceTemplateBlueprint(
    String templateId,
    List<TemplateBlock> blocks,
  ) async {
    await _database.transaction(() async {
      final oldExercises = await (_database.select(
        _database.workoutTemplateExercises,
      )..where((t) => t.templateId.equals(templateId))).get();
      for (final ex in oldExercises) {
        await (_database.delete(
          _database.workoutTemplateSets,
        )..where((t) => t.templateExerciseId.equals(ex.id))).go();
      }
      await (_database.delete(
        _database.workoutTemplateExercises,
      )..where((t) => t.templateId.equals(templateId))).go();
      for (final (i, block) in blocks.indexed) {
        final exerciseId = const Uuid().v7();
        await _database
            .into(_database.workoutTemplateExercises)
            .insert(
              db.WorkoutTemplateExercisesCompanion.insert(
                id: exerciseId,
                templateId: templateId,
                exerciseId: block.exercise.exerciseId,
                sortOrder: i,
                notes: Value(block.exercise.notes),
              ),
            );
        for (final (j, set) in block.sets.indexed) {
          await _database
              .into(_database.workoutTemplateSets)
              .insert(
                db.WorkoutTemplateSetsCompanion.insert(
                  id: const Uuid().v7(),
                  templateExerciseId: exerciseId,
                  setNumber: j + 1,
                  reps: Value(set.reps),
                  weightKg: Value(set.weightKg),
                  restSeconds: Value(set.restSeconds),
                  durationMinutes: Value(set.durationMinutes),
                  distanceMeters: Value(set.distanceMeters),
                ),
              );
        }
      }
      await (_database.update(
        _database.workoutTemplates,
      )..where((t) => t.id.equals(templateId))).write(
        db.WorkoutTemplatesCompanion(
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
  }

  /// The pending "do this workout" task linked to [workoutId] via its
  /// `workout_id` column, or null when the workout has no planner entry.
  Future<Task?> findTaskForWorkout(String workoutId) async {
    final rows = await (_database.select(
      _database.tasks,
    )..where((t) => t.workoutId.equals(workoutId))).get();
    return rows.isEmpty ? null : taskFromRow(rows.first);
  }

  /// Inserts or refreshes the "do this workout" planner task for a workout
  /// (shared by replay carry-over and the workout form's add-planner-task).
  Future<void> upsertLinkedWorkoutTask(Task task) async {
    await _database
        .into(_database.tasks)
        .insert(
          _taskCompanion(task),
          onConflict: DoUpdate((_) => _taskCompanion(task)),
        );
  }

  db.TasksCompanion _taskCompanion(Task t) => db.TasksCompanion.insert(
    id: t.id,
    date: DateTime(t.day.year, t.day.month, t.day.day).millisecondsSinceEpoch,
    title: t.title,
    done: t.done ? 1 : 0,
    sortOrder: t.sortOrder,
    dueDate: Value(t.dueDate?.millisecondsSinceEpoch),
    startTimeMinutes: Value(t.startTimeMinutes),
    endTimeMinutes: Value(t.endTimeMinutes),
    notes: Value(t.notes),
    workoutId: Value(t.workoutId),
    tags: Value(_encodeTags(t.tags)),
    recurrence: Value(
      t.recurrence == null ? null : jsonEncode(t.recurrence!.toJson()),
    ),
    seriesId: Value(t.seriesId),
    taskStatus: Value(t.taskStatus?.storage),
    carryOver: Value(t.carryOver),
    createdAt: t.createdAt.millisecondsSinceEpoch,
  );

  /// How many workouts in a replay lineage were completed — the "times done"
  /// count for a routine. Single grouped COUNT over completed occurrences.
  Future<int> getRoutineCompletionCount(String routineId) async {
    final count =
        await (_database.selectOnly(_database.workouts)
              ..addColumns([_database.workouts.id.count()])
              ..where(
                _database.workouts.routineId.equals(routineId) &
                    _database.workouts.completedAt.isNotNull(),
              ))
            .getSingle();
    return count.read(_database.workouts.id.count()) ?? 0;
  }

  /// Strips copy/replay suffixes so every occurrence of a routine shares one
  /// clean base name ("Push A #3", "Push A (Copy)" → "Push A").
  static final RegExp _suffixPattern = RegExp(r'\s+(#\d+|\(Copy\))$');
  static String _baseName(String name) =>
      name.replaceAll(_suffixPattern, '').trim();

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
    routineId: row.routineId,
    templateId: row.templateId,
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
  String? notes,
}) => WorkoutExercise(
  id: const Uuid().v7(),
  workoutId: workoutId,
  exerciseId: exerciseId,
  exerciseName: exerciseName,
  sortOrder: sortOrder,
  notes: notes,
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

DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

String? _encodeTags(List<String>? values) {
  if (values == null || values.isEmpty) return null;
  return jsonEncode(values);
}
