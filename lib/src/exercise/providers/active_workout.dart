import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adapters/drift/workout_repository.dart';
import '../../adapters/interfaces/workout_repository.dart';
import '../../models/workout.dart';
import '../services/providers.dart';
import '../services/workout_lifecycle_service.dart';
import '../../services/workout_foreground_service.dart';
import 'workout_history.dart';

/// Riverpod provider for the currently active workout.
///
/// State: `AsyncValue<Workout?>` — null means no active workout exists.
/// The `NotifierProvider` pattern is used so that screens can both read
/// (`ref.watch`) and mutate (`ref.read(...notifier)`) the active workout.
///
/// All mutations persist to SQLite immediately via the `WorkoutRepository`.
/// No SharedPreferences or in-memory caching — DB is the single source of truth.
final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, AsyncValue<Workout?>>(
      ActiveWorkoutNotifier.new,
    );

/// Manages the currently active workout's lifecycle.
///
/// Responsibility boundaries:
/// - Lifecycle DB operations → delegates to `WorkoutLifecycleService`
/// - Set mutation DB operations → delegates to `WorkoutRepository`
/// - UI state → exposes `AsyncValue<Workout?>` for Riverpod watchers
/// - Foreground notification → `WorkoutForegroundService`
///
/// Key design decisions:
/// - **complete() does NOT change state**: The caller (ActiveWorkoutScreen)
///   navigates to the summary screen directly after `complete()` returns.
///   This avoids a widget rebuild race where `state = null` would trigger a
///   competing dashboard redirect. See ActiveWorkoutScreen._complete().
/// - **cancel() DOES set state to null**: The workout is deleted, so there
///   is nothing to show — the watcher redirects to the dashboard naturally.
class ActiveWorkoutNotifier extends Notifier<AsyncValue<Workout?>> {
  /// Lazily-initialized repository reference.
  /// Set once in `build()`, safe to use with `!` after that.
  WorkoutRepository? _repo;

  /// Lazily-initialized lifecycle service.
  /// Set once in `build()`, safe to use with `!` after that.
  WorkoutLifecycleService? _lifecycleService;

  @override
  AsyncValue<Workout?> build() {
    // Riverpod calls build() once when the provider is first created.
    // We grab the repository and lifecycle service references and fire a
    // resume() to hydrate state.
    _repo = ref.read(workoutRepositoryProvider);
    _lifecycleService = ref.read(workoutLifecycleServiceProvider);
    resume();
    return const AsyncValue.loading();
  }

