import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/food.dart';
import '../../models/ingredient.dart';
import '../services/food_nutrition.dart';

/// A food plus its live per-100g profile — what the foods list and the meal
/// picker both display.
///
/// [nutrition] is `null` when the food has no resolvable composition (an empty
/// combination, or one whose ingredients are all missing locally).
typedef ResolvedFood = ({Food food, FoodNutrition? nutrition});

/// Owns `foods` + `food_ingredients` — the composition layer of the
/// `meal → food → ingredient` chain.
///
/// Foods carry no nutrition of their own: every number here is resolved live
/// from the ingredient rows via `food_nutrition.dart`. The exception is the
/// auto-created **derived** food of each ingredient, which
/// `IngredientRepository` writes and which this class refuses to touch — that
/// makes "a single food and its ingredient are always in sync" structural.
final class FoodRepository {
  final db.AppDatabase _database;
  const FoodRepository(this._database);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Every active food, name-ordered, with its live per-100g profile.
  ///
  /// Three queries regardless of how many foods exist: the foods, all their
  /// composition rows in one batch, then the ingredients those rows reference.
  /// Kept live on purpose — the browse path is a small bounded list, and a
  /// recipe must never show a number that has gone stale.
  Future<List<ResolvedFood>> getAllWithNutrition({
    bool includeArchived = false,
  }) async {
    final foods =
        await (_database.select(_database.foods)
              ..where(
                (t) => includeArchived
                    ? const Constant(true)
                    : t.archivedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return _resolveAll(foods);
  }

  /// One food with its composition loaded, or null when it does not exist.
  Future<Food?> getById(String id) async {
    final row = await (_database.select(
      _database.foods,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _foodToDomain(row, await getComponents(id));
  }

  /// The composition of [foodId], alphabetical by ingredient name.
  ///
  /// Alphabetical is the display order by decision: the table carries no
  /// `sort_order`, and ordering by name falls out of the join we already do to
  /// get the names.
  Future<List<FoodIngredient>> getComponents(String foodId) async {
    final query =
        _database.select(_database.foodIngredients).join([
            innerJoin(
              _database.ingredients,
              _database.ingredients.id.equalsExp(
                _database.foodIngredients.ingredientId,
              ),
            ),
          ])
          ..where(_database.foodIngredients.foodId.equals(foodId))
          ..orderBy([OrderingTerm.asc(_database.ingredients.name)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        FoodIngredient(
          foodId: row.readTable(_database.foodIngredients).foodId,
          ingredientId: row.readTable(_database.foodIngredients).ingredientId,
          ingredientName: row.readTable(_database.ingredients).name,
          amount: row.readTable(_database.foodIngredients).amount,
        ),
    ];
  }

  /// The live per-100g profile of one food, or `null` when it cannot be
  /// resolved (no composition, or no weight in it).
  ///
  /// This is what a meal row snapshots at log time.
  Future<FoodNutrition?> resolveNutrition(String foodId) async {
    final components = await getComponents(foodId);
    if (components.isEmpty) return null;
    final ingredients = await _ingredientsById(
      components.map((c) => c.ingredientId),
    );
    final nutrition = resolveFoodPer100g([
      for (final component in components)
        if (ingredients[component.ingredientId] case final ingredient?)
          component.toNutrition(ingredient),
    ]);
    if (nutrition.totalAmount <= 0) return null;
    return nutrition;
  }

  // ---------------------------------------------------------------------------
  // Writes (user-created foods only)
  // ---------------------------------------------------------------------------

  /// Creates a food and its composition in one transaction.
  ///
  /// A food must have at least one ingredient — a food with no composition has
  /// nothing to resolve and could not be logged.
  Future<void> insert(Food food, List<FoodIngredient> components) async {
    _rejectDerived(food.id);
    if (components.isEmpty) {
      throw ArgumentError('A food must be made of at least one ingredient');
    }
    await _database.transaction(() async {
      await _database
          .into(_database.foods)
          .insert(
            db.FoodsCompanion.insert(
              id: food.id,
              name: food.name,
              createdAt: food.createdAt.millisecondsSinceEpoch,
              archivedAt: Value(food.archivedAt?.millisecondsSinceEpoch),
            ),
          );
      await _replaceComponents(food.id, components);
    });
  }

  /// Creates a food and its composition in one transaction, returning the stored
  /// row with its composition attached — the shape a caller needs to push or
  /// display immediately after creating it.
  Future<Food> insertAndReturn(
    Food food,
    List<FoodIngredient> components,
  ) async {
    await insert(food, components);
    return (await getById(food.id))!;
  }

  /// Updates a food's name and replaces its composition wholesale.
  ///
  /// Replace semantics — the incoming list *is* the recipe, so a part dropped
  /// here disappears. Nutrition is never written: it is always resolved from the
  /// ingredients.
  Future<void> update(Food food, List<FoodIngredient> components) async {
    _rejectDerived(food.id);
    if (components.isEmpty) {
      throw ArgumentError('A food must be made of at least one ingredient');
    }
    await _database.transaction(() async {
      await (_database.update(
        _database.foods,
      )..where((t) => t.id.equals(food.id))).write(
        db.FoodsCompanion(
          name: Value(food.name),
          archivedAt: Value(food.archivedAt?.millisecondsSinceEpoch),
        ),
      );
      await _replaceComponents(food.id, components);
    });
  }

  /// Soft-delete. Meals that already reference the food keep rendering their
  /// snapshotted nutrition; the food simply leaves the picker.
  Future<void> archive(String id) async {
    _rejectDerived(id);
    await (_database.update(
      _database.foods,
    )..where((t) => t.id.equals(id))).write(
      db.FoodsCompanion(
        archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> restore(String id) async {
    _rejectDerived(id);
    await (_database.update(_database.foods)..where((t) => t.id.equals(id)))
        .write(const db.FoodsCompanion(archivedAt: Value(null)));
  }

  /// Applies a food received from the server.
  ///
  /// Composition rows referencing ingredients we do not have are skipped rather
  /// than throwing: a recipe whose parts have not synced yet still needs its row
  /// and name, it simply is not resolvable until they arrive. Server authority —
  /// the food's own `archivedAt` is taken as given.
  Future<void> applyFromServer(
    Food food,
    List<FoodIngredient> components,
  ) async {
    await _database.transaction(() async {
      await _database
          .into(_database.foods)
          .insert(
            db.FoodsCompanion.insert(
              id: food.id,
              name: food.name,
              createdAt: food.createdAt.millisecondsSinceEpoch,
              archivedAt: Value(food.archivedAt?.millisecondsSinceEpoch),
            ),
            mode: InsertMode.insertOrReplace,
          );
      await _replaceComponents(food.id, components);
    });
  }

  /// Throws when a write targets a derived food.
  ///
  /// Derived foods mirror their ingredient's name and archive state, written
  /// only by `IngredientRepository`. Letting the food path write them is how the
  /// pair would drift.
  void _rejectDerived(String id) {
    if (isDerivedFoodId(id)) {
      throw ArgumentError(
        'Derived foods are read-only; edit the ingredient instead: $id',
      );
    }
  }

  Future<void> _replaceComponents(
    String foodId,
    List<FoodIngredient> components,
  ) async {
    await (_database.delete(
      _database.foodIngredients,
    )..where((t) => t.foodId.equals(foodId))).go();
    for (final component in components) {
      if (component.amount <= 0) {
        throw ArgumentError(
          'Component amounts must be positive: ${component.ingredientName}',
        );
      }
      await _database
          .into(_database.foodIngredients)
          .insert(
            db.FoodIngredientsCompanion.insert(
              foodId: foodId,
              ingredientId: component.ingredientId,
              amount: component.amount,
            ),
          );
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Resolves a batch of foods with three queries total: the foods are already
  /// loaded, so this batches their composition rows and the ingredients those
  /// reference.
  Future<List<ResolvedFood>> _resolveAll(List<db.Food> rows) async {
    if (rows.isEmpty) return [];
    final foodIds = [for (final row in rows) row.id];

    final componentRows = await (_database.select(
      _database.foodIngredients,
    )..where((t) => t.foodId.isIn(foodIds))).get();
    final ingredients = await _ingredientsById([
      for (final row in componentRows) row.ingredientId,
    ]);

    // Alphabetical within each food, matching `getComponents`.
    final byFood = <String, List<FoodIngredient>>{};
    for (final row in componentRows) {
      final ingredient = ingredients[row.ingredientId];
      if (ingredient == null) continue;
      byFood
          .putIfAbsent(row.foodId, () => [])
          .add(
            FoodIngredient(
              foodId: row.foodId,
              ingredientId: row.ingredientId,
              ingredientName: ingredient.name,
              amount: row.amount,
            ),
          );
    }
    for (final components in byFood.values) {
      components.sort((a, b) => a.ingredientName.compareTo(b.ingredientName));
    }

    return [
      for (final row in rows)
        (
          food: _foodToDomain(row, byFood[row.id] ?? const []),
          nutrition: _nutritionOf(byFood[row.id] ?? const [], ingredients),
        ),
    ];
  }

  FoodNutrition? _nutritionOf(
    List<FoodIngredient> components,
    Map<String, Ingredient> ingredients,
  ) {
    if (components.isEmpty) return null;
    final resolved = resolveFoodPer100g([
      for (final component in components)
        if (ingredients[component.ingredientId] case final ingredient?)
          component.toNutrition(ingredient),
    ]);
    return resolved.totalAmount <= 0 ? null : resolved;
  }

  Future<Map<String, Ingredient>> _ingredientsById(Iterable<String> ids) async {
    final unique = ids.toSet();
    if (unique.isEmpty) return const {};
    final rows = await (_database.select(
      _database.ingredients,
    )..where((t) => t.id.isIn(unique))).get();
    return {for (final row in rows) row.id: _ingredientToDomain(row)};
  }

  Food _foodToDomain(db.Food row, List<FoodIngredient> components) => Food(
    id: row.id,
    name: row.name,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    archivedAt: row.archivedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
    components: components,
  );

  Ingredient _ingredientToDomain(db.Ingredient row) => Ingredient(
    id: row.id,
    name: row.name,
    caloriesPer100g: row.caloriesPer100g,
    proteinPer100g: row.proteinPer100g,
    carbsPer100g: row.carbsPer100g,
    fatPer100g: row.fatPer100g,
    sodiumPer100g: row.sodiumPer100g,
    fiberPer100g: row.fiberPer100g,
    sugarPer100g: row.sugarPer100g,
    isArchived: row.isArchived,
    brand: row.brand,
    barcode: row.barcode,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

/// Creates a new user-created [Food] with a fresh UUID v7.
///
/// Auto-created 1:1 foods do not go through here — they are created by
/// `IngredientRepository` with [derivedFoodId].
Food newFood({required String name}) =>
    Food(id: const Uuid().v7(), name: name.trim(), createdAt: DateTime.now());

/// Builds a composition entry for [newFood]'s editor, before the food exists.
FoodIngredient newFoodIngredient({
  required String ingredientId,
  required String ingredientName,
  required double amount,
}) => FoodIngredient(
  foodId: '',
  ingredientId: ingredientId,
  ingredientName: ingredientName,
  amount: amount,
);
