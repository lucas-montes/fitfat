import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/meal_entry.dart';
import '../../models/meal_food.dart';
import '../services/food_nutrition.dart';

/// A food to log, before it becomes a `meal_foods` row.
///
/// [nutrition] must be the food's **live** per-100g profile at the moment of
/// logging — the repository scales it to [amount] and writes the result as the
/// portion snapshot. Passing it in keeps this class free of a FoodRepository
/// dependency and lets a caller batch-resolve every food's nutrition once.
typedef MealFoodDraft = ({
  String foodId,
  String foodName,
  double amount,
  FoodNutrition? nutrition,
});

final class MealRepository {
  final db.AppDatabase _database;
  const MealRepository(this._database);

  /// Load all meals with their logged foods, newest first.
  ///
  /// **Three queries for the entire history**, independent of meal count —
  /// replacing the previous per-meal `meal_ingredients` + `ingredients` pair
  /// (N+1). The macros come from each row's snapshot, so the ingredient graph
  /// is not touched at all.
  Future<List<MealEntry>> getAll() async {
    final mealRows =
        await (_database.select(_database.meals)..orderBy([
              (t) =>
                  OrderingTerm(expression: t.eatenAt, mode: OrderingMode.desc),
            ]))
            .get();
    if (mealRows.isEmpty) return const [];

    final mealIds = [for (final row in mealRows) row.id];
    final foodRows = await (_database.select(
      _database.mealFoods,
    )..where((t) => t.mealId.isIn(mealIds))).get();
    // Food names stay live, so renaming a recipe updates past meals. A meal row
    // whose food has gone missing is skipped rather than fatal (the old code
    // asserted non-null here and crashed).
    final foodIds = {for (final row in foodRows) row.foodId}.toList();
    final nameRows = foodIds.isEmpty
        ? <db.Food>[]
        : await (_database.select(
            _database.foods,
          )..where((t) => t.id.isIn(foodIds))).get();
    final names = {for (final row in nameRows) row.id: row.name};

    final byMeal = <String, List<MealFood>>{};
    for (final row in foodRows) {
      final name = names[row.foodId];
      if (name == null) continue;
      byMeal
          .putIfAbsent(row.mealId, () => [])
          .add(
            MealFood(
              id: row.id,
              mealId: row.mealId,
              foodId: row.foodId,
              foodName: name,
              amount: row.amount,
              calories: row.calories,
              protein: row.protein,
              carbs: row.carbs,
              fat: row.fat,
              sodium: row.sodium,
              fiber: row.fiber,
              sugar: row.sugar,
            ),
          );
    }

    return [
      for (final row in mealRows)
        MealEntry(
          id: row.id,
          name: row.name,
          eatenAt: DateTime.fromMillisecondsSinceEpoch(row.eatenAt),
          createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
          items: byMeal[row.id] ?? const [],
        ),
    ];
  }

  /// Sums the logged nutrition over a time window, straight from the snapshots.
  ///
  /// One aggregate query — the dashboard's calorie and macro totals both come
  /// from here rather than each walking the whole history.
  Future<Nutrition> totalsBetween(DateTime from, DateTime to) async {
    final row = await _database
        .customSelect(
          'SELECT COALESCE(SUM(mf.calories), 0) AS calories, '
          'COALESCE(SUM(mf.protein), 0) AS protein, '
          'COALESCE(SUM(mf.carbs), 0) AS carbs, '
          'COALESCE(SUM(mf.fat), 0) AS fat, '
          'SUM(mf.sodium) AS sodium, SUM(mf.fiber) AS fiber, '
          'SUM(mf.sugar) AS sugar '
          'FROM meal_foods mf INNER JOIN meals m ON m.id = mf.meal_id '
          'WHERE m.eaten_at >= ?1 AND m.eaten_at < ?2',
          variables: [
            Variable<int>(from.millisecondsSinceEpoch),
            Variable<int>(to.millisecondsSinceEpoch),
          ],
          readsFrom: {_database.mealFoods, _database.meals},
        )
        .getSingle();
    return (
      calories: row.read<double>('calories'),
      protein: row.read<double>('protein'),
      carbs: row.read<double>('carbs'),
      fat: row.read<double>('fat'),
      sodium: row.readNullable<double>('sodium'),
      fiber: row.readNullable<double>('fiber'),
      sugar: row.readNullable<double>('sugar'),
    );
  }

  /// Inserts a meal and its logged foods, snapshotting each portion.
  ///
  /// Throws [ArgumentError] when a draft's nutrition is null — a food whose
  /// composition cannot be resolved would record a zero-calorie meal, so the
  /// log is refused instead.
  Future<void> insert(MealEntry meal) async {
    final snapshots = _snapshotAll(meal.items);
    await _database.transaction(() async {
      await _database
          .into(_database.meals)
          .insert(
            db.MealsCompanion.insert(
              id: meal.id,
              name: meal.name,
              eatenAt: meal.eatenAt.millisecondsSinceEpoch,
              createdAt: meal.createdAt.millisecondsSinceEpoch,
            ),
          );
      for (var i = 0; i < meal.items.length; i++) {
        final row = snapshots[i];
        await _database
            .into(_database.mealFoods)
            .insert(
              db.MealFoodsCompanion.insert(
                id: meal.items[i].id,
                mealId: meal.items[i].mealId,
                foodId: meal.items[i].foodId,
                amount: meal.items[i].amount,
                calories: row.calories,
                protein: row.protein,
                carbs: row.carbs,
                fat: row.fat,
                sodium: Value(row.sodium),
                fiber: Value(row.fiber),
                sugar: Value(row.sugar),
              ),
            );
      }
    });
  }

