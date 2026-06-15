import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart'
    hide Seance, ExerciseEntry, ExerciseSet, Exercise;
import '../../database/providers.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart' as domain;
import '../../services/logger.dart';
import '../../services/seance_foreground_service.dart';
import 'history_provider.dart';

final _log = logger('workout_provider');
const _activeWorkoutKey = 'active_workout_json';

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, domain.Workout?>(
      ActiveWorkoutNotifier.new,
    );

class ActiveWorkoutNotifier extends Notifier<domain.Workout?> {
  @override
  domain.Workout? build() {
    Future.microtask(restoreFromPrefs);
    return null;
  }

  Future<void> restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_activeWorkoutKey);
    if (json == null) return;
    try {
      state = domain.Workout.fromJson(
        Map<String, dynamic>.from(const JsonDecoder().convert(json) as Map),
      );
      if (state != null && state!.isActive) {
        unawaited(SeanceForegroundService.instance.start(state!.startTime));
      }
    } catch (e, stack) {
      _log.warning('Could not restore active workout', e, stack);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == null) {
      await prefs.remove(_activeWorkoutKey);
      return;
    }
    await prefs.setString(
      _activeWorkoutKey,
      const JsonEncoder().convert(state!.toJson()),
    );
  }

  /// Start a free-form workout (no plan, no template).
  void startWorkout({String? name}) {
    final now = DateTime.now();
    final defaultName =
        'Workout - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    state = domain.Workout(
      id: const Uuid().v4(),
      name: name ?? defaultName,
      startTime: now,
      source: 'manual',
    );
    unawaited(SeanceForegroundService.instance.start(state!.startTime));
    unawaited(_persist());
  }

  /// Start a workout from a planned workout, pre-filling prescribed weights.
  void startWorkoutFromPlanned(domain.PlannedWorkout plan) {
    final entries = plan.entries.map((plannedEntry) {
      final isCardio = plannedEntry.exercise.type == 'cardio';

      List<domain.WeightSet> weightSets;
      domain.CardioDetail? cardioDetail;

      if (isCardio) {
        weightSets = [];
        cardioDetail = domain.CardioDetail(
          durationMinutes:
              plannedEntry.plannedCardio?.plannedDurationMinutes ?? 0,
        );
      } else {
        weightSets = [
          for (var i = 0; i < 1; i++)
            domain.WeightSet(
              reps: plannedEntry.plannedReps,
              weightKg: plannedEntry.plannedWeightKg,
            ),
        ];
        cardioDetail = null;
      }

      return domain.WorkoutEntry(
        id: const Uuid().v4(),
        exercise: plannedEntry.exercise,
        sets: weightSets,
        cardioDetail: cardioDetail,
        sortOrder: plannedEntry.sortOrder,
        note: plannedEntry.note,
        effort: plannedEntry.effortTarget,
      );
    }).toList();

    final now = DateTime.now();
    state = domain.Workout(
      id: const Uuid().v4(),
      name: plan.name,
      startTime: now,
      entries: entries,
      source: plan.source,
      plannedWorkoutId: plan.id,
      isGuided: true,
    );
    unawaited(SeanceForegroundService.instance.start(state!.startTime));
    unawaited(_persist());
  }

  /// Quick-log a single-exercise workout that completes immediately.
  void quickLogWorkout({
    required String name,
    required ExerciseDefinition exercise,
    int? reps,
    double? weightKg,
    int? durationMinutes,
    int? effort,
  }) {
    final now = DateTime.now();
    final isCardio = exercise.type == 'cardio';

    List<domain.WeightSet> sets;
    domain.CardioDetail? cardioDetail;

    if (isCardio) {
      sets = [];
      cardioDetail = domain.CardioDetail(durationMinutes: durationMinutes ?? 0);
    } else {
      sets = reps != null && weightKg != null
          ? [domain.WeightSet(reps: reps, weightKg: weightKg, completedAt: now)]
          : [];
      cardioDetail = null;
    }

    final entry = domain.WorkoutEntry(
      id: const Uuid().v4(),
      exercise: exercise,
      sets: sets,
      cardioDetail: cardioDetail,
      sortOrder: 0,
      effort: effort,
    );

    final workout = domain.Workout(
      id: const Uuid().v4(),
      name: name,
      startTime: now,
      endTime: now,
      entries: [entry],
      source: 'quick_log',
    );

    _saveWorkout(workout);
    // state stays null — quick-logs don't leave an active session
  }

  /// Add a weightlifting exercise to the active workout.
  void addExercise(ExerciseDefinition exercise) {
    if (state == null) return;
    if (state!.entries.any(
      (entry) =>
          entry.exercise.name.toLowerCase() == exercise.name.toLowerCase(),
    )) {
      return;
    }
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: [
        ...state!.entries,
        domain.WorkoutEntry(
          id: const Uuid().v4(),
          exercise: exercise,
          sets: [],
          sortOrder: state!.entries.length,
        ),
      ],
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
    unawaited(
      SeanceForegroundService.instance.updateExerciseName(exercise.name),
    );
  }

  /// Add a cardio exercise with duration to the active workout.
  void addCardioEntry(ExerciseDefinition exercise, {int durationMinutes = 0}) {
    if (state == null) return;
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: [
        ...state!.entries,
        domain.WorkoutEntry(
          id: const Uuid().v4(),
          exercise: exercise,
          sets: [],
          cardioDetail: domain.CardioDetail(durationMinutes: durationMinutes),
          sortOrder: state!.entries.length,
        ),
      ],
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
  }

  /// Set the duration for a cardio-type entry.
  void setCardioDuration(int exerciseIndex, int durationMinutes) {
    if (state == null || exerciseIndex >= state!.entries.length) return;
    final entry = state!.entries[exerciseIndex];
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: [
        ...state!.entries.sublist(0, exerciseIndex),
        entry.copyWith(
          cardioDetail: domain.CardioDetail(durationMinutes: durationMinutes),
          clearCardioDetail: false,
        ),
        ...state!.entries.sublist(exerciseIndex + 1),
      ],
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
  }

  /// Remove an exercise from the active workout by index.
  void removeExercise(int index) {
    if (state == null || index >= state!.entries.length) return;
    final entries = <domain.WorkoutEntry>[...state!.entries]..removeAt(index);
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: entries,
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
  }

  /// Add a set to a weightlifting exercise.
  void addSet(int exerciseIndex, int reps, double weightKg) {
    if (state == null || exerciseIndex >= state!.entries.length) return;
    final entry = state!.entries[exerciseIndex];
    final now = DateTime.now();
    final updatedSets = [
      ...entry.sets,
      domain.WeightSet(reps: reps, weightKg: weightKg, completedAt: now),
    ];
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: [
        ...state!.entries.sublist(0, exerciseIndex),
        entry.copyWith(sets: updatedSets),
        ...state!.entries.sublist(exerciseIndex + 1),
      ],
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
    unawaited(SeanceForegroundService.instance.lastSetCompleted());
  }

  /// Toggle a set's completedAt (mark/unmark as completed).
  void toggleSetCompleted(int exerciseIndex, int setIndex) {
    if (state == null || exerciseIndex >= state!.entries.length) return;
    final entry = state!.entries[exerciseIndex];
    if (setIndex >= entry.sets.length) return;
    final set = entry.sets[setIndex];
    final updatedSets = [
      for (var i = 0; i < entry.sets.length; i++)
        if (i == setIndex)
          domain.WeightSet(
            reps: set.reps,
            weightKg: set.weightKg,
            completedAt: set.isCompleted ? null : DateTime.now(),
          )
        else
          entry.sets[i],
    ];
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: [
        ...state!.entries.sublist(0, exerciseIndex),
        entry.copyWith(sets: updatedSets),
        ...state!.entries.sublist(exerciseIndex + 1),
      ],
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
  }

  /// Update a set's reps and weight.
  void updateSet(int exerciseIndex, int setIndex, int reps, double weightKg) {
    if (state == null || exerciseIndex >= state!.entries.length) return;
    final entry = state!.entries[exerciseIndex];
    if (setIndex >= entry.sets.length) return;
    final currentSet = entry.sets[setIndex];
    final updatedSets = [
      for (var i = 0; i < entry.sets.length; i++)
        if (i == setIndex)
          domain.WeightSet(
            reps: reps,
            weightKg: weightKg,
            completedAt: currentSet.completedAt,
          )
        else
          entry.sets[i],
    ];
    state = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: [
        ...state!.entries.sublist(0, exerciseIndex),
        entry.copyWith(sets: updatedSets),
        ...state!.entries.sublist(exerciseIndex + 1),
      ],
      endTime: state!.endTime,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );
    unawaited(_persist());
  }

  /// Complete the active workout: saves to DB and clears state.
  Future<void> completeWorkout() async {
    if (state == null) return;
    if (state!.entries.isEmpty) {
      state = null;
      unawaited(SeanceForegroundService.instance.stop());
      unawaited(_persist());
      return;
    }
    final now = DateTime.now();
    final completed = domain.Workout(
      id: state!.id,
      name: state!.name,
      startTime: state!.startTime,
      entries: state!.entries,
      endTime: now,
      notes: state!.notes,
      source: state!.source,
      plannedWorkoutId: state!.plannedWorkoutId,
      isGuided: state!.isGuided,
    );

    await _insertWorkout(ref.read(databaseProvider), completed);
    await _saveToOldTables(completed);
    await ref.read(workoutHistoryProvider.notifier).loadHistory();
    state = null;
    unawaited(SeanceForegroundService.instance.stop());
    unawaited(_persist());
  }

  /// Save a copy of the completed workout to the old tables so exercise
  /// history screens (which read from `seances`/`exercise_entries`/`exercise_sets`)
  /// can find it.
  Future<void> _saveToOldTables(domain.Workout workout) async {
    final db = ref.read(databaseProvider);
    try {
      await db.transaction(() async {
        await db
            .into(db.seances)
            .insert(
              SeancesCompanion(
                id: Value(workout.id),
                name: Value(workout.name),
                startedAt: Value(workout.startTime),
                completedAt: Value(workout.endTime!),
                restBetweenSetsMillis: const Value(60000),
              ),
              mode: InsertMode.insertOrReplace,
            );

        for (var i = 0; i < workout.entries.length; i++) {
          final entry = workout.entries[i];
          final isCardio = entry.exercise.type == 'cardio';

          // Ensure exercise exists in the old exercises table
          await db
              .into(db.exercises)
              .insert(
                ExercisesCompanion.insert(
                  id: entry.exercise.id,
                  name: entry.exercise.name,
                  category: entry.exercise.category,
                ),
                mode: InsertMode.insertOrReplace,
              );

          await db
              .into(db.exerciseEntries)
              .insert(
                ExerciseEntriesCompanion(
                  id: Value(entry.id),
                  seanceId: Value(workout.id),
                  exerciseId: Value(entry.exercise.id),
                  startedAt: Value(workout.startTime),
                  completedAt: Value(workout.endTime!),
                ),
                mode: InsertMode.insertOrReplace,
              );

          if (!isCardio) {
            for (final set in entry.sets) {
              await db
                  .into(db.exerciseSets)
                  .insert(
                    ExerciseSetsCompanion.insert(
                      id: const Uuid().v4(),
                      entryId: entry.id,
                      reps: set.reps,
                      weight: set.weightKg,
                      completedAt: Value(set.completedAt),
                    ),
                  );
            }
          }
        }
      });
    } catch (e, stack) {
      _log.warning('Failed to save workout to old tables', e, stack);
    }
  }

  /// Cancel the active workout without saving.
  void cancelWorkout() {
    if (state == null) return;
    state = null;
    unawaited(SeanceForegroundService.instance.stop());
    unawaited(_persist());
  }

  /// Persist a completed workout to the new database tables via raw SQL.
  void _saveWorkout(domain.Workout workout) {
    final db = ref.read(databaseProvider);
    unawaited(_insertWorkout(db, workout));
  }

  Future<void> _insertWorkout(AppDatabase db, domain.Workout workout) async {
    // Insert the workout
    try {
      await db.customInsert(
        'INSERT OR IGNORE INTO workouts '
        '(id, name, start_time, end_time, notes, source, planned_workout_id, is_guided) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        variables: [
          Variable(workout.id),
          Variable(workout.name),
          Variable(workout.startTime),
          Variable(workout.endTime),
          Variable(workout.notes),
          Variable<String>(workout.source),
          Variable<String>(workout.plannedWorkoutId),
          Variable(workout.isGuided ? 1 : 0),
        ],
      );
    } catch (e, stack) {
      _log.warning('Failed to insert workout', e, stack);
      return;
    }

    // If this completed a planned workout, mark it as completed
    if (workout.plannedWorkoutId != null) {
      try {
        await db.customUpdate(
          'UPDATE planned_workouts SET '
          'is_completed = 1, completed_workout_id = ? '
          'WHERE id = ?',
          variables: [Variable(workout.id), Variable(workout.plannedWorkoutId)],
        );
      } catch (e, stack) {
        _log.warning('Failed to update planned workout', e, stack);
      }
    }

    for (final entry in workout.entries) {
      try {
        await db.customInsert(
          'INSERT OR IGNORE INTO workout_entries '
          '(id, sort_order, exercise_id, workout_id, note, effort) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          variables: [
            Variable(entry.id),
            Variable(entry.sortOrder),
            Variable(entry.exercise.id),
            Variable(workout.id),
            Variable(entry.note),
            Variable(entry.effort),
          ],
        );
      } catch (e, stack) {
        _log.warning('Failed to insert workout entry', e, stack);
        continue;
      }

      for (final set in entry.sets) {
        try {
          await db.customInsert(
            'INSERT OR IGNORE INTO workout_sets '
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
        } catch (e, stack) {
          _log.warning('Failed to insert workout set', e, stack);
        }
      }

      final cardio = entry.cardioDetail;
      if (cardio != null) {
        try {
          await db.customInsert(
            'INSERT OR IGNORE INTO cardio_details '
            '(id, entry_id, duration_minutes) '
            'VALUES (?, ?, ?)',
            variables: [
              Variable<String>(const Uuid().v4()),
              Variable<String>(entry.id),
              Variable<int>(cardio.durationMinutes),
            ],
          );
        } catch (e, stack) {
          _log.warning('Failed to insert cardio detail', e, stack);
        }
      }
    }
  }
}
