import 'package:fitfat/src/diet/services/food_nutrition.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a component with sensible defaults so each test only states what it
/// is actually asserting.
ComponentNutrition component({
  double calories = 100,
  double protein = 10,
  double carbs = 20,
  double fat = 5,
  double sodium = 0,
  double fiber = 0,
  double sugar = 0,
  required double amount,
}) => (
  caloriesPer100g: calories,
  proteinPer100g: protein,
  carbsPer100g: carbs,
  fatPer100g: fat,
  sodiumPer100g: sodium,
  fiberPer100g: fiber,
  sugarPer100g: sugar,
  amount: amount,
);

void main() {
  group('resolveFoodPer100g', () {
    test('weights components by amount and scales to 100g', () {
      // 50g at 100 kcal + 50g at 200 kcal = 15000 kcal-grams over a 100g batch.
      final result = resolveFoodPer100g([
        component(calories: 100, protein: 10, carbs: 20, fat: 5, amount: 50),
        component(calories: 200, protein: 20, carbs: 0, fat: 10, amount: 50),
      ]);

      expect(result.totalAmount, 100);
      expect(result.per100g.calories, 150);
      expect(result.per100g.protein, 15);
      expect(result.per100g.carbs, 10);
      expect(result.per100g.fat, 7.5);
    });

    test('normalizes to 100g regardless of total weight', () {
      // 30g at 400 kcal/100g = 120 kcal, 20g at 100 = 20 kcal. That is 140 kcal
      // across a 50g batch, so the per-100g figure must be 280.
      final result = resolveFoodPer100g([
        component(calories: 400, protein: 40, amount: 30),
        component(calories: 100, protein: 0, amount: 20),
      ]);

      expect(result.totalAmount, 50);
      expect(result.per100g.calories, closeTo(280, 1e-9));
      expect(result.per100g.protein, closeTo(24, 1e-9));
    });

    test('a single component equals that ingredient at any amount', () {
      // The invariant that lets a 1-ingredient food need no special case:
      // Σ(p·a)/Σa collapses to p whatever the amount.
      for (final amount in [1.0, 100.0, 250.0, 1000.0]) {
        final result = resolveFoodPer100g([
          component(
            calories: 400,
            protein: 13,
            carbs: 60,
            fat: 7,
            amount: amount,
          ),
        ]);
        expect(result.totalAmount, amount);
        expect(result.per100g.calories, 400, reason: 'amount=$amount');
        expect(result.per100g.protein, 13, reason: 'amount=$amount');
        expect(result.per100g.carbs, 60, reason: 'amount=$amount');
        expect(result.per100g.fat, 7, reason: 'amount=$amount');
      }
    });

    test('a nutriment only some components have averages like a macro', () {
      // Unrecorded is 0, so a component that has none contributes a real zero
      // rather than leaving the total in an undefined state.
      final partial = resolveFoodPer100g([
        component(sodium: 400, amount: 100),
        component(amount: 100),
      ]);
      expect(partial.per100g.sodium, 200);
      expect(partial.per100g.fiber, 0);
      expect(partial.per100g.sugar, 0);

      final noneAtAll = resolveFoodPer100g([component(amount: 100)]);
      expect(noneAtAll.per100g.sodium, 0);
    });

    test('empty composition yields zeroes, not a division by zero', () {
      final result = resolveFoodPer100g(const []);
      expect(result.totalAmount, 0);
      expect(result.per100g.calories, 0);
      expect(result.per100g.sodium, 0);
    });

    test('a zero-weight composition yields zeroes', () {
      final result = resolveFoodPer100g([component(amount: 0)]);
      expect(result.totalAmount, 0);
      expect(result.per100g.calories, 0);
    });
  });

  group('scaleToAmount', () {
    const profile = (
      calories: 380.0,
      protein: 10.4,
      carbs: 32.0,
      fat: 4.0,
      sodium: 4.0,
      fiber: 2.1,
      sugar: 12.0,
    );

    test('scales the per-100g profile to an absolute portion', () {
      expect(scaleToAmount(profile, 100).calories, closeTo(380, 1e-9));
      expect(scaleToAmount(profile, 50).calories, closeTo(190, 1e-9));
      expect(scaleToAmount(profile, 150).protein, closeTo(15.6, 1e-9));
      expect(scaleToAmount(profile, 150).sodium, closeTo(6, 1e-9));
      expect(scaleToAmount(profile, 0).calories, 0);
    });

    test('scales every field, nutriments included', () {
      final profile = resolveFoodPer100g([
        component(sodium: 400, fiber: 30, sugar: 10, amount: 100),
      ]).per100g;
      final scaled = scaleToAmount(profile, 200);
      expect(scaled.sodium, closeTo(profile.sodium * 2, 1e-9));
      expect(scaled.fiber, closeTo(profile.fiber * 2, 1e-9));
      expect(scaled.sugar, closeTo(profile.sugar * 2, 1e-9));
    });

    test('is linear, so rescaling a snapshot round-trips exactly', () {
      // The inverse of scaleToAmount is `portion * 100 / amount`. Going back to
      // a per-100g profile and re-scaling must land on the same numbers — this
      // is what lets a logged amount be edited without re-resolving the chain.
      final at150 = scaleToAmount(profile, 150);
      const backToPer100g = 100 / 150;
      final rescaled = scaleToAmount((
        calories: at150.calories * backToPer100g,
        protein: at150.protein * backToPer100g,
        carbs: at150.carbs * backToPer100g,
        fat: at150.fat * backToPer100g,
        sodium: at150.sodium! * backToPer100g,
        fiber: at150.fiber! * backToPer100g,
        sugar: at150.sugar! * backToPer100g,
      ), 250);

      final direct = scaleToAmount(profile, 250);
      expect(rescaled.calories, closeTo(direct.calories, 1e-9));
      expect(rescaled.protein, closeTo(direct.protein, 1e-9));
      expect(rescaled.carbs, closeTo(direct.carbs, 1e-9));
      expect(rescaled.fat, closeTo(direct.fat, 1e-9));
      expect(rescaled.sodium, closeTo(direct.sodium!, 1e-9));
    });
  });

  group('resolvePortion', () {
    test('resolves and scales in one step', () {
      // 80g oats (400/13/60/7) + 20g honey (300/0/80/0) over a 100g batch
      // gives 380 kcal, 10.4 P, 64 C, 5.6 F per 100g; 150g of it is 1.5x that.
      final portion = resolvePortion([
        component(calories: 400, protein: 13, carbs: 60, fat: 7, amount: 80),
        component(calories: 300, protein: 0, carbs: 80, fat: 0, amount: 20),
      ], 150);

      expect(portion, isNotNull);
      expect(portion!.calories, closeTo(570, 1e-9));
      expect(portion.protein, closeTo(15.6, 1e-9));
      expect(portion.carbs, closeTo(96, 1e-9));
      expect(portion.fat, closeTo(8.4, 1e-9));
    });

    test('returns null for an unresolvable composition', () {
      // The signal for the repository to refuse the log rather than record a
      // zero-calorie meal.
      expect(resolvePortion(const [], 100), isNull);
      expect(resolvePortion([component(amount: 0)], 100), isNull);
    });
  });
}
