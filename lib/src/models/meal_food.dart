import 'food.dart';

/// One food logged in a meal, with the amount eaten and the nutrition that
/// amount represents.
///
/// The seven nutrition fields are a **snapshot taken at log time** by resolving
/// `foods → food_ingredients → ingredients` and scaling to [amount]. They are
/// read verbatim, never re-derived, so a meal's history is stable: editing an
/// ingredient or a recipe afterwards cannot change a meal that was already
/// logged. The food's *name* is deliberately not snapshotted — it stays live, so
/// renaming a recipe updates everywhere.
final class MealFood {
  final String id;
  final String mealId;
  final String foodId;

  /// Live, joined from `foods.name` — not part of the snapshot.
  final String foodName;

  /// Grams of this food eaten in the meal.
  final double amount;

  // Snapshot of this portion ---
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodium;
  final double fiber;
  final double sugar;

  /// The food's **live** per-100g profile at the moment of logging, used by
  /// `MealRepository` to produce the snapshot.
  ///
  /// Transient: read back from the database it is null, because the snapshot is
  /// all a stored row needs. An item loaded from history therefore carries no
  /// live profile — which is the point, since re-deriving one would defeat the
  /// snapshot.
  final FoodNutrition? nutrition;

  const MealFood({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.foodName,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sodium = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.nutrition,
  });

  /// The snapshot as a plain [Nutrition] record, for totals and rescaling.
  Nutrition get snapshot => (
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    sodium: sodium,
    fiber: fiber,
    sugar: sugar,
  );

  /// The same portion re-expressed for [newAmount] grams, used when the logged
  /// amount is edited. Exact, because the derivation is linear in the amount.
  ///
  /// Falls back to the current numbers when [amount] is zero — a food with no
  /// weight cannot be rescaled proportionally.
  MealFood withAmount(double newAmount) {
    if (amount <= 0) {
      return copyWith(amount: newAmount);
    }
    final factor = newAmount / amount;
    return copyWith(
      amount: newAmount,
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      sodium: sodium * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
    );
  }

  /// Replaces the snapshot wholesale — used when the food itself changes, which
  /// requires a fresh resolution rather than a rescale.
  MealFood withNutrition(Nutrition nutrition, {double? newAmount}) => copyWith(
    amount: newAmount ?? amount,
    calories: nutrition.calories,
    protein: nutrition.protein,
    carbs: nutrition.carbs,
    fat: nutrition.fat,
    sodium: nutrition.sodium,
    fiber: nutrition.fiber,
    sugar: nutrition.sugar,
  );

  MealFood copyWith({
    String? id,
    String? mealId,
    String? foodId,
    String? foodName,
    double? amount,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? sodium,
    double? fiber,
    double? sugar,
    FoodNutrition? nutrition,
  }) => MealFood(
    id: id ?? this.id,
    mealId: mealId ?? this.mealId,
    foodId: foodId ?? this.foodId,
    foodName: foodName ?? this.foodName,
    amount: amount ?? this.amount,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    sodium: sodium ?? this.sodium,
    fiber: fiber ?? this.fiber,
    sugar: sugar ?? this.sugar,
    nutrition: nutrition ?? this.nutrition,
  );

  static const _unset = Object();
}
