import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../database/providers.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart' as domain;

final plannedWorkoutRepositoryProvider =
    Provider<DriftPlannedWorkoutRepository>((ref) {
      return DriftPlannedWorkoutRepository(ref.read(databaseProvider));
    });

class DriftPlannedWorkoutRepository {
  DriftPlannedWorkoutRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Load all planned workouts ordered by scheduled date.
  Future<List<domain.PlannedWorkout>> listAll() async {
    final rows = await _db
        .customSelect(
          'SELECT id, scheduled_date, name, notes, source, template_id, '
          'is_completed, completed_workout_id '
          'FROM planned_workouts '
          'ORDER BY scheduled_date',
        )
        .get();
    return _assembleList(rows);
  }

  /// Load planned workouts for the week containing [weekStart].
  /// Week is considered Monday-to-Sunday inclusive.
  Future<List<domain.PlannedWorkout>> loadByWeek(DateTime weekStart) async {
    final monday = _mondayOfWeek(weekStart);
    final nextMonday = monday.add(const Duration(days: 7));
    final rows = await _db
        .customSelect(
          'SELECT id, scheduled_date, name, notes, source, template_id, '
          'is_completed, completed_workout_id '
          'FROM planned_workouts '
          'WHERE scheduled_date >= ? AND scheduled_date < ? '
          'ORDER BY scheduled_date',
          variables: [Variable(monday), Variable(nextMonday)],
        )
        .get();
    return _assembleList(rows);
  }

  /// Create a new planned workout with its entries.
  /// Returns the saved [domain.PlannedWorkout] with generated IDs if empty.
  Future<domain.PlannedWorkout> create(domain.PlannedWorkout plan) async {
    final id = plan.id.isNotEmpty ? plan.id : _uuid.v4();
    final scheduledDate = _normalizeDate(plan.scheduledDate);

    await _db.customInsert(
      'INSERT INTO planned_workouts '
      '(id, scheduled_date, name, notes, source, template_id, '
      'is_completed, completed_workout_id) '
      'VALUES (?, ?, ?, ?, ?, ?, 0, ?)',
      variables: [
        Variable(id),
        Variable(scheduledDate),
        Variable(plan.name),
        Variable(plan.notes),
        Variable(plan.source),
        Variable(plan.templateId),
        Variable<String>(plan.completedWorkoutId),
      ],
    );

    for (final entry in plan.entries) {
      await _insertEntry(id, entry);
    }

    return plan.copyWith(id: id);
  }

  /// Update a planned workout (deletes and re-inserts entries).
  Future<void> update(domain.PlannedWorkout plan) async {
    await _deleteEntries(plan.id);
    await _db.customUpdate(
      'UPDATE planned_workouts SET name = ?, scheduled_date = ?, '
      'notes = ?, source = ?, template_id = ? '
      'WHERE id = ?',
      variables: [
        Variable(plan.name),
        Variable(_normalizeDate(plan.scheduledDate)),
        Variable(plan.notes),
        Variable(plan.source),
        Variable(plan.templateId),
        Variable(plan.id),
      ],
    );
    for (final entry in plan.entries) {
      await _insertEntry(plan.id, entry);
    }
  }

  /// Delete a planned workout and its entries.
  Future<void> delete(String id) async {
    await _deleteEntries(id);
    await _db.customUpdate(
      'DELETE FROM planned_workouts WHERE id = ?',
      variables: [Variable(id)],
    );
  }

  /// Mark a planned workout as completed and link to the actual workout.
  Future<void> markCompleted(String id, String completedWorkoutId) async {
    await _db.customUpdate(
      'UPDATE planned_workouts SET is_completed = 1, '
      'completed_workout_id = ? WHERE id = ?',
      variables: [Variable(completedWorkoutId), Variable(id)],
    );
  }

