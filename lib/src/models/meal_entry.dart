import 'meal_food.dart';

/// Plain domain model for a logged meal (a set of foods at a point in time).
final class MealEntry {
  final String id;
  final String name;
  final DateTime eatenAt;
  final DateTime createdAt;

  /// The foods logged in this meal. Not stored on the `meals` row itself —
  /// they live in `meal_foods`, each carrying a snapshot of the portion that
  /// was eaten.
  final List<MealFood> items;

  const MealEntry({
    required this.id,
    required this.name,
    required this.eatenAt,
    required this.createdAt,
    this.items = const [],
  });

  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.calories);

  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.protein);

  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);

  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);
}
