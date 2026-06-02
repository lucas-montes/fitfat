import 'package:drift/drift.dart';

import '../../database/app_database.dart' hide Ingredient;
import '../../models/food.dart';

class DriftIngredientRepository {
  DriftIngredientRepository(this._db);

  final AppDatabase _db;

  Future<List<Ingredient>> getAll() async {
    final rows = await _db.getAllIngredients();
    if (rows.isEmpty) return [];

    // Build ingredients with components
    final ingredientMap = <String, Ingredient>{};

    // First pass: create all ingredients from the main table
    for (final row in rows) {
      final ingredient = Ingredient(
        id: row.id,
        name: row.name,
        caloriesPer100g: row.caloriesPer100g,
        proteinPer100g: row.proteinPer100g,
        carbsPer100g: row.carbsPer100g,
        fatPer100g: row.fatPer100g,
        creatorId: row.creatorId,
        isArchived: row.isArchived,
        sodiumPer100g: row.sodiumPer100g,
        fiberPer100g: row.fiberPer100g,
        sugarsPer100g: row.sugarsPer100g,
        saturatedFatPer100g: row.saturatedFatPer100g,
        cholesterolPer100g: row.cholesterolPer100g,
        components: [],
      );
      ingredientMap[row.id] = ingredient;
    }

    // Second pass: resolve components for composite ingredients
    for (final ingredient in ingredientMap.values) {
      if (ingredient.components.isNotEmpty) {
        final components = await _db.getComponentsForIngredient(ingredient.id);
        if (components.isNotEmpty) {
          for (final c in components) {
            final componentIngredient = Ingredient(
              id: c.ingredientId,
              name: c.ingredientId,
              caloriesPer100g: 0.0,
              proteinPer100g: 0.0,
              carbsPer100g: 0.0,
              fatPer100g: 0.0,
              creatorId: null,
              isArchived: false,
              sodiumPer100g: null,
              fiberPer100g: null,
              sugarsPer100g: null,
              saturatedFatPer100g: null,
              cholesterolPer100g: null,
            );
            ingredient.components.add(
              IngredientPortion(
                ingredient: componentIngredient,
                grams: c.grams,
              ),
            );
          }
        }
      }
    }

    return ingredientMap.values.toList();
  }

  Future<Ingredient?> getById(String id) async {
    final ingredientResult = await _db.getIngredientByIds([id]);
    if (ingredientResult.isEmpty) return null;
    final ingredient = ingredientResult.first;

    // Get components if this is a composite ingredient
    final components = await _db.getComponentsForIngredient(id);
    if (components.isEmpty) {
      return Ingredient(
        id: ingredient.id,
        name: ingredient.name,
        caloriesPer100g: ingredient.caloriesPer100g,
        proteinPer100g: ingredient.proteinPer100g,
        carbsPer100g: ingredient.carbsPer100g,
        fatPer100g: ingredient.fatPer100g,
        creatorId: ingredient.creatorId,
        isArchived: ingredient.isArchived,
        sodiumPer100g: ingredient.sodiumPer100g,
        fiberPer100g: ingredient.fiberPer100g,
        sugarsPer100g: ingredient.sugarsPer100g,
        saturatedFatPer100g: ingredient.saturatedFatPer100g,
        cholesterolPer100g: ingredient.cholesterolPer100g,
      );
    }

    // Use for-comprehension to build the list with components
    final withComponents = [
      Ingredient(
        id: ingredient.id,
        name: ingredient.name,
        caloriesPer100g: ingredient.caloriesPer100g,
        proteinPer100g: ingredient.proteinPer100g,
        carbsPer100g: ingredient.carbsPer100g,
        fatPer100g: ingredient.fatPer100g,
        creatorId: ingredient.creatorId,
        isArchived: ingredient.isArchived,
        sodiumPer100g: ingredient.sodiumPer100g,
        fiberPer100g: ingredient.fiberPer100g,
        sugarsPer100g: ingredient.sugarsPer100g,
        saturatedFatPer100g: ingredient.saturatedFatPer100g,
        cholesterolPer100g: ingredient.cholesterolPer100g,
        components: [
          for (final c in components)
            IngredientPortion(
              ingredient: Ingredient(
                id: c.ingredientId,
                name: c.ingredientId,
                caloriesPer100g: 0.0,
                proteinPer100g: 0.0,
                carbsPer100g: 0.0,
                fatPer100g: 0.0,
                creatorId: null,
                isArchived: false,
                sodiumPer100g: null,
                fiberPer100g: null,
                sugarsPer100g: null,
                saturatedFatPer100g: null,
                cholesterolPer100g: null,
              ),
              grams: c.grams,
            ),
        ],
      ),
    ];

    return withComponents.first;
  }

