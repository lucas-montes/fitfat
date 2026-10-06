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
/// yield/cook-weight input. Sodium, fiber and sugar sum like the macros do —
/// they are mandatory and zero-defaulted, so a component that has none recorded
/// contributes a real zero rather than leaving the total undefined.
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

  // Every field accumulates the same way. There is no longer a "did any component
  // provide this" flag to track: an unrecorded nutriment is stored as 0, so a
  // component that omits it genuinely contributes nothing rather than leaving
  // the total in an undefined state.
  for (final c in components) {
    totalAmount += c.amount;
    calories += c.caloriesPer100g * c.amount;
    protein += c.proteinPer100g * c.amount;
    carbs += c.carbsPer100g * c.amount;
    fat += c.fatPer100g * c.amount;
    sodium += c.sodiumPer100g * c.amount;
    fiber += c.fiberPer100g * c.amount;
    sugar += c.sugarPer100g * c.amount;
  }

  if (totalAmount <= 0) {
    return (
      per100g: (
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        sodium: 0,
        fiber: 0,
        sugar: 0,
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
      sodium: sodium * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
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
    sodium: profile.sodium * factor,
    fiber: profile.fiber * factor,
    sugar: profile.sugar * factor,
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
