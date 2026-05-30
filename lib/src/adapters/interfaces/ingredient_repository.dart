import '../../models/food.dart' as food;

/// Abstract interface for ingredient data access.
/// Implementations: [DriftIngredientRepository], future REST/API adapters.
abstract class IngredientRepository {
  /// Returns all non-archived ingredients.
  Future<List<food.Ingredient>> getAll();

  /// Returns a single ingredient by ID, or null if not found.
  Future<food.Ingredient?> getById(String id);

  /// Inserts a new ingredient.
  Future<void> insert(food.Ingredient ingredient);

  /// Updates an existing ingredient.
  Future<void> update(food.Ingredient ingredient);

  /// Soft-deletes an ingredient by marking it archived.
  Future<void> archive(String id);

  /// Restores an archived ingredient.
  Future<void> unarchive(String id);

  /// Permanently deletes an ingredient and cleans up component junction records.
  Future<void> delete(String id);

  /// Returns all archived ingredients.
  Future<List<food.Ingredient>> getArchived();
}
