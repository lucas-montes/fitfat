import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late IngredientRepository ingredients;
  late FoodRepository foods;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    ingredients = IngredientRepository(database);
    foods = FoodRepository(database);
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

  FoodIngredient component(String id, String name, double amount) =>
      FoodIngredient(
        foodId: '',
        ingredientId: id,
        ingredientName: name,
        amount: amount,
      );

  group('composition CRUD', () {
    test('insert stores the food and its composition', () async {
      final oats = await seedIngredient('Oats', calories: 400, protein: 13);
      final honey = await seedIngredient('Honey', calories: 300, carbs: 80);

      final granola = newFood(name: 'Granola');
      await foods.insert(granola, [
        component(oats, 'Oats', 80),
        component(honey, 'Honey', 20),
      ]);

      final saved = (await foods.getById(granola.id))!;
      expect(saved.name, 'Granola');
      expect(saved.isCombination, isTrue);
      expect(saved.components.map((c) => c.ingredientName), ['Honey', 'Oats']);
      expect(saved.components.map((c) => c.amount), [20, 80]);
    });

    test('components are ordered alphabetically by ingredient name', () async {
      final z = await seedIngredient('Zucchini');
      final a = await seedIngredient('Apple');

      final food = newFood(name: 'Salad');
      await foods.insert(food, [
        component(z, 'Zucchini', 50),
        component(a, 'Apple', 50),
      ]);

      expect(
        (await foods.getComponents(food.id)).map((c) => c.ingredientName),
        ['Apple', 'Zucchini'],
      );
    });

    test('update replaces the composition rather than merging', () async {
      final oats = await seedIngredient('Oats', calories: 400);
      final honey = await seedIngredient('Honey', calories: 300);

      final food = newFood(name: 'Granola');
      await foods.insert(food, [
        component(oats, 'Oats', 80),
        component(honey, 'Honey', 20),
      ]);
      expect(await foods.getComponents(food.id), hasLength(2));

      await foods.update(food.copyWith(name: 'Trail mix'), [
        component(oats, 'Oats', 100),
      ]);

      final saved = (await foods.getById(food.id))!;
      expect(saved.name, 'Trail mix');
      expect(saved.components, hasLength(1));
      expect(saved.components.single.ingredientName, 'Oats');
      expect(saved.isCombination, isFalse);
    });

    test('a food must have at least one ingredient', () async {
      final food = newFood(name: 'Nothing');
      expect(() => foods.insert(food, const []), throwsArgumentError);
      expect(() => foods.update(food, const []), throwsArgumentError);
    });

    test('non-positive component amounts are rejected atomically', () async {
      final oats = await seedIngredient('Oats');
      final food = newFood(name: 'Bad');

      await expectLater(
        foods.insert(food, [
          component(oats, 'Oats', 50),
          component(oats, 'Oats', 0),
        ]),
        throwsArgumentError,
      );
      // The rejected insert left nothing behind.
      expect(await foods.getById(food.id), isNull);
    });
  });

  group('derived foods are read-only here', () {
    test(
      'insert, update, archive and restore all refuse a derived id',
      () async {
        final oats = await seedIngredient('Oats');
        final derivedId = derivedFoodId(oats);
        final stub = Food(
          id: derivedId,
          name: 'hijack',
          createdAt: DateTime.now(),
        );

        expect(() => foods.insert(stub, const []), throwsArgumentError);
        expect(() => foods.update(stub, const []), throwsArgumentError);
        expect(() => foods.archive(derivedId), throwsArgumentError);
        expect(() => foods.restore(derivedId), throwsArgumentError);

        // Untouched by the attempt.
        expect((await foods.getById(derivedId))!.name, 'Oats');
      },
    );
  });

  group('live nutrition', () {
    test('a combination resolves from its components', () async {
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

      final food = newFood(name: 'Granola');
      await foods.insert(food, [
        component(oats, 'Oats', 80),
        component(honey, 'Honey', 20),
      ]);

      final resolved = await foods.resolveNutrition(food.id);
      expect(resolved!.totalAmount, 100);
      expect(resolved.per100g.calories, closeTo(380, 1e-9));
      expect(resolved.per100g.protein, closeTo(10.4, 1e-9));
    });

    test('a derived food resolves to exactly its ingredient', () async {
      final oats = await seedIngredient(
        'Oats',
        calories: 400,
        protein: 13,
        carbs: 60,
        fat: 7,
      );

      final resolved = await foods.resolveNutrition(derivedFoodId(oats));
      expect(resolved!.per100g.calories, 400);
      expect(resolved.per100g.protein, 13);
      expect(resolved.per100g.carbs, 60);
      expect(resolved.per100g.fat, 7);
    });

    test(
      'nutrition reflects an ingredient edit, since it is never stored',
      () async {
        final oats = await seedIngredient('Oats', calories: 400);

        final resolved = await foods.resolveNutrition(derivedFoodId(oats));
        expect(resolved!.per100g.calories, 400);

        await ingredients.update(
          (await ingredients.getById(oats))!.copyWith(caloriesPer100g: 250),
        );

        final after = await foods.resolveNutrition(derivedFoodId(oats));
        expect(after!.per100g.calories, 250);
      },
    );

    test(
      'getAllWithNutrition returns only active foods, name-ordered',
      () async {
        final oats = await seedIngredient('Oats');
        final honey = await seedIngredient('Honey');
        final food = newFood(name: 'Granola');
        await foods.insert(food, [
          component(oats, 'Oats', 80),
          component(honey, 'Honey', 20),
        ]);

        final all = await foods.getAllWithNutrition();
        // Two derived foods plus the combination.
        expect(all.map((e) => e.food.name), ['Granola', 'Honey', 'Oats']);
        expect(all.every((e) => e.nutrition != null), isTrue);
      },
    );

    test('archived foods drop out but keep their row', () async {
      final oats = await seedIngredient('Oats');
      final food = newFood(name: 'Granola');
      await foods.insert(food, [component(oats, 'Oats', 100)]);

      await foods.archive(food.id);
      expect(
        (await foods.getAllWithNutrition()).map((e) => e.food.id),
        isNot(contains(food.id)),
      );
      // Still resolvable by id, so a past meal can still name it.
      expect(await foods.getById(food.id), isNotNull);

      await foods.restore(food.id);
      expect(
        (await foods.getAllWithNutrition()).map((e) => e.food.id),
        contains(food.id),
      );
    });

    test(
      'a food whose ingredient went missing has no nutrition, not a crash',
      () async {
        final oats = await seedIngredient('Oats');
        final food = newFood(name: 'Granola');
        await foods.insert(food, [component(oats, 'Oats', 100)]);

        // Simulate a part that has not synced yet.
        await (database.delete(
          database.foodIngredients,
        )..where((t) => t.ingredientId.equals(oats))).go();

        final resolved = await foods.resolveNutrition(food.id);
        expect(resolved, isNull);
      },
    );
  });

  group('server application', () {
    test(
      'applyFromServer stores a recipe and tolerates unknown parts',
      () async {
        final oats = await seedIngredient('Oats', calories: 400);
        final remote = Food(
          id: 'server-food',
          name: 'Remote granola',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        );

        await foods.applyFromServer(remote, [
          const FoodIngredient(
            foodId: 'server-food',
            ingredientId: 'not-synced-yet',
            ingredientName: '',
            amount: 50,
          ),
          FoodIngredient(
            foodId: 'server-food',
            ingredientId: oats,
            ingredientName: 'Oats',
            amount: 50,
          ),
        ]);

        final saved = (await foods.getById(remote.id))!;
        expect(saved.name, 'Remote granola');
        // The unknown part was skipped; the row and name still landed.
        expect(saved.components, hasLength(1));
        expect(saved.components.single.ingredientId, oats);
      },
    );
  });
}
