import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/food.dart';

class DriftMealRepository {
  DriftMealRepository(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  Future<void> delete(String id) async {
    await _db.deleteMeal(id);
  }

  Future<List<MealEntry>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    final rows = await _db.select(_db.meals).get();
    final filtered = rows.where(
      (row) => !row.eatenAt.isBefore(start) && !row.eatenAt.isAfter(end),
    );
    return Future.wait(filtered.map(_mapMealRowToDomain));
  }

  Stream<List<MealEntry>> watchMealsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);
    return _db.watchMeals().asyncMap((rows) async {
      final filtered = rows.where(
        (row) =>
            !row.eatenAt.isBefore(start) && row.eatenAt.isBefore(end),
      );
      return Future.wait(filtered.map(_mapMealRowToDomain));
    });
  }

  Future<MealEntry> _mapMealRowToDomain(db.Meal mealRow) async {
    final ingredientRows = await (
      _db.select(_db.mealIngredients)
        ..where((table) => table.mealId.equals(mealRow.id))
    ).get();

    final portions = await Future.wait(ingredientRows.map((mealIngredient) async {
      final ingredientRow = await (
        _db.select(_db.ingredients)
          ..where((table) => table.id.equals(mealIngredient.ingredientId))
      ).getSingle();

      final ingredient = Ingredient(
        id: ingredientRow.id,
        name: ingredientRow.name,
        caloriesPer100g: ingredientRow.caloriesPer100g,
        proteinPer100g: ingredientRow.proteinPer100g,
        carbsPer100g: ingredientRow.carbsPer100g,
        fatPer100g: ingredientRow.fatPer100g,
      );

      return IngredientPortion(ingredient: ingredient, grams: mealIngredient.grams);
    }));

    return MealEntry(
      id: mealRow.id,
      name: mealRow.name.isEmpty ? null : mealRow.name,
      eatenAt: mealRow.eatenAt,
      items: portions,
    );
  }

  Future<void> insert(MealEntry meal) async {
    final companion = db.MealsCompanion.insert(
      id: meal.id,
      name: meal.name ?? '',
      eatenAt: meal.eatenAt,
      notes: Value.absent(),
    );

    // Insert the meal row; fail if it already exists.
    await _db.insertMeal(companion);

    // Insert associated ingredients (no deletion on insert).
    for (final item in meal.items) {
      final mealIngredient = db.MealIngredientsCompanion.insert(
        id: _uuid.v7(),
        mealId: meal.id,
        ingredientId: item.ingredient.id,
        grams: item.grams,
      );
      await _db.insertMealIngredient(mealIngredient);
    }
  }



  Future<void> update(MealEntry meal) async {
    final companion = db.MealsCompanion.insert(
      id: meal.id,
      name: meal.name ?? '',
      eatenAt: meal.eatenAt,
      notes: Value.absent(),
    );

    // Replace the existing row (will fail silently if row doesn't exist).
    await _db.update(_db.meals).replace(companion);

    // Replace ingredients: delete existing then reinsert.
    await _db.deleteMealIngredientsByMeal(meal.id);
    for (final item in meal.items) {
      final mealIngredient = db.MealIngredientsCompanion.insert(
        id: _uuid.v7(),
        mealId: meal.id,
        ingredientId: item.ingredient.id,
        grams: item.grams,
      );
      await _db.insertMealIngredient(mealIngredient);
    }
  }
}
