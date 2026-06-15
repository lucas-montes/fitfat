import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/providers.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart' as domain;
import '../../services/logger.dart';

final _log = logger('workout_history');

final workoutHistoryProvider =
    NotifierProvider<WorkoutHistoryNotifier, List<domain.Workout>>(
      WorkoutHistoryNotifier.new,
    );

class WorkoutHistoryNotifier extends Notifier<List<domain.Workout>> {
  @override
  List<domain.Workout> build() {
    Future.microtask(_loadFromDb);
    return [];
  }

  Future<List<domain.Workout>> _loadFromDb({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = ref.read(databaseProvider);

      // Build date-filtered query for completed workouts
      final buffer = StringBuffer(
        'SELECT id, name, start_time, end_time, notes, source, '
        'planned_workout_id, is_guided '
        'FROM workouts '
        'WHERE end_time IS NOT NULL',
      );
      final vars = <Object?>[];
      if (startDate != null) {
        buffer.write(' AND end_time >= ?');
        vars.add(startDate);
      }
      if (endDate != null) {
        buffer.write(' AND end_time <= ?');
        vars.add(endDate);
      }
      buffer.write(' ORDER BY end_time DESC');

      final workoutRows = await db
          .customSelect(
            buffer.toString(),
            variables: vars.map((v) => Variable(v)).toList(),
          )
          .get();

      final workouts = <domain.Workout>[];
      for (final row in workoutRows) {
        final workoutId = row.data['id'] as String;
        final endTimeRaw = row.data['end_time'];
        final endTime = endTimeRaw is String
            ? DateTime.tryParse(endTimeRaw)
            : endTimeRaw as DateTime?;
        final startTimeRaw = row.data['start_time'];
        final startTime = startTimeRaw is String
            ? DateTime.parse(startTimeRaw)
            : startTimeRaw as DateTime;

        workouts.add(
          domain.Workout(
            id: workoutId,
            name: row.data['name'] as String,
            startTime: startTime,
            endTime: endTime,
            entries: await _loadEntries(db, workoutId),
            notes: row.data['notes'] as String?,
            source: (row.data['source'] as String?) ?? 'manual',
            plannedWorkoutId: row.data['planned_workout_id'] as String?,
            isGuided: (row.data['is_guided'] as int?) == 1,
          ),
        );
      }

      return workouts;
    } catch (e, stack) {
      _log.severe('Failed to load workout history', e, stack);
      return [];
    }
  }

  Future<List<domain.WorkoutEntry>> _loadEntries(
    AppDatabase db,
    String workoutId,
  ) async {
    final entryRows = await db
        .customSelect(
          'SELECT we.id, we.sort_order, we.exercise_id, we.note, we.effort, '
          'e.name as ex_name, e.category as ex_category, '
          'e.type as ex_type, e.met as ex_met '
          'FROM workout_entries we '
          'JOIN exercises e ON e.id = we.exercise_id '
          'WHERE we.workout_id = ? '
          'ORDER BY we.sort_order',
          variables: [Variable(workoutId)],
        )
        .get();

    final entries = <domain.WorkoutEntry>[];
    for (final row in entryRows) {
      final entryId = row.data['id'] as String;
      final exerciseId = row.data['exercise_id'] as String;
      final exType = (row.data['ex_type'] as String?) ?? 'weightlifting';
      final isCardio = exType == 'cardio';

      // Load weight sets
      final sets = <domain.WeightSet>[];
      if (!isCardio) {
        final setRows = await db
            .customSelect(
              'SELECT reps, weight_kg, completed_at '
              'FROM workout_sets '
              'WHERE entry_id = ?',
              variables: [Variable(entryId)],
            )
            .get();
        for (final setRow in setRows) {
          sets.add(
            domain.WeightSet(
              reps: setRow.data['reps'] as int,
              weightKg: (setRow.data['weight_kg'] as num).toDouble(),
              completedAt: _parseDateTimeOrNull(setRow.data['completed_at']),
            ),
          );
        }
      }

      // Load cardio detail
      domain.CardioDetail? cardioDetail;
      if (isCardio) {
        final cardioRow = await db
            .customSelect(
              'SELECT duration_minutes FROM cardio_details WHERE entry_id = ?',
              variables: [Variable(entryId)],
            )
            .getSingleOrNull();
        if (cardioRow != null) {
          cardioDetail = domain.CardioDetail(
            durationMinutes: cardioRow.data['duration_minutes'] as int,
          );
        }
      }

      entries.add(
        domain.WorkoutEntry(
          id: entryId,
          exercise: ExerciseDefinition(
            id: exerciseId,
            name: (row.data['ex_name'] as String?) ?? '',
            category: (row.data['ex_category'] as String?) ?? 'General',
            type: exType,
            met: (row.data['ex_met'] as num?)?.toDouble() ?? 5.0,
          ),
          sets: sets,
          cardioDetail: cardioDetail,
          sortOrder: row.data['sort_order'] as int? ?? 0,
          note: row.data['note'] as String?,
          effort: row.data['effort'] as int?,
        ),
      );
    }

    return entries;
  }

  /// Parse a field that may be String (TEXT) or DateTime (native), returning
  /// null if the value is null or parsing fails.
  DateTime? _parseDateTimeOrNull(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Reload all history from DB (no date filter).
  Future<void> loadHistory() async {
    state = await _loadFromDb();
  }

  /// Load workouts within a date range.
  Future<void> loadHistoryInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = await _loadFromDb(startDate: startDate, endDate: endDate);
  }

  /// Get total volume (reps × weight) per exercise name within a date range.
  Future<Map<String, double>> getVolumeByExercise({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final workouts = await _loadFromDb(startDate: startDate, endDate: endDate);
    final volumeMap = <String, double>{};

    for (final workout in workouts) {
      for (final entry in workout.entries) {
        final vol = entry.sets.fold<double>(
          0.0,
          (sum, s) => sum + (s.reps * s.weightKg),
        );
        if (vol > 0) {
          volumeMap.update(
            entry.exercise.name,
            (v) => v + vol,
            ifAbsent: () => vol,
          );
        }
      }
    }

    return volumeMap;
  }

  /// Get total cardio minutes per week (ISO week string) within a date range.
  Future<Map<String, int>> getCardioMinutesByWeek({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final workouts = await _loadFromDb(startDate: startDate, endDate: endDate);
    final cardioMap = <String, int>{};

    for (final workout in workouts) {
      if (workout.endTime == null) continue;
      final weekKey = _isoWeekKey(workout.endTime!);
      final minutes = workout.entries.fold<int>(
        0,
        (sum, e) => sum + (e.cardioDetail?.durationMinutes ?? 0),
      );
      if (minutes > 0) {
        cardioMap.update(weekKey, (v) => v + minutes, ifAbsent: () => minutes);
      }
    }

    return cardioMap;
  }

  /// Format a DateTime as an ISO week key (e.g. "2026-W23").
  String _isoWeekKey(DateTime date) {
    // Approximate ISO week calculation
    final dayOfYear = int.parse(
      DateUtils.dateOnly(
        date,
      ).difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
