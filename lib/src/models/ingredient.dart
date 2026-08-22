/// Plain domain model for a food ingredient.
final class Ingredient {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  // Optional extra nutriments per 100g (ingredient-only; not propagated to meals).
  final double? sodiumPer100g; // mg
  final double? fiberPer100g; // g
  final double? sugarPer100g; // g
  /// Soft-delete flag: archived ingredients are hidden from list and picker
  /// but stay in the DB so past meals keep rendering name/macros.
  final bool isArchived;
  // Shopping metadata (v20): brand name + barcode as printed on the package.
  final String? brand;
  final String? barcode;
  final DateTime createdAt;

  const Ingredient({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.sodiumPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.isArchived = false,
    this.brand,
    this.barcode,
    required this.createdAt,
  });

  /// Sentinel to distinguish "not passed" from "explicitly set to null".
  static const _unset = Object();

  Ingredient copyWith({
    String? id,
    String? name,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    Object? sodiumPer100g = _unset,
    Object? fiberPer100g = _unset,
    Object? sugarPer100g = _unset,
    bool? isArchived,
    Object? brand = _unset,
    Object? barcode = _unset,
    DateTime? createdAt,
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
    proteinPer100g: proteinPer100g ?? this.proteinPer100g,
    carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    fatPer100g: fatPer100g ?? this.fatPer100g,
    sodiumPer100g: identical(sodiumPer100g, _unset)
        ? this.sodiumPer100g
        : sodiumPer100g as double?,
    fiberPer100g: identical(fiberPer100g, _unset)
        ? this.fiberPer100g
        : fiberPer100g as double?,
    sugarPer100g: identical(sugarPer100g, _unset)
        ? this.sugarPer100g
        : sugarPer100g as double?,
    isArchived: isArchived ?? this.isArchived,
    brand: identical(brand, _unset) ? this.brand : brand as String?,
    barcode: identical(barcode, _unset) ? this.barcode : barcode as String?,
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
