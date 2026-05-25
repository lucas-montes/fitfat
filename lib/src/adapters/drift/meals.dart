import 'dart:async';

import 'package:drift/drift.dart';
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
    // Query the DB directly for the month range to avoid loading all rows.
    final rows = await (
      _db.select(_db.meals)
        ..where((t) => t.eatenAt.isBetweenValues(start, end))
        ..orderBy([(t) => OrderingTerm(expression: t.eatenAt, mode: OrderingMode.desc)])
    ).get();
    try {
      print('[DB] getByDate for $start - $end: found ${rows.length} rows');
      for (final r in rows) {
        print('[DB]  - meal row id=${r.id} eatenAt=${r.eatenAt} name=${r.name}');
      }
    } catch (_) {}

    // Map rows to domain objects, but guard against failures converting
    // individual rows so a single bad row won't break the whole query.
    final mapped = await Future.wait(rows.map((r) async {
      try {
        return await _mapMealRowToDomain(r);
      } catch (e, st) {
        print('[DB] Failed to map meal ${r.id}: $e\n$st');
        return null;
      }
    }));
    return mapped.whereType<MealEntry>().toList();
  }

  Stream<List<MealEntry>> watchMealsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    // Use a DB-level watcher that only observes meals within the month range.
    return (_db.select(_db.meals)
          ..where((t) => t.eatenAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.eatenAt, mode: OrderingMode.desc)]))
        .watch()
        .asyncMap((rows) async {
      try {
        print('[DB] watchMealsForDay for $start - $end: rows=${rows.length}');
        for (final r in rows) {
          print('[DB]  - meal row id=${r.id} eatenAt=${r.eatenAt} name=${r.name}');
        }
      } catch (_) {}

      final mapped = await Future.wait(rows.map((r) async {
        try {
          return await _mapMealRowToDomain(r);
        } catch (e, st) {
          print('[DB] Failed to map meal ${r.id} in watcher: $e\n$st');
          return null;
        }
      }));
      return mapped.whereType<MealEntry>().toList();
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
      ).getSingleOrNull();

      if (ingredientRow == null) {
        // Missing ingredient referenced by meal_ingredients; log and skip.
        try {
          print('[DB] Missing ingredient ${mealIngredient.ingredientId} for meal ${mealRow.id} - skipping portion');
        } catch (_) {}
        return null;
      }

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
    final filteredPortions = portions.whereType<IngredientPortion>().toList();

    return MealEntry(
      id: mealRow.id,
      name: mealRow.name.isEmpty ? null : mealRow.name,
      eatenAt: mealRow.eatenAt,
      items: filteredPortions,
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

    // Debug: print meals count after insert to verify persistence during runtime
    try {
      final all = await _db.select(_db.meals).get();
      print('[DB] Inserted meal ${meal.id}. Meals in DB: ${all.length}');
    } catch (e, st) {
      print('[DB] Failed to query meals after insert: $e\n$st');
    }

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
