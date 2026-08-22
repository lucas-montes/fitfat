import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/ingredient.dart';
import '../../models/ingredient_picture.dart';
import '../../models/ingredient_price.dart';
import '../../models/store.dart';

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
            brand: Value(ingredient.brand),
            barcode: Value(ingredient.barcode),
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
        brand: Value(ingredient.brand),
        barcode: Value(ingredient.barcode),
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

  // ---------------------------------------------------------------------------
  // Stores (v20)
  // ---------------------------------------------------------------------------

  Future<List<Store>> getStores() async {
    final rows = await (_database.select(
      _database.stores,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    return rows.map(_storeToDomain).toList();
  }

  Future<Store?> getStoreById(String id) async {
    final row = await (_database.select(
      _database.stores,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _storeToDomain(row);
  }

  Future<void> insertStore(Store store) async {
    await _database
        .into(_database.stores)
        .insert(
          db.StoresCompanion.insert(
            id: store.id,
            name: store.name,
            createdAt: store.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> updateStore(Store store) async {
    await (_database.update(_database.stores)
          ..where((t) => t.id.equals(store.id)))
        .write(db.StoresCompanion(name: Value(store.name)));
  }

  // ---------------------------------------------------------------------------
  // Pictures (v20)
  // ---------------------------------------------------------------------------

  Future<List<IngredientPicture>> getPictures(String ingredientId) async {
    final rows =
        await (_database.select(_database.ingredientPictures)
              ..where((t) => t.ingredientId.equals(ingredientId))
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    return rows.map(_pictureToDomain).toList();
  }

  Future<void> insertPicture(IngredientPicture picture) async {
    await _database
        .into(_database.ingredientPictures)
        .insert(
          db.IngredientPicturesCompanion.insert(
            id: picture.id,
            ingredientId: picture.ingredientId,
            imagePath: picture.imagePath,
            sortOrder: picture.sortOrder,
            createdAt: picture.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> deletePicture(String id) async {
    await (_database.delete(
      _database.ingredientPictures,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Rewrites `sort_order` densely (0..n-1) following [orderedIds].
  Future<void> reorderPictures(
    String ingredientId,
    List<String> orderedIds,
  ) async {
    await _database.batch((batch) {
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(
          _database.ingredientPictures,
          db.IngredientPicturesCompanion(sortOrder: Value(i)),
          where: (tbl) =>
              tbl.id.equals(orderedIds[i]) &
              tbl.ingredientId.equals(ingredientId),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Prices (v20)
  // ---------------------------------------------------------------------------

  /// Inserts a price row; re-recording for the same (ingredient, store, day)
  /// overwrites the existing observation instead of adding a duplicate.
  Future<void> upsertPrice(IngredientPrice price) async {
    await _database
        .into(_database.ingredientPrices)
        .insertOnConflictUpdate(
          db.IngredientPricesCompanion.insert(
            id: price.id,
            ingredientId: price.ingredientId,
            storeId: price.storeId,
            price: price.price,
            currencyCode: price.currencyCode,
            packageGrams: Value(price.packageGrams),
            recordedAt: price.recordedAt.millisecondsSinceEpoch,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> deletePrice(String id) async {
    await (_database.delete(
      _database.ingredientPrices,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Full price history for an ingredient (with its store), newest first.
  Future<List<(IngredientPrice, Store)>> getPrices(String ingredientId) async {
    final query =
        _database.select(_database.ingredientPrices).join([
            innerJoin(
              _database.stores,
              _database.stores.id.equalsExp(_database.ingredientPrices.storeId),
            ),
          ])
          ..where(_database.ingredientPrices.ingredientId.equals(ingredientId))
          ..orderBy([OrderingTerm.desc(_database.ingredientPrices.recordedAt)]);
    final rows = await query.get();
    return rows
        .map(
          (row) => (
            _priceToDomain(row.readTable(_database.ingredientPrices)),
            _storeToDomain(row.readTable(_database.stores)),
          ),
        )
        .toList();
  }

  /// The most recent price observation per store for an ingredient.
  Future<List<(IngredientPrice, Store)>> latestPricesPerStore(
    String ingredientId,
  ) async {
    final all = await getPrices(ingredientId);
    final seen = <String>{};
    return [
      for (final entry in all)
        if (seen.add(entry.$1.storeId)) entry,
    ];
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
    brand: row.brand,
    barcode: row.barcode,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  Store _storeToDomain(db.Store row) => Store(
    id: row.id,
    name: row.name,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  IngredientPicture _pictureToDomain(db.IngredientPicture row) =>
      IngredientPicture(
        id: row.id,
        ingredientId: row.ingredientId,
        imagePath: row.imagePath,
        sortOrder: row.sortOrder,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );

  IngredientPrice _priceToDomain(db.IngredientPrice row) => IngredientPrice(
    id: row.id,
    ingredientId: row.ingredientId,
    storeId: row.storeId,
    price: row.price,
    currencyCode: row.currencyCode,
    packageGrams: row.packageGrams,
    recordedAt: DateTime.fromMillisecondsSinceEpoch(row.recordedAt),
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
  String? brand,
  String? barcode,
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
  brand: brand?.trim().isEmpty == true ? null : brand?.trim(),
  barcode: barcode?.trim().isEmpty == true ? null : barcode?.trim(),
  createdAt: DateTime.now(),
);

/// Creates a new [Store] with a fresh UUID v7 and the current timestamp.
Store newStore({required String name}) =>
    Store(id: const Uuid().v7(), name: name.trim(), createdAt: DateTime.now());

/// Creates a new [IngredientPicture] with a fresh UUID v7.
IngredientPicture newIngredientPicture({
  required String ingredientId,
  required String imagePath,
  required int sortOrder,
}) => IngredientPicture(
  id: const Uuid().v7(),
  ingredientId: ingredientId,
  imagePath: imagePath,
  sortOrder: sortOrder,
  createdAt: DateTime.now(),
);

/// Creates a new [IngredientPrice] with a fresh UUID v7.
IngredientPrice newIngredientPrice({
  required String ingredientId,
  required String storeId,
  required double price,
  required String currencyCode,
  required DateTime recordedAt,
  double? packageGrams,
}) => IngredientPrice(
  id: const Uuid().v7(),
  ingredientId: ingredientId,
  storeId: storeId,
  price: price,
  currencyCode: currencyCode,
  packageGrams: packageGrams,
  recordedAt: recordedAt,
);
