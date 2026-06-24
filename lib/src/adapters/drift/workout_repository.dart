import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/providers.dart';
import '../interfaces/workout_repository.dart';
import '../../models/workout.dart' as domain;

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return DriftWorkoutRepository(ref.read(databaseProvider));
});

class DriftWorkoutRepository implements WorkoutRepository {
  DriftWorkoutRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Workout CRUD
  // ---------------------------------------------------------------------------

  /// Insert or update a workout and its sets.
  @override
  Future<void> save(
    domain.Workout workout, {
    List<domain.WeightSet>? weightSets,
    List<domain.CardioSet>? cardioSets,
  }) async {
    await _db.transaction(() async {
      await _db
          .into(_db.workouts)
          .insert(_workoutToRow(workout), mode: InsertMode.insertOrReplace);

      if (weightSets != null) {
        await (_db.delete(
          _db.weightSets,
        )..where((t) => t.workoutId.equals(workout.id))).go();
        for (final set in weightSets) {
          await _db.into(_db.weightSets).insert(_weightSetToRow(set));
        }
      }

      if (cardioSets != null) {
        await (_db.delete(
          _db.cardioSets,
        )..where((t) => t.workoutId.equals(workout.id))).go();
        for (final set in cardioSets) {
          await _db.into(_db.cardioSets).insert(_cardioSetToRow(set));
        }
      }
    });
  }

  /// Load a workout with all its sets by ID.
  @override
  Future<(domain.Workout, List<domain.WeightSet>, List<domain.CardioSet>)>
  getById(String id) async {
    final row = await (_db.select(
      _db.workouts,
    )..where((t) => t.id.equals(id))).getSingle();
    final weightSets = await getWeightSets(id);
    final cardioSets = await _getCardioSets(id);
    return (_rowToWorkout(row), weightSets, cardioSets);
  }

