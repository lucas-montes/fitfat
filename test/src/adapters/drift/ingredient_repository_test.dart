import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/adapters/drift/ingredient_repository.dart';
import 'package:fitfat/src/database/app_database.dart';
import 'package:fitfat/src/models/food.dart' as food;

void main() {
  group('DriftIngredientRepository', () {
    late AppDatabase database;
    late DriftIngredientRepository repository;
    const uuid = Uuid();

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = DriftIngredientRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts a new atomic ingredient and reads it back', () async {
      final ingredient = food.Ingredient(
        id: uuid.v7(),
        name: 'Test Apple',
        caloriesPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
        creatorId: null,
        isArchived: false,
        sodiumPer100g: null,
        fiberPer100g: null,
        sugarsPer100g: null,
        saturatedFatPer100g: null,
        cholesterolPer100g: null,
      );

      await repository.insert(ingredient);

      final ingredients = await repository.getAll();
      expect(ingredients, hasLength(1));
      expect(ingredients.single.id, ingredient.id);
      expect(ingredients.single.name, 'Test Apple');
      expect(ingredients.single.caloriesPer100g, 52);
      expect(ingredients.single.proteinPer100g, 0.3);
      expect(ingredients.single.carbsPer100g, 14);
      expect(ingredients.single.fatPer100g, 0.2);
    });

    test('inserts an ingredient with all optional fields', () async {
      final ingredient = food.Ingredient(
        id: uuid.v7(),
        name: 'Full Macro Item',
        caloriesPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 25,
        fatPer100g: 8,
        creatorId: 'user_test',
        isArchived: false,
        sodiumPer100g: 0.5,
        fiberPer100g: 3.0,
        sugarsPer100g: 5.0,
        saturatedFatPer100g: 2.0,
        cholesterolPer100g: 0.05,
      );

      await repository.insert(ingredient);

      final ingredients = await repository.getAll();
      expect(ingredients, hasLength(1));
      final saved = ingredients.single;
      expect(saved.creatorId, 'user_test');
      expect(saved.isArchived, false);
      expect(saved.sodiumPer100g, 0.5);
      expect(saved.fiberPer100g, 3.0);
      expect(saved.sugarsPer100g, 5.0);
      expect(saved.saturatedFatPer100g, 2.0);
      expect(saved.cholesterolPer100g, 0.05);
    });

    test('returns empty list when no ingredients exist', () async {
      final ingredients = await repository.getAll();
      expect(ingredients, isEmpty);
    });

    test('getById returns null for non-existent ingredient', () async {
      final result = await repository.getById('non-existent-id');
      expect(result, isNull);
    });

    test('getById returns ingredient when it exists', () async {
      final id = uuid.v7();
      final ingredient = food.Ingredient(
        id: id,
        name: 'Test Item',
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
      );

      await repository.insert(ingredient);

      final result = await repository.getById(id);
      expect(result, isNotNull);
      expect(result!.name, 'Test Item');
    });
  });

  group('MacroNutrients calculations', () {
    test('zero macros sum to zero', () {
      expect(food.MacroNutrients.zero.calories, 0);
      expect(food.MacroNutrients.zero.protein, 0);
      expect(food.MacroNutrients.zero.carbs, 0);
      expect(food.MacroNutrients.zero.fat, 0);
    });

    test('adding two macro sets', () {
      final a = food.MacroNutrients(
        calories: 200,
        protein: 10,
        carbs: 25,
        fat: 5,
      );
      final b = food.MacroNutrients(
        calories: 150,
        protein: 8,
        carbs: 20,
        fat: 4,
      );
      final sum = a + b;
      expect(sum.calories, 350);
      expect(sum.protein, 18);
      expect(sum.carbs, 45);
      expect(sum.fat, 9);
    });

    test('scaling macros', () {
      final macros = food.MacroNutrients(
        calories: 200,
        protein: 10,
        carbs: 25,
        fat: 5,
      );
      final scaled = macros.scale(0.5);
      expect(scaled.calories, 100);
      expect(scaled.protein, 5);
      expect(scaled.carbs, 12.5);
      expect(scaled.fat, 2.5);
    });

    test('macrosForGrams calculates correctly for 100g', () {
      final ingredient = food.Ingredient(
        id: 'test',
        name: 'Test',
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
      );
      final result = ingredient.macrosForGrams(100);
      expect(result.calories, 100);
      expect(result.protein, 10);
      expect(result.carbs, 20);
      expect(result.fat, 5);
    });

    test('macrosForGrams calculates correctly for 200g', () {
      final ingredient = food.Ingredient(
        id: 'test2',
        name: 'Test2',
        caloriesPer100g: 50,
        proteinPer100g: 5,
        carbsPer100g: 10,
        fatPer100g: 2.5,
      );
      final result = ingredient.macrosForGrams(200);
      expect(result.calories, 100);
      expect(result.protein, 10);
      expect(result.carbs, 20);
      expect(result.fat, 5);
    });

    test('macrosForGrams returns zero for zero grams', () {
      final ingredient = food.Ingredient(
        id: 'test3',
        name: 'Test3',
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
      );
      final result = ingredient.macrosForGrams(0);
      expect(result.calories, 0);
      expect(result.protein, 0);
      expect(result.carbs, 0);
      expect(result.fat, 0);
    });
  });
}