  /// Hydrate state from the database on provider creation or refresh.
  ///
  /// Queries for a workout WHERE startedAt IS NOT NULL AND completedAt IS NULL.
  /// If found, also starts the foreground notification service so the timer
  /// keeps running even if the app is backgrounded.
  Future<void> resume() async {
    try {
      final active = await _lifecycleService!.resume();
      state = AsyncValue.data(active);
      if (active != null) {
        // Start a persistent notification showing elapsed workout time.
        // The notification is updated every second by WorkoutTaskHandler.
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

  /// Start a free-form workout immediately with no scheduled date.
  ///
  /// Free-form workouts have `scheduledDate = null` and are started
  /// the moment the user taps "Start" — no pre-planning needed.
  Future<void> startFreeform({String? name}) async {
    final workout = await _lifecycleService!.startFreeform(name: name);
    state = AsyncValue.data(workout);
    unawaited(
      WorkoutForegroundService.instance.start(
        workout.startedAt!,
        workoutName: workout.name,
      ),
    );
  }

  /// Start a previously scheduled workout by marking it as in-progress.
  ///
  /// Scheduled workouts exist in the DB with `startedAt = null`.
  /// This sets `startedAt = now` so the workout becomes "active".
  Future<void> startScheduled(String workoutId) async {
    final workout = await _lifecycleService!.startScheduled(workoutId);
    state = AsyncValue.data(workout);
    unawaited(
      WorkoutForegroundService.instance.start(
        workout.startedAt!,
        workoutName: workout.name,
      ),
    );
  }

  /// Add a weight set to the active workout.
  ///
  /// For free-form workouts, the caller passes `completedAt = DateTime.now()`
  /// and `actualReps` / `actualWeightKg` matching the planned values, so the
  /// set is auto-completed. For scheduled workouts, only planned values are set
  /// and the user completes each set manually later.
  ///
  /// When a set is created as completed, the foreground service is notified
  /// so the notification can show "Rest: mm:ss" since the last set.
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
    // Tell the foreground service when a set was completed so the
    // notification can display elapsed rest time since last set.
    if (completedAt != null) {
      unawaited(WorkoutForegroundService.instance.lastSetCompleted());
    }
    await _refreshActive();
  }

  /// Update an existing weight set (e.g. toggle completion, edit values).
  ///
  /// If the update sets `completedAt`, the foreground service is notified
  /// for rest timer display in the notification.
  Future<void> updateWeightSet(WeightSet set) async {
    await _repo!.updateWeightSet(set);
    if (set.completedAt != null) {
      unawaited(WorkoutForegroundService.instance.lastSetCompleted());
    }
    await _refreshActive();
  }

  /// Add a cardio set to the active workout.
  /// See [addWeightSet] for details — same logic applied to duration-based sets.
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
    if (completedAt != null) {
      unawaited(WorkoutForegroundService.instance.lastSetCompleted());
    }
    await _refreshActive();
  }

  /// Update an existing cardio set.
  /// See [updateWeightSet] for details.
  Future<void> updateCardioSet(CardioSet set) async {
    await _repo!.updateCardioSet(set);
    if (set.completedAt != null) {
      unawaited(WorkoutForegroundService.instance.lastSetCompleted());
    }
    await _refreshActive();
  }

  /// Remove a set by ID from the active workout.
  Future<void> removeSet(String setId) async {
    await _repo!.removeSet(setId);
    await _refreshActive();
  }

  /// Mark the active workout as completed in the database.
  ///
  /// IMPORTANT DESIGN NOTE: This method updates `completedAt` on the in-memory
  /// workout so watchers (e.g. floating pill, training tab card) see it as no
  /// longer active. It does NOT set `state = null` — that would trigger a
  /// competing dashboard redirect in ActiveWorkoutScreen._complete().
  ///
  /// The caller (ActiveWorkoutScreen._complete) navigates directly to the
  /// summary screen after this returns. Setting `completedAt` keeps the state
  /// non-null so ActiveWorkoutScreen doesn't redirect to dashboard.
  ///
  /// The cancel flow (which sets state = null) is different — there's no
  /// summary to show, so the dashboard redirect is the correct behavior.
  Future<void> complete() async {
    final current = state.asData?.value;
    if (current == null) return;

    await _lifecycleService!.complete(current.id);

    // Update in-memory state so watchers see the workout as no longer active.
    // We must NOT set state = null here — that would trigger a competing
    // dashboard redirect in ActiveWorkoutScreen._complete(). By setting
    // completedAt on the existing workout, isActive becomes false but the
    // state value remains non-null, so ActiveWorkoutScreen doesn't redirect.
    state = AsyncValue.data(current.copyWith(completedAt: DateTime.now()));

    // Refresh history so the completed workout appears in the list immediately.
    ref.read(workoutHistoryProvider.notifier).load();

    // Stop the persistent notification — the workout is done.
    unawaited(WorkoutForegroundService.instance.stop());
  }

  /// Cancel (delete) the active workout entirely.
  ///
  /// Sets state to null so the watcher redirects to the dashboard.
  /// Unlike complete(), cancel has no summary screen — the workout is gone.
  Future<void> cancel() async {
    final current = state.asData?.value;
    if (current == null) return;

    await _lifecycleService!.cancel(current.id);
    state = const AsyncValue.data(null);
    unawaited(WorkoutForegroundService.instance.stop());
  }

  /// Reload active workout state from the database.
  ///
  /// Called internally after any set mutation so Riverpod watchers
  /// receive fresh data (e.g. updated set list for the active screen).
  Future<void> _refreshActive() async {
    await resume();
  }

  /// Generate a unique, time-based ID for workouts and sets.
  /// Not cryptographically unique, but sufficient for local SQLite storage.
  String _generateId() {
    return 'w_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
