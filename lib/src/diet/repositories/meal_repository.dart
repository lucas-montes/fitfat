import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/meal_entry.dart';
import '../../models/meal_ingredient.dart';

final class MealRepository {
  final db.AppDatabase _database;
  const MealRepository(this._database);

  /// Load all meals with their ingredient items, ordered by eatenAt desc.
  Future<List<MealEntry>> getAll() async {
    final meals =
        await (_database.select(_database.meals)..orderBy([
              (t) =>
                  OrderingTerm(expression: t.eatenAt, mode: OrderingMode.desc),
            ]))
            .get();

    final result = <MealEntry>[];
    for (final meal in meals) {
      final items = await _getItemsForMeal(meal.id);
      result.add(_toDomain(meal, items));
    }
    return result;
  }

  Future<List<MealIngredient>> _getItemsForMeal(String mealId) async {
    final mis = await (_database.select(
      _database.mealIngredients,
    )..where((t) => t.mealId.equals(mealId))).get();

    if (mis.isEmpty) return [];

    // Load referenced ingredients in batch
    final ingredientIds = mis.map((mi) => mi.ingredientId).toList();
    final ingredients = await (_database.select(
      _database.ingredients,
    )..where((t) => t.id.isIn(ingredientIds))).get();
    final ingredientMap = {for (final ing in ingredients) ing.id: ing};

    return mis.map((mi) {
      final ing = ingredientMap[mi.ingredientId]!;
      return MealIngredient(
        id: mi.id,
        mealId: mi.mealId,
        ingredientId: mi.ingredientId,
        ingredientName: ing.name,
        grams: mi.grams,
        caloriesPer100g: ing.caloriesPer100g,
        proteinPer100g: ing.proteinPer100g,
        carbsPer100g: ing.carbsPer100g,
        fatPer100g: ing.fatPer100g,
      );
    }).toList();
  }

  Future<void> insert(MealEntry meal) async {
    await _database.transaction(() async {
      await _database
          .into(_database.meals)
          .insert(
            db.MealsCompanion.insert(
              id: meal.id,
              name: meal.name,
              eatenAt: meal.eatenAt.millisecondsSinceEpoch,
              createdAt: meal.createdAt.millisecondsSinceEpoch,
            ),
          );
      for (final item in meal.items) {
        await _database
            .into(_database.mealIngredients)
            .insert(
              db.MealIngredientsCompanion.insert(
                id: item.id,
                mealId: item.mealId,
                ingredientId: item.ingredientId,
                grams: item.grams,
              ),
            );
      }
    });
  }

  Future<void> update(MealEntry meal) async {
    await _database.transaction(() async {
      await (_database.update(
        _database.meals,
      )..where((t) => t.id.equals(meal.id))).write(
        db.MealsCompanion(
          name: Value(meal.name),
          eatenAt: Value(meal.eatenAt.millisecondsSinceEpoch),
        ),
      );
      // Replace all meal_ingredients
      await (_database.delete(
        _database.mealIngredients,
      )..where((t) => t.mealId.equals(meal.id))).go();
      for (final item in meal.items) {
        await _database
            .into(_database.mealIngredients)
            .insert(
              db.MealIngredientsCompanion.insert(
                id: item.id,
                mealId: item.mealId,
                ingredientId: item.ingredientId,
                grams: item.grams,
              ),
            );
      }
    });
  }

  Future<void> delete(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.mealIngredients,
      )..where((t) => t.mealId.equals(id))).go();
      await (_database.delete(
        _database.meals,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  MealEntry _toDomain(db.Meal row, List<MealIngredient> items) => MealEntry(
    id: row.id,
    name: row.name,
    eatenAt: DateTime.fromMillisecondsSinceEpoch(row.eatenAt),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    items: items,
  );
}

/// Creates a new [MealEntry] with a fresh UUID v7 and the current timestamp.
MealEntry newMeal({
  required String name,
  required DateTime eatenAt,
  required List<MealIngredient> items,
}) => MealEntry(
  id: const Uuid().v7(),
  name: name,
  eatenAt: eatenAt,
  createdAt: DateTime.now(),
  items: items,
);