  /// Look up an exercise by its exact (case-insensitive) name.
  Future<ExerciseDefinition?> findExerciseByName(String name) async {
    final rows = await _db
        .customSelect(
          'SELECT id, name, category, type, met '
          'FROM exercises WHERE LOWER(name) = ?',
          variables: [Variable(name.toLowerCase())],
        )
        .get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ExerciseDefinition(
      id: row.data['id'] as String,
      name: row.data['name'] as String,
      category: (row.data['category'] as String?) ?? 'General',
      type: (row.data['type'] as String?) ?? 'weightlifting',
      met: (row.data['met'] as num?)?.toDouble() ?? 5.0,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<List<domain.PlannedWorkout>> _assembleList(List<QueryRow> rows) async {
    final result = <domain.PlannedWorkout>[];
    for (final row in rows) {
      result.add(await _assembleOne(row));
    }
    return result;
  }

  Future<domain.PlannedWorkout> _assembleOne(QueryRow row) async {
    final id = row.data['id'] as String;
    final entries = await _loadEntries(id);
    return domain.PlannedWorkout(
      id: id,
      scheduledDate: _parseDateTime(row.data['scheduled_date']),
      name: (row.data['name'] as String?) ?? '',
      entries: entries,
      notes: row.data['notes'] as String?,
      source: (row.data['source'] as String?) ?? 'manual',
      templateId: row.data['template_id'] as String?,
      isCompleted: (row.data['is_completed'] as int?) == 1,
      completedWorkoutId: row.data['completed_workout_id'] as String?,
    );
  }

  DateTime _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError(
      'Cannot parse DateTime from $value (${value.runtimeType})',
    );
  }

  Future<List<domain.PlannedEntry>> _loadEntries(
    String plannedWorkoutId,
  ) async {
    final entryRows = await _db
        .customSelect(
          'SELECT pe.id, pe.planned_workout_id, pe.exercise_id, '
          'pe.sort_order, pe.planned_reps, pe.planned_weight_kg, '
          'pe.planned_rest_seconds, pe.note, pe.effort_target, '
          'e.name as ex_name, e.category as ex_category, '
          'e.type as ex_type, e.met as ex_met '
          'FROM planned_entries pe '
          'JOIN exercises e ON e.id = pe.exercise_id '
          'WHERE pe.planned_workout_id = ? '
          'ORDER BY pe.sort_order',
          variables: [Variable(plannedWorkoutId)],
        )
        .get();

    final entries = <domain.PlannedEntry>[];
    for (final row in entryRows) {
      final entryId = row.data['id'] as String;
      final exType = (row.data['ex_type'] as String?) ?? 'weightlifting';
      final isCardio = exType == 'cardio';

      domain.PlannedCardio? plannedCardio;
      if (isCardio) {
        final cardioRows = await _db
            .customSelect(
              'SELECT planned_duration_minutes '
              'FROM planned_cardio WHERE planned_entry_id = ?',
              variables: [Variable(entryId)],
            )
            .get();
        if (cardioRows.isNotEmpty) {
          final cardioRow = cardioRows.first;
          plannedCardio = domain.PlannedCardio(
            plannedDurationMinutes:
                cardioRow.data['planned_duration_minutes'] as int,
          );
        }
      }

      entries.add(
        domain.PlannedEntry(
          id: entryId,
          exercise: ExerciseDefinition(
            id: row.data['exercise_id'] as String,
            name: (row.data['ex_name'] as String?) ?? '',
            category: (row.data['ex_category'] as String?) ?? 'General',
            type: exType,
            met: (row.data['ex_met'] as num?)?.toDouble() ?? 5.0,
          ),
          plannedReps: row.data['planned_reps'] as int? ?? 0,
          plannedWeightKg:
              (row.data['planned_weight_kg'] as num?)?.toDouble() ?? 0.0,
          plannedRestSeconds: row.data['planned_rest_seconds'] as int?,
          sortOrder: row.data['sort_order'] as int? ?? 0,
          note: row.data['note'] as String?,
          effortTarget: row.data['effort_target'] as int?,
          plannedCardio: plannedCardio,
        ),
      );
    }
    return entries;
  }

  Future<void> _insertEntry(
    String plannedWorkoutId,
    domain.PlannedEntry entry,
  ) async {
    final entryId = entry.id.isNotEmpty ? entry.id : _uuid.v4();
    await _db.customInsert(
      'INSERT INTO planned_entries '
      '(id, planned_workout_id, exercise_id, sort_order, planned_reps, '
      'planned_weight_kg, planned_rest_seconds, note, effort_target) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(entryId),
        Variable(plannedWorkoutId),
        Variable(entry.exercise.id),
        Variable(entry.sortOrder),
        Variable(entry.plannedReps),
        Variable(entry.plannedWeightKg),
        Variable(entry.plannedRestSeconds),
        Variable(entry.note),
        Variable(entry.effortTarget),
      ],
    );

    final cardio = entry.plannedCardio;
    if (cardio != null) {
      await _db.customInsert(
        'INSERT INTO planned_cardio '
        '(id, planned_entry_id, planned_duration_minutes) '
        'VALUES (?, ?, ?)',
        variables: [
          Variable(_uuid.v4()),
          Variable(entryId),
          Variable(cardio.plannedDurationMinutes),
        ],
      );
    }
  }

  Future<void> _deleteEntries(String plannedWorkoutId) async {
    final entryRows = await _db
        .customSelect(
          'SELECT id FROM planned_entries WHERE planned_workout_id = ?',
          variables: [Variable(plannedWorkoutId)],
        )
        .get();
    for (final row in entryRows) {
      final entryId = row.data['id'] as String;
      await _db.customUpdate(
        'DELETE FROM planned_cardio WHERE planned_entry_id = ?',
        variables: [Variable(entryId)],
      );
    }
    await _db.customUpdate(
      'DELETE FROM planned_entries WHERE planned_workout_id = ?',
      variables: [Variable(plannedWorkoutId)],
    );
  }

  DateTime _mondayOfWeek(DateTime date) {
    final diff = date.weekday - 1; // weekday 1 = Monday
    return DateTime.utc(date.year, date.month, date.day - diff);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
