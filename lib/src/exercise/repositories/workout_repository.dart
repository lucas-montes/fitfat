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
                    durationMinutes: Value(set.durationMinutes),
                    distanceMeters: Value(set.distanceMeters),
                  ),
                );
          }
        }
      }
    });
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
    int? durationMinutes,
    double? distanceMeters,
    String? notes,
  }) async {
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
        durationMinutes: durationMinutes != null
            ? Value(durationMinutes)
            : const Value.absent(),
        distanceMeters: distanceMeters != null
            ? Value(distanceMeters)
            : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
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
          sets: sets
              .map(
                (s) => ExerciseSet(
                  id: s.id,
                  workoutExerciseId: s.workoutExerciseId,
                  setNumber: s.setNumber,
                  reps: s.reps,
                  weightKg: s.weightKg,
                  actualReps: s.actualReps,
                  actualWeightKg: s.actualWeightKg,
                  durationMinutes: s.durationMinutes,
                  distanceMeters: s.distanceMeters,
                  notes: s.notes,
                ),
              )
              .toList(),
        ),
      );
    }
    return blocks;
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
  int? durationMinutes,
  double? distanceMeters,
}) => ExerciseSet(
  id: const Uuid().v7(),
  workoutExerciseId: workoutExerciseId,
  setNumber: setNumber,
  reps: reps,
  weightKg: weightKg,
  durationMinutes: durationMinutes,
  distanceMeters: distanceMeters,
);
