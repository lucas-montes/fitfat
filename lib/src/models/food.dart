import 'ingredient.dart';

/// The seven nutrition numbers for an ingredient.
///
/// The same shape describes a per-100g profile and an absolute portion —
/// [FoodNutrition.per100g] is the former, a meal row's snapshot the latter.
/// The three optional nutriments are null only when nothing in the source ever
/// provided a value.
typedef Nutrition = ({
  double calories,
  double protein,
  double carbs,
  double fat,
  double sodium,
  double fiber,
  double sugar,
});

/// One ingredient's contribution to a food: its per-100g profile plus the
/// amount of it the food contains.
typedef ComponentNutrition = ({
  double caloriesPer100g,
  double proteinPer100g,
  double carbsPer100g,
  double fatPer100g,
  double sodiumPer100g,
  double fiberPer100g,
  double sugarPer100g,
  double amount,
});

/// A food resolved against its ingredients.
///
/// [per100g] is the food's own per-100g profile; [totalAmount] is the weight of
/// the batch it was derived from, which is what a portion is a fraction of.
typedef FoodNutrition = ({Nutrition per100g, double totalAmount});

/// Prefix marking a **derived** food: the auto-created 1:1 wrapper the app
/// creates for every ingredient so a meal can reference ingredients uniformly.
///
/// Encoding it in the id keeps `Food.isDerived` a prefix test rather than a
/// query, and lets the sync layer decide what is shareable without loading a
/// row.
const String kDerivedFoodPrefix = 'i:';

/// The id of the auto-created food that wraps [ingredientId].
///
/// Deterministic, so logging the same ingredient from anywhere always lands on
/// the same row instead of accumulating duplicates.
String derivedFoodId(String ingredientId) => '$kDerivedFoodPrefix$ingredientId';

/// Whether [id] denotes a derived (auto-created, read-only) food.
bool isDerivedFoodId(String id) => id.startsWith(kDerivedFoodPrefix);

/// A loggable thing: 1..N ingredients with amounts.
///
/// Foods carry **no nutrition of their own** — that is defined only on
/// [Ingredient] and resolved through [FoodIngredients]. See
/// `diet/services/food_nutrition.dart` for the single derivation used everywhere.
final class Food {
  final String id;
  final String name;
  final DateTime createdAt;

  /// Soft-delete marker; null means active. Foods are only ever hidden, never
  /// hard-deleted, because `meal_foods` references them.
  final DateTime? archivedAt;

  /// Composition, alphabetical by ingredient name when loaded from the
  /// repository. Empty for a food whose composition has not been loaded.
  final List<FoodIngredient> components;

  const Food({
    required this.id,
    required this.name,
    required this.createdAt,
    this.archivedAt,
    this.components = const [],
  });

  bool get isArchived => archivedAt != null;

  /// Auto-created 1:1 wrapper around a single ingredient. Derived foods are
  /// read-only: their `name` and `archivedAt` mirror the ingredient row and are
  /// written only by `IngredientRepository`.
  bool get isDerived => isDerivedFoodId(id);

  /// A user-created combination of more than one ingredient.
  bool get isCombination => components.length > 1;

  /// A food with no loaded composition cannot be resolved or logged.
  bool get hasComposition => components.isNotEmpty;

  Food copyWith({
    String? name,
    DateTime? createdAt,
    Object? archivedAt = _unset,
    List<FoodIngredient>? components,
  }) => Food(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: identical(archivedAt, _unset)
        ? this.archivedAt
        : archivedAt as DateTime?,
    components: components ?? this.components,
  );

  static const _unset = Object();
}

/// One ingredient in a food, with the amount of it the food contains.
///
/// [ingredientName] is a read-model convenience resolved by joining
/// `ingredients`; it is not persisted, so renaming an ingredient propagates
/// without rewriting composition rows.
final class FoodIngredient {
  final String foodId;
  final String ingredientId;
  final String ingredientName;
  final double amount;

  const FoodIngredient({
    required this.foodId,
    required this.ingredientId,
    required this.ingredientName,
    required this.amount,
  });

  /// The nutrition this component contributes, ready for
  /// [resolveFoodPer100g].
  ///
  /// [ingredient] supplies the per-100g profile — passed in rather than looked
  /// up, so callers can batch-resolve a whole food's composition in one pass.
  ComponentNutrition toNutrition(Ingredient ingredient) => (
    caloriesPer100g: ingredient.caloriesPer100g,
    proteinPer100g: ingredient.proteinPer100g,
    carbsPer100g: ingredient.carbsPer100g,
    fatPer100g: ingredient.fatPer100g,
    sodiumPer100g: ingredient.sodiumPer100g,
    fiberPer100g: ingredient.fiberPer100g,
    sugarPer100g: ingredient.sugarPer100g,
    amount: amount,
  );
}
