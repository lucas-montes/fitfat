import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/ingredient.dart';

final class IngredientRepository {
  final db.AppDatabase _database;
  const IngredientRepository(this._database);

  Future<List<Ingredient>> getAll() async {
    final rows = await (_database.select(
      _database.ingredients,
    )..where((t) => t.isArchived.equals(false))).get();
    return rows.map(_toDomain).toList();
  }

  Future<Ingredient?> getById(String id) async {
    final row = await (_database.select(
      _database.ingredients,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<void> insert(Ingredient ingredient) async {
    await _database
        .into(_database.ingredients)
        .insert(
          db.IngredientsCompanion.insert(
            id: ingredient.id,
            name: ingredient.name,
            caloriesPer100g: ingredient.caloriesPer100g,
            proteinPer100g: ingredient.proteinPer100g,
            carbsPer100g: ingredient.carbsPer100g,
            fatPer100g: ingredient.fatPer100g,
            sodiumPer100g: Value(ingredient.sodiumPer100g),
            fiberPer100g: Value(ingredient.fiberPer100g),
            sugarPer100g: Value(ingredient.sugarPer100g),
            createdAt: ingredient.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(Ingredient ingredient) async {
    await (_database.update(
      _database.ingredients,
    )..where((t) => t.id.equals(ingredient.id))).write(
      db.IngredientsCompanion(
        name: Value(ingredient.name),
        caloriesPer100g: Value(ingredient.caloriesPer100g),
        proteinPer100g: Value(ingredient.proteinPer100g),
        carbsPer100g: Value(ingredient.carbsPer100g),
        fatPer100g: Value(ingredient.fatPer100g),
        sodiumPer100g: Value(ingredient.sodiumPer100g),
        fiberPer100g: Value(ingredient.fiberPer100g),
        sugarPer100g: Value(ingredient.sugarPer100g),
      ),
    );
  }

  /// Soft-delete: hidden from list/picker via the `isArchived` flag. The row
  /// stays so past meals keep rendering the ingredient name and macros.
  Future<void> archive(String id) async {
    await (_database.update(_database.ingredients)
          ..where((t) => t.id.equals(id)))
        .write(db.IngredientsCompanion(isArchived: const Value(true)));
  }

  /// Undo of [archive]: clears the flag so the ingredient reappears.
  Future<void> restore(String id) async {
    await (_database.update(_database.ingredients)
          ..where((t) => t.id.equals(id)))
        .write(db.IngredientsCompanion(isArchived: const Value(false)));
  }

  Ingredient _toDomain(db.Ingredient row) => Ingredient(
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
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

/// Creates a new [Ingredient] with a fresh UUID v7 and the current timestamp.
Ingredient newIngredient({
  required String name,
  required double caloriesPer100g,
  required double proteinPer100g,
  required double carbsPer100g,
  required double fatPer100g,
  double? sodiumPer100g,
  double? fiberPer100g,
  double? sugarPer100g,
}) => Ingredient(
  id: const Uuid().v7(),
  name: name,
  caloriesPer100g: caloriesPer100g,
  proteinPer100g: proteinPer100g,
  carbsPer100g: carbsPer100g,
  fatPer100g: fatPer100g,
  sodiumPer100g: sodiumPer100g,
  fiberPer100g: fiberPer100g,
  sugarPer100g: sugarPer100g,
  createdAt: DateTime.now(),
);
