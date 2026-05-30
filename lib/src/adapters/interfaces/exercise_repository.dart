import '../../models/exercise.dart' as model;

/// Abstract interface for exercise data access.
/// Implementations: [DriftExerciseRepository], future REST/API adapters.
abstract class ExerciseRepository {
  /// Returns all exercises in the library.
  Future<List<model.ExerciseDefinition>> getAll();

  /// Returns a single exercise by ID.
  Future<model.ExerciseDefinition?> getById(String id);

  /// Inserts a new exercise definition.
  Future<void> insert(model.ExerciseDefinition exercise);

  /// Batch inserts/updates exercises (for initial seeding).
  Future<void> upsertAll(List<model.ExerciseDefinition> exercises);

  /// Deletes an exercise by ID.
  Future<void> delete(String id);
}
