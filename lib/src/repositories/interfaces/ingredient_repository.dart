import '../../models/food_models.dart';

abstract class IngredientRepository {
  Future<List<Ingredient>> getAll();
  Future<void> insert(Ingredient ingredient);
  Future<void> update(Ingredient ingredient);
  Future<void> delete(String id);
}
