import 'ingredient.dart';

/// Plain domain model for a single ingredient portion within a meal.
final class MealIngredient {
  final String id;
  final String mealId;
  final String ingredientId;
  final String ingredientName;
  final double grams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const MealIngredient({
    required this.id,
    required this.mealId,
    required this.ingredientId,
    required this.ingredientName,
    required this.grams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  double get calories => (caloriesPer100g * grams) / 100;
  double get protein => (proteinPer100g * grams) / 100;
  double get carbs => (carbsPer100g * grams) / 100;
  double get fat => (fatPer100g * grams) / 100;

  /// Build from an [Ingredient] domain model.
  factory MealIngredient.fromIngredient({
    required String id,
    required String mealId,
    required Ingredient ingredient,
    required double grams,
  }) => MealIngredient(
    id: id,
    mealId: mealId,
    ingredientId: ingredient.id,
    ingredientName: ingredient.name,
    grams: grams,
    caloriesPer100g: ingredient.caloriesPer100g,
    proteinPer100g: ingredient.proteinPer100g,
    carbsPer100g: ingredient.carbsPer100g,
    fatPer100g: ingredient.fatPer100g,
  );
}
