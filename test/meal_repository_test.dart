import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/repositories/meal_repository.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:uuid/uuid.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/models/meal_food.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<String> seedIngredient(
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
    return ingredient.id;
  }

  /// A `MealFoodDraft` for [foodId], resolving its live nutrition the way a
  /// screen would.
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

  Future<MealEntry> logMeal(
    String name,
    List<MealFoodDraft> drafts, {
    DateTime? eatenAt,
  }) async {
    final meal = newMeal(
      name: name,
      eatenAt: eatenAt ?? DateTime(2026, 3, 1, 12),
      foods: drafts,
    );
    await meals.insert(meal);
    return meal;
  }

  group('portion snapshots', () {
    test('a logged portion follows a later ingredient edit', () async {
      final oats = await seedIngredient(
        'Oats',
        calories: 400,
        protein: 13,
        carbs: 60,
        fat: 7,
      );

      await logMeal('Breakfast', [
        await draft(derivedFoodId(oats), 'Oats', 80),
      ]);

      var stored = (await meals.getAll()).single;
      expect(stored.items.single.calories, closeTo(320, 1e-9));
      expect(stored.items.single.protein, closeTo(10.4, 1e-9));
      expect(stored.totalCalories, closeTo(320, 1e-9));

      // Correcting the ingredient re-derives the portion that used it: the
      // snapshot is a cache of the derivation, not an independent record of
      // what was eaten. 80 g at 250 kcal/100g is 200.
      await ingredients.update(
        (await ingredients.getById(oats))!.copyWith(caloriesPer100g: 250),
      );

      stored = (await meals.getAll()).single;
      expect(stored.items.single.calories, closeTo(200, 1e-9));
      expect(stored.items.single.protein, closeTo(10.4, 1e-9));
      expect(stored.totalCalories, closeTo(200, 1e-9));
    });

    test('a recipe portion snapshots the resolved combination', () async {
      final oats = await seedIngredient(
        'Oats',
        calories: 400,
        protein: 13,
        carbs: 60,
        fat: 7,
      );
      final honey = await seedIngredient(
        'Honey',
        calories: 300,
        protein: 0,
        carbs: 80,
        fat: 0,
      );
      final granola = newFood(name: 'Granola');
      await foods.insert(granola, [
        FoodIngredient(
          foodId: granola.id,
          ingredientId: oats,
          ingredientName: 'Oats',
          amount: 80,
        ),
        FoodIngredient(
          foodId: granola.id,
          ingredientId: honey,
          ingredientName: 'Honey',
          amount: 20,
        ),
      ]);

      await logMeal('Breakfast', [await draft(granola.id, 'Granola', 150)]);

      final stored = (await meals.getAll()).single;
      // 380 kcal per 100g of recipe × 150g.
      expect(stored.items.single.calories, closeTo(570, 1e-9));
      expect(stored.totalCalories, closeTo(570, 1e-9));
    });

    test(
      'a food whose composition cannot be resolved refuses the log',
      () async {
        final oats = await seedIngredient('Oats');
        await expectLater(
          logMeal('Breakfast', [
            (
              foodId: derivedFoodId(oats),
              foodName: 'Oats',
              amount: 100,
              nutrition: null,
            ),
          ]),
          throwsArgumentError,
        );
        // Nothing was written.
        expect(await meals.getAll(), isEmpty);
      },
    );

    test('a non-positive amount refuses the log', () async {
      final oats = await seedIngredient('Oats');
      await expectLater(
        logMeal('Breakfast', [await draft(derivedFoodId(oats), 'Oats', 0)]),
        throwsArgumentError,
      );
      expect(await meals.getAll(), isEmpty);
    });
  });

  group('amount edits', () {
    test('updateAmounts rescales the snapshot exactly', () async {
      final oats = await seedIngredient('Oats', calories: 400, protein: 13);
      final meal = await logMeal('Breakfast', [
        await draft(derivedFoodId(oats), 'Oats', 100),
      ]);

      await meals.updateAmounts(meal.id, {meal.items.single.id: 250});

      final stored = (await meals.getAll()).single.items.single;
      expect(stored.amount, 250);
      expect(stored.calories, closeTo(1000, 1e-9));
      expect(stored.protein, closeTo(32.5, 1e-9));
    });

    test('updateAmounts leaves untouched rows alone', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final honey = await seedIngredient('Honey', calories: 300);
      final meal = await logMeal('Lunch', [
        await draft(derivedFoodId(oats), 'Oats', 100),
        await draft(derivedFoodId(honey), 'Honey', 50),
      ]);

      await meals.updateAmounts(meal.id, {meal.items.first.id: 200});

      final stored = (await meals.getAll()).single;
      expect(stored.items.first.calories, closeTo(800, 1e-9));
      expect(stored.items.last.calories, closeTo(150, 1e-9));
    });

    test('re-snapshot via update picks up an ingredient edit', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final meal = await logMeal('Breakfast', [
        await draft(derivedFoodId(oats), 'Oats', 100),
      ]);

      await ingredients.update(
        (await ingredients.getById(oats))!.copyWith(caloriesPer100g: 250),
      );

      // The cascade above has already refreshed this row, so this asserts the
      // narrower thing: update() writes a fresh resolution rather than rescaling
      // what is stored. Built directly rather than via newMeal(), which mints a
      // fresh id — the edit path targets an existing meal.
      await meals.update(
        MealEntry(
          id: meal.id,
          name: meal.name,
          eatenAt: meal.eatenAt,
          createdAt: meal.createdAt,
          items: [
            MealFood(
              id: meal.items.single.id,
              mealId: meal.id,
              foodId: derivedFoodId(oats),
              foodName: 'Oats',
              amount: 100,
              calories: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              nutrition: await foods.resolveNutrition(derivedFoodId(oats)),
            ),
          ],
        ),
      );

      expect(
        (await meals.getAll()).single.items.single.calories,
        closeTo(250, 1e-9),
      );
    });
  });

  group('reads', () {
    test('getAll is newest-first and carries live food names', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final food = derivedFoodId(oats);

      await logMeal('Early', [
        await draft(food, 'Oats', 100),
      ], eatenAt: DateTime(2026, 3, 1, 8));
      await logMeal('Late', [
        await draft(food, 'Oats', 100),
      ], eatenAt: DateTime(2026, 3, 2, 20));

      final all = await meals.getAll();
      expect(all.map((m) => m.name), ['Late', 'Early']);

      // The name is live: renaming the ingredient shows through.
      await ingredients.update(
        (await ingredients.getById(oats))!.copyWith(name: 'Rolled oats'),
      );
      expect((await meals.getAll()).first.items.single.foodName, 'Rolled oats');
    });

    test('a meal row whose food vanished is skipped, not fatal', () async {
      final oats = await seedIngredient('Oats');
      final meal = await logMeal('Breakfast', [
        await draft(derivedFoodId(oats), 'Oats', 100),
      ]);

      // A hard delete of the food is not a supported operation (foods are
      // soft-archived), but the read path must not crash if it happens.
      await (database.delete(
        database.foods,
      )..where((t) => t.id.equals(derivedFoodId(oats)))).go();

      final stored = (await meals.getAll()).single;
      expect(stored.items, isEmpty);
      expect(stored.totalCalories, 0);
      expect(meal.items, hasLength(1));
    });

    test('totalsBetween aggregates the snapshots in one query', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final food = derivedFoodId(oats);

      await logMeal('Breakfast', [
        await draft(food, 'Oats', 100),
      ], eatenAt: DateTime(2026, 3, 1, 8));
      await logMeal('Lunch', [
        await draft(food, 'Oats', 50),
      ], eatenAt: DateTime(2026, 3, 1, 13));
      await logMeal('Tomorrow', [
        await draft(food, 'Oats', 100),
      ], eatenAt: DateTime(2026, 3, 2, 8));

      final totals = await meals.totalsBetween(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
      );
      // 400 + 200 from the 1st only.
      expect(totals.calories, closeTo(600, 1e-9));
    });

    test('an empty window totals to zero for every field', () async {
      final totals = await meals.totalsBetween(DateTime(2020), DateTime(2021));
      expect(totals.calories, 0);
      // Was null while the fields were nullable; zero now, since an empty SUM is
      // wrapped in COALESCE and every field is non-nullable.
      expect(totals.sodium, 0);
      expect(totals.fiber, 0);
      expect(totals.sugar, 0);
    });
  });

  group('writes', () {
    test('update replaces the meal foods', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final honey = await seedIngredient('Honey', calories: 300);
      final food = derivedFoodId(oats);

      final meal = await logMeal('Breakfast', [await draft(food, 'Oats', 100)]);
      expect((await meals.getAll()).single.items, hasLength(1));

      await meals.update(
        MealEntry(
          id: meal.id,
          name: 'Brunch',
          eatenAt: meal.eatenAt,
          createdAt: meal.createdAt,
          items: [
            MealFood(
              id: const Uuid().v7(),
              mealId: meal.id,
              foodId: derivedFoodId(honey),
              foodName: 'Honey',
              amount: 50,
              calories: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              nutrition: await foods.resolveNutrition(derivedFoodId(honey)),
            ),
          ],
        ),
      );

      final stored = (await meals.getAll()).single;
      expect(stored.name, 'Brunch');
      expect(stored.items, hasLength(1));
      expect(stored.items.single.foodName, 'Honey');
      expect(stored.totalCalories, closeTo(150, 1e-9));
    });

    test(
      'delete removes the foods too, and restore brings them back',
      () async {
        final oats = await seedIngredient('Oats', calories: 400);
        final food = derivedFoodId(oats);
        final meal = await logMeal('Breakfast', [
          await draft(food, 'Oats', 100),
        ]);

        await meals.delete(meal.id);
        expect(await meals.getAll(), isEmpty);
        expect(await database.select(database.mealFoods).get(), isEmpty);

        await meals.restore(meal);
        final restored = (await meals.getAll()).single;
        expect(restored.items.single.calories, closeTo(400, 1e-9));
      },
    );

    test('a food can appear twice in one meal', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final food = derivedFoodId(oats);

      await logMeal('Brunch', [
        await draft(food, 'Oats', 50),
        await draft(food, 'Oats', 30),
      ]);

      final stored = (await meals.getAll()).single;
      expect(stored.items, hasLength(2));
      expect(stored.totalCalories, closeTo(320, 1e-9));
    });
  });
}
