import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/diet/services/macro_calculation_service.dart';
import 'package:fitfat/src/models/food.dart';

void main() {
  group('MacroCalculationService', () {
    late MacroCalculationService service;
    const uuid = Uuid();

    setUp(() {
      service = MacroCalculationService();
    });

    group('computePer100g', () {
      test('returns zero for empty components', () {
        final result = service.computePer100g([]);
        expect(result.calories, 0);
        expect(result.protein, 0);
        expect(result.carbs, 0);
        expect(result.fat, 0);
      });

      test('computes weighted average for single component', () {
        final chicken = Ingredient(
          id: uuid.v7(),
          name: 'Chicken',
          caloriesPer100g: 165,
          proteinPer100g: 31,
          carbsPer100g: 0,
          fatPer100g: 3.6,
        );

        final result = service.computePer100g([
          IngredientPortion(ingredient: chicken, grams: 100),
        ]);

        expect(result.calories, closeTo(165, 0.01));
        expect(result.protein, closeTo(31, 0.01));
        expect(result.carbs, 0);
        expect(result.fat, closeTo(3.6, 0.01));
      });

      test('computes weighted average for two components', () {
        final chicken = Ingredient(
          id: uuid.v7(),
          name: 'Chicken',
          caloriesPer100g: 165,
          proteinPer100g: 31,
          carbsPer100g: 0,
          fatPer100g: 3.6,
        );
        final rice = Ingredient(
          id: uuid.v7(),
          name: 'Rice',
          caloriesPer100g: 130,
          proteinPer100g: 2.7,
          carbsPer100g: 28,
          fatPer100g: 0.3,
        );

        // 200g chicken + 100g rice = 300g total
        // Chicken ratio: 2/3, Rice ratio: 1/3
        // Calories: 165*(2/3) + 130*(1/3) = 110 + 43.33 = 153.33
        final result = service.computePer100g([
          IngredientPortion(ingredient: chicken, grams: 200),
          IngredientPortion(ingredient: rice, grams: 100),
        ]);

        expect(result.calories, closeTo(153.33, 0.1));
        expect(result.protein, closeTo(21.57, 0.1));
        expect(result.carbs, closeTo(9.33, 0.1));
        expect(result.fat, closeTo(2.5, 0.1));
      });
    });

    group('dailyTotals', () {
      test('returns zero for empty meal list', () {
        final result = service.dailyTotals([]);
        expect(result.calories, 0);
      });

      test('sums macros across meals', () {
        final chicken = Ingredient(
          id: uuid.v7(),
          name: 'Chicken',
          caloriesPer100g: 165,
          proteinPer100g: 31,
          carbsPer100g: 0,
          fatPer100g: 3.6,
        );
        final rice = Ingredient(
          id: uuid.v7(),
          name: 'Rice',
          caloriesPer100g: 130,
          proteinPer100g: 2.7,
          carbsPer100g: 28,
          fatPer100g: 0.3,
        );

        final meals = [
          MealEntry(
            id: uuid.v7(),
            eatenAt: DateTime(2026, 5, 28, 12),
            items: [IngredientPortion(ingredient: chicken, grams: 200)],
          ),
          MealEntry(
            id: uuid.v7(),
            eatenAt: DateTime(2026, 5, 28, 19),
            items: [IngredientPortion(ingredient: rice, grams: 150)],
          ),
        ];

        // Chicken 200g: 330kcal, Rice 150g: 195kcal = 525 total
        final result = service.dailyTotals(meals);
        expect(result.calories, closeTo(525, 0.01));
      });
    });

    group('groupMealsByDay', () {
      test('groups meals by calendar day ignoring time', () {
        final meals = [
          MealEntry(
            id: uuid.v7(),
            eatenAt: DateTime(2026, 5, 28, 12),
            items: [],
          ),
          MealEntry(
            id: uuid.v7(),
            eatenAt: DateTime(2026, 5, 28, 19),
            items: [],
          ),
          MealEntry(
            id: uuid.v7(),
            eatenAt: DateTime(2026, 5, 27, 8),
            items: [],
          ),
        ];

        final grouped = service.groupMealsByDay(meals);
        expect(grouped.length, 2);
        expect(grouped[DateTime(2026, 5, 28)], hasLength(2));
        expect(grouped[DateTime(2026, 5, 27)], hasLength(1));
      });

      test('sorts days descending', () {
        final meals = [
          MealEntry(id: uuid.v7(), eatenAt: DateTime(2026, 5, 27), items: []),
          MealEntry(id: uuid.v7(), eatenAt: DateTime(2026, 5, 28), items: []),
          MealEntry(id: uuid.v7(), eatenAt: DateTime(2026, 5, 26), items: []),
        ];

        final grouped = service.groupMealsByDay(meals);
        final keys = grouped.keys.toList();
        expect(keys[0], DateTime(2026, 5, 28));
        expect(keys[1], DateTime(2026, 5, 27));
        expect(keys[2], DateTime(2026, 5, 26));
      });

      test('returns empty map for empty input', () {
        final grouped = service.groupMealsByDay([]);
        expect(grouped, isEmpty);
      });
    });

    group('validateIngredient', () {
      test('returns error for empty name', () {
        final error = service.validateIngredient('', [], 100, 10, 20, 5);
        expect(error, isNotNull);
        expect(error, contains('name'));
      });

      test('returns null for valid composite ingredient', () {
        final chicken = Ingredient(
          id: uuid.v7(),
          name: 'Chicken',
          caloriesPer100g: 165,
          proteinPer100g: 31,
          carbsPer100g: 0,
          fatPer100g: 3.6,
        );
        final error = service.validateIngredient(
          'My Dish',
          [IngredientPortion(ingredient: chicken, grams: 100)],
          0,
          0,
          0,
          0,
        );
        expect(error, isNull);
      });

      test('returns error for atomic with all zero macros', () {
        final error = service.validateIngredient('Test', [], 0, 0, 0, 0);
        expect(error, isNotNull);
        expect(error, contains('macro'));
      });

      test('returns null for valid atomic ingredient with macros', () {
        final error = service.validateIngredient('Apple', [], 52, 0.3, 14, 0.2);
        expect(error, isNull);
      });
    });

    group('formatMacros', () {
      test('formats all macros by default', () {
        final text = service.formatMacros(
          MacroNutrients(calories: 200, protein: 10, carbs: 25, fat: 5),
        );
        expect(text, contains('200 kcal'));
        expect(text, contains('P 10.0g'));
        expect(text, contains('C 25.0g'));
        expect(text, contains('F 5.0g'));
      });

      test('filters macros based on visibility flags', () {
        final text = service.formatMacros(
          MacroNutrients(calories: 200, protein: 10, carbs: 25, fat: 5),
          showCalories: true,
          showProtein: false,
          showCarbs: true,
          showFat: false,
        );
        expect(text, contains('200 kcal'));
        expect(text, contains('C 25.0g'));
        expect(text, isNot(contains('P')));
        expect(text, isNot(contains('F')));
      });
    });
  });
}
