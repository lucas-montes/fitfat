import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/adapters/drift/meals.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/models/food.dart' as food;

void main() {
  group('DriftMealRepository', () {
    late AppDatabase database;
    late DriftMealRepository repository;
    const uuid = Uuid();

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftMealRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    Future<food.Ingredient> seedIngredient({
      required String name,
    }) async {
      final ingredientId = uuid.v4();
      await database.insertIngredient(
        IngredientsCompanion.insert(
          id: ingredientId,
          name: name,
          caloriesPer100g: 100,
          proteinPer100g: 10,
          carbsPer100g: 20,
          fatPer100g: 5,
        ),
      );

      return food.Ingredient(
        id: ingredientId,
        name: name,
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
      );
    }

    test('inserts a new meal and reads it back', () async {
      final ingredient = await seedIngredient(name: 'Rice');
      final meal = food.MealEntry(
        id: uuid.v7(),
        name: 'Lunch',
        eatenAt: DateTime(2026, 5, 24, 12),
        items: [
          food.IngredientPortion(ingredient: ingredient, grams: 150),
        ],
      );

      await repository.insert(meal);

      final meals = await repository.getByDate(meal.eatenAt);
      expect(meals, hasLength(1));

      final savedMeal = meals.single;
      expect(savedMeal.id, meal.id);
      expect(savedMeal.name, meal.name);
      expect(savedMeal.items, hasLength(1));
      expect(savedMeal.items.single.ingredient.id, ingredient.id);
      expect(savedMeal.items.single.grams, 150);
    });

    test('updates an existing meal and replaces its ingredients', () async {
      final ingredient = await seedIngredient(name: 'Chicken');
      final mealId = uuid.v7();
      final eatenAt = DateTime(2026, 5, 24, 18);

      await repository.insert(
        food.MealEntry(
          id: mealId,
          name: 'Dinner',
          eatenAt: eatenAt,
          items: [
            food.IngredientPortion(ingredient: ingredient, grams: 100),
          ],
        ),
      );

      await repository.update(
        food.MealEntry(
          id: mealId,
          name: 'Updated Dinner',
          eatenAt: eatenAt,
          items: [
            food.IngredientPortion(ingredient: ingredient, grams: 200),
          ],
        ),
      );

      final meals = await repository.getByDate(eatenAt);
      expect(meals, hasLength(1));

      final updatedMeal = meals.single;
      expect(updatedMeal.id, mealId);
      expect(updatedMeal.name, 'Updated Dinner');
      expect(updatedMeal.items, hasLength(1));
      expect(updatedMeal.items.single.grams, 200);

      final mealIngredients = await database
          .select(database.mealIngredients)
          .get();
      expect(mealIngredients, hasLength(1));
      expect(mealIngredients.single.mealId, mealId);
      expect(mealIngredients.single.grams, 200);
    });
  });
}
