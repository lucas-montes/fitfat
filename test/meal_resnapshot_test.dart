import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/repositories/meal_repository.dart';
import 'package:fitfat/src/diet/repositories/meal_resnapshot.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:fitfat/src/models/ingredient.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/models/meal_food.dart';
import 'package:flutter_test/flutter_test.dart';

/// The portion snapshot on `meal_foods` is a **cache of a derivation**, so it has
/// to be re-derived when the composition behind it changes. Otherwise correcting
/// a typo in an ingredient leaves every past meal showing the old figure.
///
/// These cover the triggers and the degradation: a food that stops resolving
/// must keep its last known numbers rather than being zeroed.
void main() {
  late db.AppDatabase database;
  late IngredientRepository ingredients;
  late FoodRepository foods;
  late MealRepository meals;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    ingredients = IngredientRepository(database);
    foods = FoodRepository(database);
    meals = MealRepository(database);
  });

  tearDown(() => database.close());

  Future<Ingredient> seedIngredient(
    String name, {
    double calories = 100,
    double protein = 10,
    double carbs = 20,
    double fat = 5,
  }) async {
    final ingredient = newIngredient(
      name: name,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
    );
    await ingredients.insert(ingredient);
    return ingredient;
  }

  Future<MealFoodDraft> draft(
    String foodId,
    String foodName,
    double amount,
  ) async {
    final nutrition = await foods.resolveNutrition(foodId);
    return (
      foodId: foodId,
      foodName: foodName,
      amount: amount,
      nutrition: nutrition,
    );
  }

  Future<void> logFood(String foodId, String foodName, double amount) async {
    await meals.insert(
      newMeal(
        name: 'Lunch',
        eatenAt: DateTime(2026, 3, 1, 12),
        foods: [await draft(foodId, foodName, amount)],
      ),
    );
  }

  Future<MealFood> loggedPortion() async =>
      (await meals.getAll()).single.items.single;

  group('an ingredient edit re-derives what depends on it', () {
    test(
      'a meal logging the ingredient directly follows the new macros',
      () async {
        final oats = await seedIngredient('Oats', calories: 400);
        await logFood(derivedFoodId(oats.id), 'Oats', 100);
        expect((await loggedPortion()).calories, 400);

        await ingredients.update(
          oats.copyWith(caloriesPer100g: 500, proteinPer100g: 20),
        );

        final after = await loggedPortion();
        expect(after.calories, 500);
        expect(after.protein, 20);
      },
    );

    test('a meal logging a recipe containing it follows too', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final honey = await seedIngredient('Honey', calories: 300);

      // 80 g oats + 20 g honey = 380 kcal per 100 g of batch.
      final granola = newFood(name: 'Granola');
      await foods.insert(granola, [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats.id,
          ingredientName: 'Oats',
          amount: 80,
        ),
        FoodIngredient(
          foodId: granola.id,
          ingredientId: honey.id,
          ingredientName: 'Honey',
          amount: 20,
        ),
      ]);
      await logFood(granola.id, 'Granola', 100);
      expect((await loggedPortion()).calories, closeTo(380, 1e-9));

      // Oats 400 -> 800 doubles the oats term: (800*80 + 300*20)/100 = 700.
      await ingredients.update(oats.copyWith(caloriesPer100g: 800));

      expect((await loggedPortion()).calories, closeTo(700, 1e-9));
    });

    test('an ingredient nothing depends on rewrites nothing', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final lonely = await seedIngredient('Lonely', calories: 400);
      await logFood(derivedFoodId(oats.id), 'Oats', 100);

      final resnapshot = MealResnapshot(database);
      final affected = await resnapshot.foodsAffectedByIngredient(lonely.id);
      // Only its own derived food, which no meal has logged.
      expect(affected, {derivedFoodId(lonely.id)});
      expect(await resnapshot.applyToFoods(affected), 0);

      expect((await loggedPortion()).calories, 400);
    });
  });

  group('a recipe edit re-derives what depends on it', () {
    test('changing an amount moves the logged portion', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final granola = newFood(name: 'Granola');
      await foods.insert(granola, [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats.id,
          ingredientName: 'Oats',
          amount: 100,
        ),
      ]);
      await logFood(granola.id, 'Granola', 200);
      expect((await loggedPortion()).calories, 800);

      // Halve the oats and add honey at equal weight.
      final honey = await seedIngredient('Honey', calories: 100);
      await foods.update(granola.copyWith(name: 'Granola'), [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats.id,
          ingredientName: 'Oats',
          amount: 50,
        ),
        FoodIngredient(
          foodId: granola.id,
          ingredientId: honey.id,
          ingredientName: 'Honey',
          amount: 50,
        ),
      ]);

      // (400*50 + 100*50)/100 = 250 per 100 g, so 500 for the logged 200 g.
      expect((await loggedPortion()).calories, closeTo(500, 1e-9));
    });

    test('a recipe arriving from the server also re-derives', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final granola = newFood(name: 'Granola');
      await foods.insert(granola, [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats.id,
          ingredientName: 'Oats',
          amount: 100,
        ),
      ]);
      await logFood(granola.id, 'Granola', 100);
      expect((await loggedPortion()).calories, 400);

      // Same food id, corrected composition from the server.
      await foods.applyFromServer(granola, [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats.id,
          ingredientName: 'Oats',
          amount: 200,
        ),
      ]);

      // A single component always collapses to the ingredient's own per-100g.
      expect((await loggedPortion()).calories, 400);
    });
  });

  group('degradation', () {
    test('a food that stops resolving keeps its last known numbers', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final honey = await seedIngredient('Honey', calories: 300);
      final granola = newFood(name: 'Granola');
      await foods.insert(granola, [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats.id,
          ingredientName: 'Oats',
          amount: 50,
        ),
        FoodIngredient(
          foodId: granola.id,
          ingredientId: honey.id,
          ingredientName: 'Honey',
          amount: 50,
        ),
      ]);
      await logFood(granola.id, 'Granola', 100);
      final before = (await loggedPortion()).calories;
      expect(before, closeTo(350, 1e-9));

      // Delete the honey ingredient outright, so the recipe cannot resolve.
      await (database.delete(
        database.ingredients,
      )..where((t) => t.id.equals(honey.id))).go();
      expect(await foods.resolveNutrition(granola.id), isNull);

      await MealResnapshot(database).applyToFoods({granola.id});

      // Still the last figure that described a portion genuinely eaten —
      // not zeroed, which would invent a claim.
      expect((await loggedPortion()).calories, closeTo(before, 1e-9));
    });

    test('re-deriving twice is stable', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      await logFood(derivedFoodId(oats.id), 'Oats', 100);
      await ingredients.update(oats.copyWith(caloriesPer100g: 500));
      final once = (await loggedPortion()).calories;

      await MealResnapshot(database).applyToFoods({derivedFoodId(oats.id)});
      expect((await loggedPortion()).calories, once);
    });
  });

  group('foodsAffectedByIngredient', () {
    test(
      'lists the derived food plus every recipe using the ingredient',
      () async {
        final oats = await seedIngredient('Oats');
        final granola = newFood(name: 'Granola');
        await foods.insert(granola, [
          FoodIngredient(
            foodId: granola.id,
            ingredientId: oats.id,
            ingredientName: 'Oats',
            amount: 100,
          ),
        ]);

        expect(
          await MealResnapshot(database).foodsAffectedByIngredient(oats.id),
          {derivedFoodId(oats.id), granola.id},
        );
      },
    );
  });
}
