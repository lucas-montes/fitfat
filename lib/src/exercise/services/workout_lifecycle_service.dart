import '../../adapters/interfaces/workout_repository.dart';
import '../../models/workout.dart' as domain;

/// Pure Dart service for workout lifecycle operations.
///
/// Handles:
/// - `resume` — load the currently active workout
/// - `startFreeform` — create and persist a new free-form workout
/// - `startScheduled` — mark a scheduled workout as in-progress
/// - `complete` — mark a workout as completed in the database
/// - `cancel` — delete a workout entirely
///
/// Delegates persistence to [WorkoutRepository]. No Flutter, no Riverpod,
/// no UI dependencies — fully testable.
class WorkoutLifecycleService {
  const WorkoutLifecycleService(this._repo);

  final WorkoutRepository _repo;

  /// Load the currently active workout (startedAt NOT NULL, completedAt IS NULL).
  Future<domain.Workout?> resume() => _repo.getActive();

  /// Create and persist a new free-form workout (no scheduled date).
  ///
  /// Returns the created [Workout] with [startedAt] set to now.
  Future<domain.Workout> startFreeform({String? name}) async {
    final workout = domain.Workout(
      id: _generateId(),
      name: name ?? 'Workout',
      scheduledDate: null,
      startedAt: DateTime.now(),
      completedAt: null,
      source: domain.WorkoutSource.manual,
    );
    await _repo.save(workout);
    return workout;
  }

  /// Start a previously scheduled workout by marking it as in-progress.
  ///
  /// Sets `startedAt = now` in the database and returns the updated workout.
  Future<domain.Workout> startScheduled(String workoutId) async {
    await _repo.start(workoutId);
    final (workout, _, _) = await _repo.getById(workoutId);
    return workout;
  }

  /// Mark [workoutId] as completed in the database (sets `completedAt = now`).
  Future<void> complete(String workoutId) => _repo.complete(workoutId);

  /// Delete [workoutId] and all its sets from the database.
  Future<void> cancel(String workoutId) => _repo.delete(workoutId);

  /// Generate a unique, time-based ID for workouts and sets.
  /// Not cryptographically unique, but sufficient for local SQLite storage.
  String _generateId() {
    return 'w_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
