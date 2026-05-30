import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/models/food.dart';

void main() {
  group('MacroNutrients', () {
    test('zero returns all zeros', () {
      const zero = MacroNutrients.zero;
      expect(zero.calories, 0);
      expect(zero.protein, 0);
      expect(zero.carbs, 0);
      expect(zero.fat, 0);
    });

    test('addition combines two macro sets', () {
      const a = MacroNutrients(calories: 200, protein: 10, carbs: 25, fat: 5);
      const b = MacroNutrients(calories: 150, protein: 8, carbs: 20, fat: 4);
      final sum = a + b;
      expect(sum.calories, 350);
      expect(sum.protein, 18);
      expect(sum.carbs, 45);
      expect(sum.fat, 9);
    });

    test('identity addition with zero', () {
      const a = MacroNutrients(calories: 100, protein: 5, carbs: 10, fat: 2);
      const zero = MacroNutrients.zero;
      expect((a + zero).calories, 100);
      expect((zero + a).calories, 100);
    });

    test('scale multiplies all values', () {
      const macros = MacroNutrients(
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

    test('scale by 1 returns same values', () {
      const macros = MacroNutrients(
        calories: 200,
        protein: 10,
        carbs: 25,
        fat: 5,
      );
      final scaled = macros.scale(1.0);
      expect(scaled.calories, 200);
      expect(scaled.protein, 10);
      expect(scaled.carbs, 25);
      expect(scaled.fat, 5);
    });

    test('scale by 0 returns zero', () {
      const macros = MacroNutrients(
        calories: 200,
        protein: 10,
        carbs: 25,
        fat: 5,
      );
      final scaled = macros.scale(0.0);
      expect(scaled.calories, 0);
      expect(scaled.protein, 0);
      expect(scaled.carbs, 0);
      expect(scaled.fat, 0);
    });
  });

  group('Ingredient', () {
    const uuid = Uuid();

    test('isComposite is true when components are non-empty', () {
      final ingredient = Ingredient(
        id: uuid.v7(),
        name: 'Composite',
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
        components: [
          IngredientPortion(
            ingredient: Ingredient(
              id: 'sub1',
              name: 'Sub Item',
              caloriesPer100g: 50,
              proteinPer100g: 5,
              carbsPer100g: 10,
              fatPer100g: 2.5,
            ),
            grams: 50,
          ),
        ],
      );
      expect(ingredient.isComposite, isTrue);
    });

    test('isComposite is false when components are empty', () {
      final ingredient = Ingredient(
        id: uuid.v7(),
        name: 'Atomic',
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
        components: [],
      );
      expect(ingredient.isComposite, isFalse);
    });

    test('macrosForGrams computes correctly for 100g', () {
      final ingredient = Ingredient(
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

    test('macrosForGrams computes correctly for 200g (doubles)', () {
      final ingredient = Ingredient(
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
      final ingredient = Ingredient(
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

    test('macrosForGrams rounds correctly for partial amounts', () {
      final ingredient = Ingredient(
        id: 'test4',
        name: 'Test4',
        caloriesPer100g: 250,
        proteinPer100g: 12.5,
        carbsPer100g: 30.3,
        fatPer100g: 8.7,
      );
      final result = ingredient.macrosForGrams(30);
      expect(result.calories, closeTo(75, 0.01));
      expect(result.protein, closeTo(3.75, 0.01));
      expect(result.carbs, closeTo(9.09, 0.01));
      expect(result.fat, closeTo(2.61, 0.01));
    });
  });

  group('IngredientPortion', () {
    test('macros returns correct values for portion', () {
      final ingredient = Ingredient(
        id: 'test',
        name: 'Test',
        caloriesPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
      );
      final portion = IngredientPortion(ingredient: ingredient, grams: 150);
      final macros = portion.macros;
      expect(macros.calories, 150);
      expect(macros.protein, 15);
      expect(macros.carbs, 30);
      expect(macros.fat, 7.5);
    });
  });

  group('MealEntry', () {
    test('totalMacros sums all portions', () {
      final ingredient1 = Ingredient(
        id: 'ing1',
        name: 'Chicken',
        caloriesPer100g: 165,
        proteinPer100g: 31,
        carbsPer100g: 0,
        fatPer100g: 3.6,
      );
      final ingredient2 = Ingredient(
        id: 'ing2',
        name: 'Rice',
        caloriesPer100g: 130,
        proteinPer100g: 2.7,
        carbsPer100g: 28,
        fatPer100g: 0.3,
      );

      final meal = MealEntry(
        id: 'meal1',
        eatenAt: DateTime(2026, 5, 28, 12, 30),
        items: [
          IngredientPortion(ingredient: ingredient1, grams: 200),
          IngredientPortion(ingredient: ingredient2, grams: 150),
        ],
      );

      final total = meal.totalMacros;
      // Chicken 200g: 330 kcal, 62g protein, 0g carbs, 7.2g fat
      // Rice 150g: 195 kcal, 4.05g protein, 42g carbs, 0.45g fat
      // Total: 525 kcal, 66.05g protein, 42g carbs, 7.65g fat
      expect(total.calories, closeTo(525, 0.01));
      expect(total.protein, closeTo(66.05, 0.01));
      expect(total.carbs, closeTo(42.0, 0.01));
      expect(total.fat, closeTo(7.65, 0.01));
    });

    test('empty meal has zero total macros', () {
      final meal = MealEntry(
        id: 'empty',
        eatenAt: DateTime(2026, 5, 28),
        items: [],
      );
      final total = meal.totalMacros;
      expect(total.calories, 0);
      expect(total.protein, 0);
      expect(total.carbs, 0);
      expect(total.fat, 0);
    });
  });
}
