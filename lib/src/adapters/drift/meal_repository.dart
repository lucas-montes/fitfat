import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../diet/repositories/meals.dart';
import '../../models/food.dart';

class DriftMealRepository implements MealRepository {
  DriftMealRepository(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<void> delete(String id) async {
    await _db.deleteMeal(id);
  }

  @override
  Future<List<MealEntry>> getByDate(DateTime date) async {
    final rows = await _db.getMealsByDate(date);
    return Future.wait(rows.map(_mapMealRowToDomain));
  }

  @override
  Stream<List<MealEntry>> watchMealsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _db.watchMeals().asyncMap((rows) async {
      final filtered = rows.where(
        (row) => row.eatenAt.isAfter(start) && row.eatenAt.isBefore(end),
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

  @override
  Future<void> insert(MealEntry meal) async {
    await upsert(meal);
  }

  @override
  Future<void> upsert(MealEntry meal) async {
    final companion = db.MealsCompanion.insert(
      id: meal.id,
      name: meal.name ?? '',
      eatenAt: meal.eatenAt,
      notes: Value.absent(),
    );

    await _db.into(_db.meals).insertOnConflictUpdate(companion);

    await _db.deleteMealIngredientsByMeal(meal.id);
    for (final item in meal.items) {
      final mealIngredient = db.MealIngredientsCompanion.insert(
        id: _uuid.v4(),
        mealId: meal.id,
        ingredientId: item.ingredient.id,
        grams: item.grams,
      );
      await _db.insertMealIngredient(mealIngredient);
    }
  }
}
