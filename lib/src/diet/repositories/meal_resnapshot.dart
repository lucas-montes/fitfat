import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../../models/food.dart';
import '../services/food_nutrition.dart';

/// Rewrites the portion snapshot on logged meal rows when the food behind them
/// changes.
///
/// A `meal_foods` snapshot is a **cache of a derivation**, not an independent
/// record of what was eaten. It exists so reads stay flat — the dashboard's
/// daily total is one `SUM`, and the meal list never walks the ingredient
/// graph — but it is only correct while the composition behind it is unchanged.
/// Correct an ingredient and every meal that used a food containing it is
/// showing a number the user no longer believes, so those rows have to be
/// re-derived.
///
/// Deliberately a standalone class rather than a method on `MealRepository`:
/// `FoodRepository` and `IngredientRepository` both need to trigger it, and
/// reaching through either of them from `MealRepository` would make the import
/// graph cyclic. It talks to Drift directly and depends on neither.
final class MealResnapshot {
  final db.AppDatabase _database;
  const MealResnapshot(this._database);

  /// The foods whose logged portions are invalidated by a change to
  /// [ingredientId]: the ingredient's own derived food, plus every recipe that
  /// lists it.
  ///
  /// Both hops are indexed (`food_ingredients.ingredient_id`,
  /// `meal_foods.food_id`), so this stays cheap for an ingredient nothing
  /// depends on.
  Future<Set<String>> foodsAffectedByIngredient(String ingredientId) async {
    final rows = await (_database.select(
      _database.foodIngredients,
    )..where((t) => t.ingredientId.equals(ingredientId))).get();
    return {derivedFoodId(ingredientId), for (final row in rows) row.foodId};
  }

  /// Re-derives the snapshot on every meal row that logged one of [foodIds], and
  /// returns how many rows were rewritten.
  ///
  /// A food that cannot be resolved — a part whose ingredient row is gone, or an
  /// emptied composition — leaves its rows **untouched** rather than being
  /// zeroed. The last known figures still describe a portion that was genuinely
  /// eaten, whereas zero would invent a claim; and resolution is deliberately
  /// all-or-nothing, so there is no new value to write in that state anyway.
  /// Such rows still pick up correct numbers as soon as the food resolves again.
  Future<int> applyToFoods(Set<String> foodIds) async {
    if (foodIds.isEmpty) return 0;
    final ids = foodIds.toList();
    final nutrition = await _nutritionForFoods(ids);
    if (nutrition.isEmpty) return 0;

    final mealRows = await (_database.select(
      _database.mealFoods,
    )..where((t) => t.foodId.isIn(ids))).get();
    if (mealRows.isEmpty) return 0;

    var rewritten = 0;
    await _database.transaction(() async {
      for (final row in mealRows) {
        final per100g = nutrition[row.foodId]?.per100g;
        if (per100g == null) continue;
        final portion = scaleToAmount(per100g, row.amount);
        await (_database.update(
          _database.mealFoods,
        )..where((t) => t.id.equals(row.id))).write(
          db.MealFoodsCompanion(
            calories: Value(portion.calories),
            protein: Value(portion.protein),
            carbs: Value(portion.carbs),
            fat: Value(portion.fat),
            sodium: Value(portion.sodium),
            fiber: Value(portion.fiber),
            sugar: Value(portion.sugar),
          ),
        );
        rewritten++;
      }
    });
    return rewritten;
  }

  /// The live per-100g profile of each requested food, or `null` for one that
  /// does not resolve.
  ///
  /// Uses the same pure resolver the meal form and `FoodRepository` use, so a
  /// refreshed row cannot disagree with what a new log would record.
  Future<Map<String, FoodNutrition?>> _nutritionForFoods(
    List<String> foodIds,
  ) async {
    final componentRows = await (_database.select(
      _database.foodIngredients,
    )..where((t) => t.foodId.isIn(foodIds))).get();
    final counts = <String, int>{};
    for (final row in componentRows) {
      counts[row.foodId] = (counts[row.foodId] ?? 0) + 1;
    }
    if (componentRows.isEmpty) return {for (final id in foodIds) id: null};

    final ingredientIds = {for (final row in componentRows) row.ingredientId};
    final ingredientRows = await (_database.select(
      _database.ingredients,
    )..where((t) => t.id.isIn(ingredientIds))).get();
    final ingredients = {
      for (final row in ingredientRows)
        row.id: (
          caloriesPer100g: row.caloriesPer100g,
          proteinPer100g: row.proteinPer100g,
          carbsPer100g: row.carbsPer100g,
          fatPer100g: row.fatPer100g,
          sodiumPer100g: row.sodiumPer100g,
          fiberPer100g: row.fiberPer100g,
          sugarPer100g: row.sugarPer100g,
        ),
    };

    final byFood = <String, List<ComponentNutrition>>{};
    for (final row in componentRows) {
      final ingredient = ingredients[row.ingredientId];
      if (ingredient == null) continue;
      byFood.putIfAbsent(row.foodId, () => []).add((
        caloriesPer100g: ingredient.caloriesPer100g,
        proteinPer100g: ingredient.proteinPer100g,
        carbsPer100g: ingredient.carbsPer100g,
        fatPer100g: ingredient.fatPer100g,
        sodiumPer100g: ingredient.sodiumPer100g,
        fiberPer100g: ingredient.fiberPer100g,
        sugarPer100g: ingredient.sugarPer100g,
        amount: row.amount,
      ));
    }

    return {
      for (final id in foodIds)
        // All-or-nothing, matching FoodRepository: a food missing one part has
        // no meaningful per-100g, and summing the rest would both under-report
        // and drop that part from the weight denominator.
        id:
            (byFood[id]?.length ?? 0) == (counts[id] ?? 0) &&
                (counts[id] ?? 0) > 0
            ? resolveFoodPer100g(byFood[id]!)
            : null,
    };
  }
}
