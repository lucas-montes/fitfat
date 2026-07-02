/// Plain domain model for a food ingredient.
final class Ingredient {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.createdAt,
  });

  Ingredient copyWith({
    String? id,
    String? name,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    DateTime? createdAt,
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
    proteinPer100g: proteinPer100g ?? this.proteinPer100g,
    carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    fatPer100g: fatPer100g ?? this.fatPer100g,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Calculate macros for a given gram amount.
  (double calories, double protein, double carbs, double fat) macrosForGrams(
    double grams,
  ) {
    final factor = grams / 100;
    return (
      caloriesPer100g * factor,
      proteinPer100g * factor,
      carbsPer100g * factor,
      fatPer100g * factor,
    );
  }
}
