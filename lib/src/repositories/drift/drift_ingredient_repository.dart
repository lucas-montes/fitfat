import 'package:drift/drift.dart';
import '../../database/app_database.dart' hide Ingredient;
import '../../models/food_models.dart';
import '../interfaces/ingredient_repository.dart';

class DriftIngredientRepository implements IngredientRepository {
  DriftIngredientRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Ingredient>> getAll() async {
    final rows = await _db.getAllIngredients();
    return rows
        .map(
          (r) => Ingredient(
            id: r.id,
            name: r.name,
            caloriesPer100g: r.caloriesPer100g,
            proteinPer100g: r.proteinPer100g,
            carbsPer100g: r.carbsPer100g,
            fatPer100g: r.fatPer100g,
            components: [],
          ),
        )
        .toList();
  }

  @override
  Future<void> insert(Ingredient ingredient) async {
    await _db.insertIngredient(
      IngredientsCompanion.insert(
        id: ingredient.id,
        name: ingredient.name,
        caloriesPer100g: ingredient.caloriesPer100g,
        proteinPer100g: ingredient.proteinPer100g,
        carbsPer100g: ingredient.carbsPer100g,
        fatPer100g: ingredient.fatPer100g,
      ),
    );
  }

  @override
  Future<void> update(Ingredient ingredient) async {
    await _db.updateIngredient(
      IngredientsCompanion(
        id: Value(ingredient.id),
        name: Value(ingredient.name),
        caloriesPer100g: Value(ingredient.caloriesPer100g),
        proteinPer100g: Value(ingredient.proteinPer100g),
        carbsPer100g: Value(ingredient.carbsPer100g),
        fatPer100g: Value(ingredient.fatPer100g),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.deleteIngredient(id);
  }
}
