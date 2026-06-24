import '../../adapters/interfaces/workout_repository.dart';
import '../../models/workout.dart' as domain;

/// Pure Dart service for managing exercise sets within a workout.
///
/// Handles:
/// - Loading weight and cardio sets for a workout
/// - Deriving unique exercise IDs from set data
/// - Adding, toggling, and deleting sets
///
/// Delegates persistence to [WorkoutRepository]. No Flutter, no UI, no
/// state management dependencies — fully testable.
class SetManagementService {
  const SetManagementService(this._repo);

  final WorkoutRepository _repo;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Load all weight and cardio sets for [workoutId].
  Future<(List<domain.WeightSet>, List<domain.CardioSet>)> loadSets(
    String workoutId,
  ) async {
    final results = await Future.wait([
      _repo.getWeightSets(workoutId),
      _repo.getCardioSets(workoutId),
    ]);
    return (
      results[0] as List<domain.WeightSet>,
      results[1] as List<domain.CardioSet>,
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise derivation
  // ---------------------------------------------------------------------------

  /// Extract unique exercise IDs from the given sets.
  ///
  /// If [initialExerciseId] is provided and not already present in the
  /// derived set, it is appended so the add-form is visible for exercises
  /// that have no sets yet (e.g. just added from the Add Exercise sheet).
  List<String> deriveExerciseIds(
    List<domain.WeightSet> weightSets,
    List<domain.CardioSet> cardioSets, {
    String? initialExerciseId,
  }) {
    final ids = <String>{
      ...weightSets.map((s) => s.exerciseId),
      ...cardioSets.map((s) => s.exerciseId),
    }.toList();

    if (initialExerciseId != null && !ids.contains(initialExerciseId)) {
      ids.add(initialExerciseId);
    }

    return ids;
  }

  // ---------------------------------------------------------------------------
  // Mutations — scaffolding for T04; delegates to repo
  // ---------------------------------------------------------------------------

  /// Persist a new weight set.
  Future<void> addWeightSet(domain.WeightSet set) => _repo.addWeightSet(set);

  /// Persist a new cardio set.
  Future<void> addCardioSet(domain.CardioSet set) => _repo.addCardioSet(set);

  /// Toggle a weight set between completed and incomplete.
  ///
  /// When completing: sets actualReps/actualWeightKg = planned values and
  /// completedAt = now.
  /// When un-completing: clears completedAt.
  domain.WeightSet toggleWeightSetCompletion(domain.WeightSet set) {
    if (set.isCompleted) {
      return set.copyWith(completedAt: null, clearCompletedAt: true);
    }
    return set.copyWith(
      actualReps: set.plannedReps,
      actualWeightKg: set.plannedWeightKg,
      completedAt: DateTime.now(),
    );
  }

  /// Toggle a cardio set between completed and incomplete.
  ///
  /// When completing: sets actualDurationMinutes = planned value and
  /// completedAt = now.
  /// When un-completing: clears completedAt.
  domain.CardioSet toggleCardioSetCompletion(domain.CardioSet set) {
    if (set.isCompleted) {
      return set.copyWith(completedAt: null, clearCompletedAt: true);
    }
    return set.copyWith(
      actualDurationMinutes: set.plannedDurationMinutes,
      completedAt: DateTime.now(),
    );
  }

  /// Remove a set by ID from the database.
  Future<void> deleteSet(String setId) => _repo.removeSet(setId);
}
