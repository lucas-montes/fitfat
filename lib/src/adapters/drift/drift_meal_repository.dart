import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart' show Value;

import '../../models/food_models.dart';
import '../../repositories/interfaces/meal_repository.dart';
import '../../database/app_database.dart' as db;

class DriftMealRepository implements MealRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  DriftMealRepository(this._db);

  @override
  Future<void> delete(String id) async {
    await _db.deleteMeal(id);
  }

  @override
  Future<List<MealEntry>> getAll() async {
    final meals = await _db.select(_db.meals).get();
    return Future.wait(meals.map(_mapMealRowToDomain));
  }

  @override
  Future<List<MealEntry>> getByDate(DateTime date) async {
    final rows = await _db.getMealsByDate(date);
    return Future.wait(rows.map(_mapMealRowToDomain));
  }

  @override
  Stream<List<MealEntry>> watchAll() {
    return _db.watchMeals().asyncMap((rows) async {
      final results = await Future.wait(rows.map(_mapMealRowToDomain));
      return results;
    });
  }

  @override
  Stream<List<MealEntry>> watchMealsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _db.watchMeals().asyncMap((rows) async {
      final filtered = rows.where((r) => r.eatenAt.isAfter(start) && r.eatenAt.isBefore(end));
      final results = await Future.wait(filtered.map(_mapMealRowToDomain));
      return results;
    });
  }

  Future<MealEntry> _mapMealRowToDomain(db.Meal mealRow) async {
    final ingRows = await (_db.select(_db.mealIngredients)..where((t) => t.mealId.equals(mealRow.id))).get();
    final portions = await Future.wait(ingRows.map((mi) async {
      final ingRow = await (_db.select(_db.ingredients)..where((t) => t.id.equals(mi.ingredientId))).getSingle();
      final ingredient = Ingredient(
        id: ingRow.id,
        name: ingRow.name,
        caloriesPer100g: ingRow.caloriesPer100g,
        proteinPer100g: ingRow.proteinPer100g,
        carbsPer100g: ingRow.carbsPer100g,
        fatPer100g: ingRow.fatPer100g,
      );
      return IngredientPortion(ingredient: ingredient, grams: mi.grams);
    }));

    final name = mealRow.name.isEmpty ? null : mealRow.name;
    return MealEntry(id: mealRow.id, name: name, eatenAt: mealRow.eatenAt, items: portions);
  }

  @override
  Future<void> insert(MealEntry meal) async {
    // insert as new meal; use upsert for convenience
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

    // insert or replace meal row
    await _db.into(_db.meals).insertOnConflictUpdate(companion);

    // replace ingredients for the meal: delete existing then insert
    await _db.deleteMealIngredientsByMeal(meal.id);
    for (final item in meal.items) {
      final mi = db.MealIngredientsCompanion.insert(
        id: _uuid.v4(),
        mealId: meal.id,
        ingredientId: item.ingredient.id,
        grams: item.grams,
      );
      await _db.insertMealIngredient(mi);
    }
  }
}
