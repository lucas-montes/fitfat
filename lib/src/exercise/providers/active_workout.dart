import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adapters/drift/workout_repository.dart';
import '../../models/workout.dart';
import '../../services/workout_foreground_service.dart';
import 'workout_history.dart';

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, AsyncValue<Workout?>>(
      ActiveWorkoutNotifier.new,
    );

/// Manages the currently active workout.
/// State: `AsyncValue<Workout?>` — null means no active workout.
/// All mutations persist to DB immediately. No SharedPreferences.
class ActiveWorkoutNotifier extends Notifier<AsyncValue<Workout?>> {
  DriftWorkoutRepository? _repo;

  @override
  AsyncValue<Workout?> build() {
    _repo = ref.read(workoutRepositoryProvider);
    resume();
    return const AsyncValue.loading();
  }

  /// Resume the active workout from DB on startup.
  Future<void> resume() async {
    try {
      final active = await _repo!.getActive();
      state = AsyncValue.data(active);
      if (active != null) {
        unawaited(
          WorkoutForegroundService.instance.start(
            active.startedAt!,
            workoutName: active.name,
          ),
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Start a free-form workout immediately.
  Future<void> startFreeform({String? name}) async {
    final workout = Workout(
      id: _generateId(),
      name: name ?? 'Workout',
      scheduledDate: null,
      startedAt: DateTime.now(),
      completedAt: null,
      source: WorkoutSource.manual,
    );
    await _repo!.save(workout);
    state = AsyncValue.data(workout);
    unawaited(
      WorkoutForegroundService.instance.start(
        workout.startedAt!,
        workoutName: workout.name,
      ),
    );
  }

  /// Start a previously scheduled workout.
  Future<void> startScheduled(String workoutId) async {
    await _repo!.start(workoutId);
    final (workout, _, _) = await _repo!.getById(workoutId);
    state = AsyncValue.data(workout);
    unawaited(
      WorkoutForegroundService.instance.start(
        workout.startedAt!,
        workoutName: workout.name,
      ),
    );
  }

  /// Add a weight set to the active workout.
  Future<void> addWeightSet({
    required String workoutId,
    required String exerciseId,
    required int plannedReps,
    required double plannedWeightKg,
    int? plannedRestSeconds,
    int? actualReps,
    double? actualWeightKg,
    DateTime? completedAt,
    String? notes,
    int sortOrder = 0,
  }) async {
    final set = WeightSet(
      id: _generateId(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      plannedReps: plannedReps,
      plannedWeightKg: plannedWeightKg,
      plannedRestSeconds: plannedRestSeconds,
      actualReps: actualReps,
      actualWeightKg: actualWeightKg,
      completedAt: completedAt,
      notes: notes,
    );
    await _repo!.addWeightSet(set);
    await _refreshActive();
  }

  /// Update a weight set.
  Future<void> updateWeightSet(WeightSet set) async {
    await _repo!.updateWeightSet(set);
    await _refreshActive();
  }

  /// Add a cardio set to the active workout.
  Future<void> addCardioSet({
    required String workoutId,
    required String exerciseId,
    required int plannedDurationMinutes,
    int? actualDurationMinutes,
    DateTime? completedAt,
    String? notes,
    int sortOrder = 0,
  }) async {
    final set = CardioSet(
      id: _generateId(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      plannedDurationMinutes: plannedDurationMinutes,
      actualDurationMinutes: actualDurationMinutes,
      completedAt: completedAt,
      notes: notes,
    );
    await _repo!.addCardioSet(set);
    await _refreshActive();
  }

  /// Update a cardio set.
  Future<void> updateCardioSet(CardioSet set) async {
    await _repo!.updateCardioSet(set);
    await _refreshActive();
  }

  /// Remove a set by ID.
  Future<void> removeSet(String setId) async {
    await _repo!.removeSet(setId);
    await _refreshActive();
  }

  /// Complete the active workout (set completedAt = now).
  Future<void> complete() async {
    final current = state.asData?.value;
    if (current == null) return;

    await _repo!.complete(current.id);
    await _repo!.getActive(); // will return null now

    // Refresh history
    ref.read(workoutHistoryProvider.notifier).load();

    state = const AsyncValue.data(null);
    unawaited(WorkoutForegroundService.instance.stop());
  }

  /// Cancel (delete) the active workout.
  Future<void> cancel() async {
    final current = state.asData?.value;
    if (current == null) return;

    await _repo!.delete(current.id);
    state = const AsyncValue.data(null);
    unawaited(WorkoutForegroundService.instance.stop());
  }

  Future<void> _refreshActive() async {
    await resume();
  }

  String _generateId() {
    return 'w_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