  /// List workouts with scheduledDate >= today and startedAt IS NULL.
  @override
  Future<List<domain.Workout>> listUpcoming() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows =
        await (_db.select(_db.workouts)..where(
              (t) =>
                  t.scheduledDate.isBiggerThanValue(
                    today.subtract(const Duration(days: 1)),
                  ) &
                  t.startedAt.isNull(),
            ))
            .get();
    return rows.map(_rowToWorkout).toList();
  }

  /// List workouts whose scheduledDate matches the given date.
  @override
  Future<List<domain.Workout>> listByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (_db.select(
      _db.workouts,
    )..where((t) => t.scheduledDate.isBetweenValues(start, end))).get();
    return rows.map(_rowToWorkout).toList();
  }

  /// List completed workouts, optionally filtered by date range.
  @override
  Future<List<domain.Workout>> listCompleted({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _db.select(_db.workouts)
      ..where((t) => t.completedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);
    if (from != null) {
      query.where((t) => t.completedAt.isBiggerThanValue(from));
    }
    if (to != null) {
      query.where((t) => t.completedAt.isSmallerThanValue(to));
    }
    final rows = await query.get();
    return rows.map(_rowToWorkout).toList();
  }

  /// Get the currently active workout (startedAt NOT NULL, completedAt IS NULL).
  @override
  Future<domain.Workout?> getActive() async {
    final rows =
        await (_db.select(_db.workouts)
              ..where((t) => t.startedAt.isNotNull() & t.completedAt.isNull())
              ..limit(1))
            .get();
    if (rows.isEmpty) return null;
    return _rowToWorkout(rows.single);
  }

  /// Set startedAt = now.
  @override
  Future<void> start(String id) async {
    await _db.customUpdate(
      'UPDATE workouts SET started_at = ? WHERE id = ?',
      variables: [Variable(DateTime.now()), Variable(id)],
    );
  }

  /// Set completedAt = now.
  @override
  Future<void> complete(String id) async {
    await _db.customUpdate(
      'UPDATE workouts SET completed_at = ? WHERE id = ?',
      variables: [Variable(DateTime.now()), Variable(id)],
    );
  }

  /// Delete a workout and cascade delete all its sets.
  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.weightSets,
      )..where((t) => t.workoutId.equals(id))).go();
      await (_db.delete(
        _db.cardioSets,
      )..where((t) => t.workoutId.equals(id))).go();
      await (_db.delete(_db.workouts)..where((t) => t.id.equals(id))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Weight set operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> addWeightSet(domain.WeightSet set) async {
    await _db.into(_db.weightSets).insert(_weightSetToRow(set));
  }

  @override
  Future<void> updateWeightSet(domain.WeightSet set) async {
    // Note: .replace() auto-matches on primary key — do NOT combine with .where()
    await (_db.update(_db.weightSets)).replace(_weightSetToRow(set));
  }

  // ---------------------------------------------------------------------------
  // Cardio set operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> addCardioSet(domain.CardioSet set) async {
    await _db.into(_db.cardioSets).insert(_cardioSetToRow(set));
  }

  @override
  Future<void> updateCardioSet(domain.CardioSet set) async {
    // Note: .replace() auto-matches on primary key — do NOT combine with .where()
    await (_db.update(_db.cardioSets)).replace(_cardioSetToRow(set));
  }

  /// Remove a set by ID (works for both weight_sets and cardio_sets).
  @override
  Future<void> removeSet(String setId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.weightSets)..where((t) => t.id.equals(setId))).go();
      await (_db.delete(_db.cardioSets)..where((t) => t.id.equals(setId))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Get all weight sets for a workout, ordered by sort_order.
  @override
  Future<List<domain.WeightSet>> getWeightSets(String workoutId) async {
    final rows =
        await (_db.select(_db.weightSets)
              ..where((t) => t.workoutId.equals(workoutId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(_rowToWeightSet).toList();
  }

  /// Get all cardio sets for a workout, ordered by sort_order.
  @override
  Future<List<domain.CardioSet>> getCardioSets(String workoutId) async {
    final rows =
        await (_db.select(_db.cardioSets)
              ..where((t) => t.workoutId.equals(workoutId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(_rowToCardioSet).toList();
  }

  /// Get weight sets for multiple workouts, keyed by workoutId.
  /// Uses a single `IN` query for efficiency.
  @override
  Future<Map<String, List<domain.WeightSet>>> getWeightSetsByWorkoutIds(
    List<String> workoutIds,
  ) async {
    if (workoutIds.isEmpty) return {};
    final rows =
        await (_db.select(_db.weightSets)
              ..where((t) => t.workoutId.isIn(workoutIds))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    final map = <String, List<domain.WeightSet>>{};
    for (final row in rows) {
      map.putIfAbsent(row.workoutId, () => []).add(_rowToWeightSet(row));
    }
    return map;
  }

  /// Get completed weight sets for a specific exercise across all workouts.
  @override
  Future<List<domain.WeightSet>> getCompletedWeightSetsByExercise(
    String exerciseId,
  ) async {
    final rows =
        await (_db.select(_db.weightSets)
              ..where(
                (t) =>
                    t.exerciseId.equals(exerciseId) & t.completedAt.isNotNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]))
            .get();
    return rows.map(_rowToWeightSet).toList();
  }

  Future<List<domain.CardioSet>> _getCardioSets(String workoutId) async {
    final rows =
        await (_db.select(_db.cardioSets)
              ..where((t) => t.workoutId.equals(workoutId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(_rowToCardioSet).toList();
  }

  // ---------------------------------------------------------------------------
  // Domain <-> DB row mapping
  // ---------------------------------------------------------------------------

  WorkoutsCompanion _workoutToRow(domain.Workout w) {
    return WorkoutsCompanion(
      id: Value(w.id),
      name: Value(w.name),
      scheduledDate: Value(w.scheduledDate),
      startedAt: Value(w.startedAt),
      completedAt: Value(w.completedAt),
      notes: Value(w.notes),
      source: Value(w.source.name),
    );
  }

  domain.Workout _rowToWorkout(WorkoutRow r) {
    return domain.Workout(
      id: r.id,
      name: r.name,
      scheduledDate: r.scheduledDate,
      startedAt: r.startedAt,
      completedAt: r.completedAt,
      notes: r.notes,
      source: domain.WorkoutSource.values.firstWhere(
        (e) => e.name == r.source,
        orElse: () => domain.WorkoutSource.manual,
      ),
    );
  }

  WeightSetsCompanion _weightSetToRow(domain.WeightSet s) {
    return WeightSetsCompanion(
      id: Value(s.id),
      workoutId: Value(s.workoutId),
      exerciseId: Value(s.exerciseId),
      sortOrder: Value(s.sortOrder),
      plannedReps: Value(s.plannedReps),
      plannedWeightKg: Value(s.plannedWeightKg),
      plannedRestSeconds: Value(s.plannedRestSeconds),
      actualReps: Value(s.actualReps),
      actualWeightKg: Value(s.actualWeightKg),
      completedAt: Value(s.completedAt),
      notes: Value(s.notes),
    );
  }

  domain.WeightSet _rowToWeightSet(WeightSetRow r) {
    return domain.WeightSet(
      id: r.id,
      workoutId: r.workoutId,
      exerciseId: r.exerciseId,
      sortOrder: r.sortOrder,
      plannedReps: r.plannedReps,
      plannedWeightKg: r.plannedWeightKg,
      plannedRestSeconds: r.plannedRestSeconds,
      actualReps: r.actualReps,
      actualWeightKg: r.actualWeightKg,
      completedAt: r.completedAt,
      notes: r.notes,
    );
  }

  CardioSetsCompanion _cardioSetToRow(domain.CardioSet s) {
    return CardioSetsCompanion(
      id: Value(s.id),
      workoutId: Value(s.workoutId),
      exerciseId: Value(s.exerciseId),
      sortOrder: Value(s.sortOrder),
      plannedDurationMinutes: Value(s.plannedDurationMinutes),
      actualDurationMinutes: Value(s.actualDurationMinutes),
      completedAt: Value(s.completedAt),
      notes: Value(s.notes),
    );
  }

  domain.CardioSet _rowToCardioSet(CardioSetRow r) {
    return domain.CardioSet(
      id: r.id,
      workoutId: r.workoutId,
      exerciseId: r.exerciseId,
      sortOrder: r.sortOrder,
      plannedDurationMinutes: r.plannedDurationMinutes,
      actualDurationMinutes: r.actualDurationMinutes,
      completedAt: r.completedAt,
      notes: r.notes,
    );
  }
}