  /// Replaces a meal's foods.
  ///
  /// Callers pass items whose macros already reflect the current composition of
  /// their foods, so every save re-snapshots rather than rescaling — an ingredient
  /// edit is picked up the next time a meal is edited.
  Future<void> update(MealEntry meal) async {
    final snapshots = _snapshotAll(meal.items);
    await _database.transaction(() async {
      await (_database.update(
        _database.meals,
      )..where((t) => t.id.equals(meal.id))).write(
        db.MealsCompanion(
          name: Value(meal.name),
          eatenAt: Value(meal.eatenAt.millisecondsSinceEpoch),
        ),
      );
      await (_database.delete(
        _database.mealFoods,
      )..where((t) => t.mealId.equals(meal.id))).go();
      for (var i = 0; i < meal.items.length; i++) {
        final row = snapshots[i];
        await _database
            .into(_database.mealFoods)
            .insert(
              db.MealFoodsCompanion.insert(
                id: meal.items[i].id,
                mealId: meal.items[i].mealId,
                foodId: meal.items[i].foodId,
                amount: meal.items[i].amount,
                calories: row.calories,
                protein: row.protein,
                carbs: row.carbs,
                fat: row.fat,
                sodium: Value(row.sodium),
                fiber: Value(row.fiber),
                sugar: Value(row.sugar),
              ),
            );
      }
    });
  }

  /// Rescales only the logged amounts of an existing meal, leaving its
  /// nutrition snapshots untouched.
  ///
  /// The derivation is linear in the amount, so this is exact — and it means
  /// adjusting a portion from 150 g to 200 g cannot silently rewrite history the
  /// way a full re-snapshot would if the food changed in between. Use [update]
  /// when the foods themselves were edited.
  Future<void> updateAmounts(
    String mealId,
    Map<String, double> amountsByFoodRowId,
  ) async {
    final rows = await (_database.select(
      _database.mealFoods,
    )..where((t) => t.mealId.equals(mealId))).get();
    await _database.transaction(() async {
      for (final row in rows) {
        final next = amountsByFoodRowId[row.id];
        if (next == null || next == row.amount) continue;
        final factor = row.amount <= 0 ? 0.0 : next / row.amount;
        await (_database.update(
          _database.mealFoods,
        )..where((t) => t.id.equals(row.id))).write(
          db.MealFoodsCompanion(
            amount: Value(next),
            calories: Value(row.calories * factor),
            protein: Value(row.protein * factor),
            carbs: Value(row.carbs * factor),
            fat: Value(row.fat * factor),
            sodium: Value(row.sodium == null ? null : row.sodium! * factor),
            fiber: Value(row.fiber == null ? null : row.fiber! * factor),
            sugar: Value(row.sugar == null ? null : row.sugar! * factor),
          ),
        );
      }
    });
  }

  Future<void> delete(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.mealFoods,
      )..where((t) => t.mealId.equals(id))).go();
      await (_database.delete(
        _database.meals,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  /// Re-inserts a previously deleted [meal] with all its items and their
  /// original ids — the undo path for delete. Shares the create path so the
  /// create and restore flows stay consistent, and so the snapshots are
  /// re-verified against the current composition on the way back in.
  Future<void> restore(MealEntry meal) => insert(meal);

  /// Scales every item's live per-100g profile to the logged amount.
  Nutrition _portionFor(MealFood item) {
    final nutrition = item.nutrition;
    if (nutrition == null || nutrition.totalAmount <= 0) {
      throw ArgumentError(
        'Cannot log "${item.foodName}": its nutrition could not be resolved.',
      );
    }
    if (item.amount <= 0) {
      throw ArgumentError(
        'Cannot log "${item.foodName}": the amount must be greater than 0.',
      );
    }
    return scaleToAmount(nutrition.per100g, item.amount);
  }

  List<Nutrition> _snapshotAll(List<MealFood> items) => [
    for (final item in items) _portionFor(item),
  ];
}

/// Creates a new [MealEntry] with a fresh UUID v7 and the current timestamp.
///
/// The generated meal id is stamped onto every item so the inserted `meal_foods`
/// rows reference the real meal (fixes the pre-T02 empty-meal_id bug where items
/// kept `mealId: ''` and never loaded back).
MealEntry newMeal({
  required String name,
  required DateTime eatenAt,
  required List<MealFoodDraft> foods,
}) {
  final id = const Uuid().v7();
  return MealEntry(
    id: id,
    name: name,
    eatenAt: eatenAt,
    createdAt: DateTime.now(),
    items: [
      for (final draft in foods)
        MealFood(
          id: const Uuid().v7(),
          mealId: id,
          foodId: draft.foodId,
          foodName: draft.foodName,
          amount: draft.amount,
          // Zeroes are a placeholder only — the repository overwrites these with
          // the resolved snapshot on insert, and refuses the log if it cannot.
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          sodium: draft.nutrition?.per100g.sodium,
          fiber: draft.nutrition?.per100g.fiber,
          sugar: draft.nutrition?.per100g.sugar,
          // Carried through so the repository can snapshot from it.
          nutrition: draft.nutrition,
        ),
    ],
  );
}
