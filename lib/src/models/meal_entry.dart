import 'meal_ingredient.dart';

/// Plain domain model for a logged meal (collection of ingredients).
final class MealEntry {
  final String id;
  final String name;
  final DateTime eatenAt;
  final DateTime createdAt;

  /// The ingredients that make up this meal.
  /// Not persisted in the meals table directly; stored via meal_ingredients.
  final List<MealIngredient> items;

  const MealEntry({
    required this.id,
    required this.name,
    required this.eatenAt,
    required this.createdAt,
    this.items = const [],
  });

  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.calories);
}
