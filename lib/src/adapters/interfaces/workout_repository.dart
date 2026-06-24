import '../../models/workout.dart' as model;

/// Abstract interface for workout data access.
/// Implementations: [DriftWorkoutRepository], future REST/API adapters.
abstract class WorkoutRepository {
  // ---------------------------------------------------------------------------
  // Workout CRUD
  // ---------------------------------------------------------------------------

  /// Insert or update a workout and its sets.
  Future<void> save(
    model.Workout workout, {
    List<model.WeightSet>? weightSets,
    List<model.CardioSet>? cardioSets,
  });

  /// Load a workout with all its sets by ID.
  Future<(model.Workout, List<model.WeightSet>, List<model.CardioSet>)> getById(
    String id,
  );

  /// List workouts with scheduledDate >= today and startedAt IS NULL.
  Future<List<model.Workout>> listUpcoming();

  /// List workouts whose scheduledDate matches the given date.
  Future<List<model.Workout>> listByDate(DateTime date);

  /// List completed workouts, optionally filtered by date range.
  Future<List<model.Workout>> listCompleted({DateTime? from, DateTime? to});

  /// Get the currently active workout (startedAt NOT NULL, completedAt IS NULL).
  Future<model.Workout?> getActive();

  /// Set startedAt = now.
  Future<void> start(String id);

  /// Set completedAt = now.
  Future<void> complete(String id);

  /// Delete a workout and cascade delete all its sets.
  Future<void> delete(String id);

  // ---------------------------------------------------------------------------
  // Weight set operations
  // ---------------------------------------------------------------------------

  /// Add a new weight set.
  Future<void> addWeightSet(model.WeightSet set);

  /// Update an existing weight set.
  Future<void> updateWeightSet(model.WeightSet set);

  // ---------------------------------------------------------------------------
  // Cardio set operations
  // ---------------------------------------------------------------------------

  /// Add a new cardio set.
  Future<void> addCardioSet(model.CardioSet set);

  /// Update an existing cardio set.
  Future<void> updateCardioSet(model.CardioSet set);

  /// Remove a set by ID (works for both weight_sets and cardio_sets).
  Future<void> removeSet(String setId);

  /// Get all weight sets for a workout, ordered by sort_order.
  Future<List<model.WeightSet>> getWeightSets(String workoutId);

  /// Get all cardio sets for a workout, ordered by sort_order.
  Future<List<model.CardioSet>> getCardioSets(String workoutId);

  /// Get weight sets for multiple workouts, keyed by workoutId.
  Future<Map<String, List<model.WeightSet>>> getWeightSetsByWorkoutIds(
    List<String> workoutIds,
  );

  /// Get completed weight sets for a specific exercise across all workouts.
  Future<List<model.WeightSet>> getCompletedWeightSetsByExercise(
    String exerciseId,
  );
}