  Future<void> insert(Ingredient ingredient) async {
    await _db.insertIngredient(
      IngredientsCompanion.insert(
        id: ingredient.id,
        name: ingredient.name,
        caloriesPer100g: ingredient.caloriesPer100g,
        proteinPer100g: ingredient.proteinPer100g,
        carbsPer100g: ingredient.carbsPer100g,
        fatPer100g: ingredient.fatPer100g,
        creatorId: Value(ingredient.creatorId),
        isArchived: Value(ingredient.isArchived),
        sodiumPer100g: Value(ingredient.sodiumPer100g),
        fiberPer100g: Value(ingredient.fiberPer100g),
        sugarsPer100g: Value(ingredient.sugarsPer100g),
        saturatedFatPer100g: Value(ingredient.saturatedFatPer100g),
        cholesterolPer100g: Value(ingredient.cholesterolPer100g),
      ),
    );
  }

  Future<void> update(Ingredient ingredient) async {
    await _db.updateIngredient(
      IngredientsCompanion(
        id: Value(ingredient.id),
        name: Value(ingredient.name),
        caloriesPer100g: Value(ingredient.caloriesPer100g),
        proteinPer100g: Value(ingredient.proteinPer100g),
        carbsPer100g: Value(ingredient.carbsPer100g),
        fatPer100g: Value(ingredient.fatPer100g),
        creatorId: Value(ingredient.creatorId),
        isArchived: Value(ingredient.isArchived),
        sodiumPer100g: Value(ingredient.sodiumPer100g),
        fiberPer100g: Value(ingredient.fiberPer100g),
        sugarsPer100g: Value(ingredient.sugarsPer100g),
        saturatedFatPer100g: Value(ingredient.saturatedFatPer100g),
        cholesterolPer100g: Value(ingredient.cholesterolPer100g),
      ),
    );
  }

  Future<void> archiveIngredient(String id) async {
    await _db.archiveIngredient(id);
  }

  Future<void> deleteIngredient(String id) async {
    await _db.deleteIngredient(id);
  }

  Future<List<Ingredient>> getArchivedIngredients() async {
    final rows = await _db.getAllIngredients();
    if (rows.isEmpty) return [];

    // Build ingredients with components
    final ingredientMap = <String, Ingredient>{};

    // First pass: create all ingredients from the main table
    for (final row in rows) {
      final ingredient = Ingredient(
        id: row.id,
        name: row.name,
        caloriesPer100g: row.caloriesPer100g,
        proteinPer100g: row.proteinPer100g,
        carbsPer100g: row.carbsPer100g,
        fatPer100g: row.fatPer100g,
        creatorId: row.creatorId,
        isArchived: row.isArchived,
        sodiumPer100g: row.sodiumPer100g,
        fiberPer100g: row.fiberPer100g,
        sugarsPer100g: row.sugarsPer100g,
        saturatedFatPer100g: row.saturatedFatPer100g,
        cholesterolPer100g: row.cholesterolPer100g,
        components: [],
      );
      ingredientMap[row.id] = ingredient;
    }

    // Second pass: resolve components for composite ingredients
    for (final ingredient in ingredientMap.values) {
      if (ingredient.components.isNotEmpty) {
        final components = await _db.getComponentsForIngredient(ingredient.id);
        if (components.isNotEmpty) {
          for (final c in components) {
            final componentIngredient = Ingredient(
              id: c.ingredientId,
              name: c.ingredientId,
              caloriesPer100g: 0.0,
              proteinPer100g: 0.0,
              carbsPer100g: 0.0,
              fatPer100g: 0.0,
              creatorId: null,
              isArchived: false,
              sodiumPer100g: null,
              fiberPer100g: null,
              sugarsPer100g: null,
              saturatedFatPer100g: null,
              cholesterolPer100g: null,
            );
            ingredient.components.add(
              IngredientPortion(
                ingredient: componentIngredient,
                grams: c.grams,
              ),
            );
          }
        }
      }
    }

    return ingredientMap.values.toList();
  }
}
