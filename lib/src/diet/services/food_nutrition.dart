import '../../models/food.dart';

// The nutrition shapes are re-exported so the derivation and the shapes it
// speaks in are reachable from one import.
export '../../models/food.dart'
    show ComponentNutrition, FoodNutrition, Nutrition;

/// Resolves a food's nutrition from its composition.
///
/// This is the **only** place the `meal → food → ingredient` chain is turned
/// into numbers, and it is pure — no Drift, no models — so it is unit-testable
/// on its own and cannot drift between the form preview, the foods list, the
/// meal snapshot and the server.
///
/// The denominator is the **sum of component amounts**; there is no separate
/// yield/cook-weight input. An optional nutriment (sodium/fiber/sugar) stays
/// null only when *no* component ever provided a value for it; otherwise
/// components that omit it count as zero so the total stays meaningful.
///
/// Each term accumulates `per100g * amount`, an **absolute** amount, so dividing
/// the totals by the total weight lands directly on a per-100g figure — there is
/// no extra /100 or x100 factor.
FoodNutrition resolveFoodPer100g(List<ComponentNutrition> components) {
  var totalAmount = 0.0;
  var calories = 0.0;
  var protein = 0.0;
  var carbs = 0.0;
  var fat = 0.0;
  var sodium = 0.0;
  var fiber = 0.0;
  var sugar = 0.0;
  var sawSodium = false;
  var sawFiber = false;
  var sawSugar = false;

  for (final c in components) {
    totalAmount += c.amount;
    calories += c.caloriesPer100g * c.amount;
    protein += c.proteinPer100g * c.amount;
    carbs += c.carbsPer100g * c.amount;
    fat += c.fatPer100g * c.amount;
    if (c.sodiumPer100g != null) {
      sawSodium = true;
      sodium += c.sodiumPer100g! * c.amount;
    }
    if (c.fiberPer100g != null) {
      sawFiber = true;
      fiber += c.fiberPer100g! * c.amount;
    }
    if (c.sugarPer100g != null) {
      sawSugar = true;
      sugar += c.sugarPer100g! * c.amount;
    }
  }

  if (totalAmount <= 0) {
    return (
      per100g: (
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        sodium: sawSodium ? 0 : null,
        fiber: sawFiber ? 0 : null,
        sugar: sawSugar ? 0 : null,
      ),
      totalAmount: 0,
    );
  }

  final factor = 1.0 / totalAmount;
  return (
    per100g: (
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      sodium: sawSodium ? sodium * factor : null,
      fiber: sawFiber ? fiber * factor : null,
      sugar: sawSugar ? sugar * factor : null,
    ),
    totalAmount: totalAmount,
  );
}

/// Scales a per-100g [profile] to an absolute portion of [amount] grams.
///
/// This is what gets snapshotted onto a `meal_foods` row at log time. It is
/// linear in [amount], which is why editing a logged amount can rescale an
/// existing snapshot exactly instead of re-resolving the chain.
Nutrition scaleToAmount(Nutrition profile, double amount) {
  final factor = amount / 100;
  return (
    calories: profile.calories * factor,
    protein: profile.protein * factor,
    carbs: profile.carbs * factor,
    fat: profile.fat * factor,
    sodium: profile.sodium == null ? null : profile.sodium! * factor,
    fiber: profile.fiber == null ? null : profile.fiber! * factor,
    sugar: profile.sugar == null ? null : profile.sugar! * factor,
  );
}

/// Convenience for the common case: resolve a food and immediately take the
/// portion a meal would log for [amount] grams.
///
/// Returns `null` when the composition is empty or carries no weight, which is
/// the signal to refuse the log rather than record a zero-calorie meal.
Nutrition? resolvePortion(List<ComponentNutrition> components, double amount) {
  final resolved = resolveFoodPer100g(components);
  if (resolved.totalAmount <= 0) return null;
  return scaleToAmount(resolved.per100g, amount);
}
