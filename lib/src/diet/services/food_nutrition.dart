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
/// The numerator is the **sum of `per100g × amount`**; the denominator is
/// [cookedWeight] when the recipe has one, otherwise the raw sum of component
/// amounts. Cooking moves water in or out of the batch but leaves its calories
/// and macros behind, so using the cooked weight here is what makes a weighed
/// cooked portion score the same as the raw ingredients that went into it.
/// Sodium, fiber and sugar sum like the macros do — they are mandatory and
/// zero-defaulted, so a component that has none recorded contributes a real zero
/// rather than leaving the total undefined.
///
/// Each term accumulates `per100g * amount`, an **absolute** amount, so dividing
/// the totals by the denominator lands directly on a per-100g figure — there is
/// no extra /100 or x100 factor.
FoodNutrition resolveFoodPer100g(
  List<ComponentNutrition> components, {
  double? cookedWeight,
}) {
  var rawAmount = 0.0;
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
    rawAmount += c.amount;
    calories += c.caloriesPer100g * c.amount;
    protein += c.proteinPer100g * c.amount;
    carbs += c.carbsPer100g * c.amount;
    fat += c.fatPer100g * c.amount;
    sodium += c.sodiumPer100g * c.amount;
    fiber += c.fiberPer100g * c.amount;
    sugar += c.sugarPer100g * c.amount;
  }

  if (rawAmount <= 0) {
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

  // A non-positive cooked weight is treated as unset: the form and repository
  // reject it, and falling back to raw is the only meaningful resolution here.
  final denominator = cookedWeight != null && cookedWeight > 0
      ? cookedWeight
      : rawAmount;
  final factor = 1.0 / denominator;
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
    totalAmount: denominator,
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
Nutrition? resolvePortion(
  List<ComponentNutrition> components,
  double amount, {
  double? cookedWeight,
}) {
  final resolved = resolveFoodPer100g(components, cookedWeight: cookedWeight);
  if (resolved.totalAmount <= 0) return null;
  return scaleToAmount(resolved.per100g, amount);
}
