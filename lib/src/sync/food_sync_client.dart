import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../models/food.dart';
import '../network/api_client.dart';

import 'sync_models.dart';
import 'sync_state_store.dart';

/// Pulls and pushes **user-created foods** (recipes) against the shared
/// catalogue: `GET /foods?since=<cursor>` and `POST /foods`, both with a Bearer
/// API key.
///
/// Two things it deliberately does **not** carry:
///
///  * **Derived foods.** The auto-created 1:1 wrapper every ingredient has is
///    fully reconstructible from that ingredient, so pushing one is pure noise —
///    and on a receiving device it would collide with the local auto-creation.
///    [isDerived] discriminates with no query.
///  * **Nutrition.** Foods carry no macros; they resolve live from their
///    ingredients. A pulled recipe's numbers therefore follow the ingredients
///    the receiving device already has.
final class FoodSyncClient {
  final ApiClient _api;
  final db.AppDatabase _database;
  final SyncStateStore _state;

  FoodSyncClient(this._api, this._database, this._state);

  static const _path = '/foods';

  static Map<String, String> authHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
  };

  /// Pulls recipes changed since the stored cursor and applies them.
  ///
  /// **Must run after the ingredient sync.** A recipe's composition references
  /// ingredients by id, and the two resources have independent cursors, so a
  /// recipe can arrive before the parts it needs. Composition rows whose
  /// ingredient is still missing are skipped rather than failing the row — the
  /// recipe lands and becomes resolvable once the ingredient catches up.
  ///
  /// [resolveMissingIngredientIds] is invoked with the ingredient ids a pulled
  /// recipe needs but does not have, so the caller can import them from the
  /// catalogue before the recipe is applied.
  Future<SyncResult> sync({
    required String apiKey,
    String endpoint = _path,
    Future<void> Function(Set<String> ids)? resolveMissingIngredientIds,
  }) async {
    final since = _state.getLastSyncedAt(SyncResource.foods);
    try {
      final payload = await _api.getJson(
        endpoint,
        query: {'since': '$since'},
        headers: authHeaders(apiKey),
      );
      if (payload is! Map) {
        return const SyncResult(error: 'Unexpected foods payload');
      }
      final serverTime = (payload['server_time'] as num?)?.toInt() ?? since;
      final items = payload['items'];

      var updated = 0;
      if (items is List) {
        // One pass to collect every ingredient id the pulled recipes reference,
        // then resolve what we are missing *before* applying, so a recipe is
        // never stored in a half-resolvable state.
        var present = await _presentIngredientIds();
        final parsed = [
          for (final raw in items)
            if (parseFood(raw, serverTime) case final entry?) entry,
        ];
        final needed = {
          for (final entry in parsed)
            for (final c in entry.components) c.ingredientId,
        };
        final missing = needed.difference(present);

        if (missing.isNotEmpty && resolveMissingIngredientIds != null) {
          await resolveMissingIngredientIds(missing);
          present = await _presentIngredientIds();
        }

        for (final entry in parsed) {
          // Derived ids are never accepted from the wire — they belong to the
          // local ingredient, which manages them itself.
          if (isDerivedFoodId(entry.food.id)) continue;
          await _apply(entry.food, [
            for (final c in entry.components)
              if (present.contains(c.ingredientId)) c,
          ]);
          updated++;
        }
      }

      final deletedRaw = payload['deleted'];
      var deleted = 0;
      if (deletedRaw is List) {
        for (final id in deletedRaw) {
          if (id is! String || isDerivedFoodId(id)) continue;
          // Archived rather than deleted: `meal_foods` references the food, and
          // a logged meal's snapshot must keep rendering. Leaving the picker is
          // all a tombstone needs to mean.
          await (_database.update(_database.foods)
                ..where((t) => t.id.equals(id)))
              .write(db.FoodsCompanion(archivedAt: Value(serverTime)));
          deleted++;
        }
      }

      if (serverTime > 0) {
        await _state.setLastSyncedAt(SyncResource.foods, serverTime);
      }
      return SyncResult(
        updated: updated,
        deleted: deleted,
        serverTime: serverTime,
      );
    } on ApiException catch (e) {
      return SyncResult(error: 'Sync failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  /// Contributes local recipes to the shared pool.
  ///
  /// Takes the already-filtered list so the caller decides what is shareable —
  /// [FoodSyncClient.shareable] is that decision.
  Future<SyncResult> push({
    required List<Food> foods,
    required List<List<FoodIngredient>> componentsByFoodId,
    required String apiKey,
    String endpoint = _path,
  }) async {
    if (foods.isEmpty) return const SyncResult();
    try {
      final rows = <Map<String, Object?>>[];
      for (var i = 0; i < foods.length; i++) {
        rows.add({
          'id': foods[i].id,
          'name': foods[i].name,
          'createdAt': foods[i].createdAt.millisecondsSinceEpoch,
          'archivedAt': foods[i].archivedAt?.millisecondsSinceEpoch,
          'components': [
            for (final c in componentsByFoodId[i])
              {'ingredientId': c.ingredientId, 'amount': c.amount},
          ],
        });
      }
      await _api.postJson(
        endpoint,
        headers: authHeaders(apiKey),
        body: {'items': rows},
      );
      return SyncResult(updated: foods.length);
    } on ApiException catch (e) {
      return SyncResult(error: 'Push failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  /// The foods worth pushing: user-created ones only.
  ///
  /// Derived wrappers are excluded — see the class doc.
  static List<Food> shareable(Iterable<Food> foods) => [
    for (final food in foods)
      if (!food.isDerived) food,
  ];

  Future<void> _apply(Food food, List<FoodIngredient> components) async {
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
      await (_database.delete(
        _database.foodIngredients,
      )..where((t) => t.foodId.equals(food.id))).go();
      for (final component in components) {
        await _database
            .into(_database.foodIngredients)
            .insert(
              db.FoodIngredientsCompanion.insert(
                foodId: food.id,
                ingredientId: component.ingredientId,
                amount: component.amount,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<Set<String>> _presentIngredientIds() async {
    final rows = await _database.select(_database.ingredients).get();
    return {for (final row in rows) row.id};
  }

  /// Parses one `items[]` entry. `id` and `name` are required; composition
  /// entries need an `ingredientId` and a positive `amount`.
  static ({Food food, List<FoodIngredient> components})? parseFood(
    Object? raw,
    int serverTime,
  ) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String) return null;

    final components = <FoodIngredient>[];
    final rawComponents = raw['components'];
    if (rawComponents is List) {
      for (final c in rawComponents) {
        if (c is! Map) continue;
        final ingredientId = c['ingredientId'];
        final amount = c['amount'];
        if (ingredientId is! String || ingredientId.isEmpty) continue;
        if (amount is! num || amount <= 0) continue;
        components.add(
          FoodIngredient(
            foodId: id,
            ingredientId: ingredientId,
            // Resolved by the repository on read.
            ingredientName: '',
            amount: amount.toDouble(),
          ),
        );
      }
    }

    return (
      food: Food(
        id: id,
        name: name,
        createdAt: toSyncDateTime(raw['createdAt'], serverTime),
        archivedAt: switch (raw['archivedAt']) {
          final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
          _ => null,
        },
        components: components,
      ),
      components: components,
    );
  }
}
