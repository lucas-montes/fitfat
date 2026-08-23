import '../models/ingredient.dart';
import '../models/ingredient_picture.dart';
import '../models/ingredient_price.dart';
import '../models/store.dart';
import '../network/api_client.dart';
import '../diet/repositories/ingredient_repository.dart';
import 'sync_models.dart';

/// Pulls ingredients from the sync server: `GET /ingredients?since=<cursor>`
/// with a Bearer API key. Each item carries nested `pictures` and `prices`;
/// referenced `stores` arrive in a top-level array. Changed rows are upserted
/// (server authority) and deleted ids are soft-archived locally.
final class IngredientSyncClient {
  final ApiClient _api;
  final IngredientRepository _repo;

  const IngredientSyncClient(this._api, this._repo);

  static const _path = '/ingredients';

  Future<SyncResult> sync({required int since, required String apiKey}) async {
    try {
      final payload = await _api.getJson(
        _path,
        query: {'since': '$since'},
        headers: _auth(apiKey),
      );
      if (payload is! Map) {
        return const SyncResult(error: 'Unexpected ingredients payload');
      }
      final serverTime = (payload['server_time'] as num?)?.toInt() ?? since;

      final stores = payload['stores'];
      if (stores is List) {
        for (final s in stores) {
          if (s is! Map) continue;
          final id = s['id'];
          final name = s['name'];
          if (id is String && name is String) {
            await _repo.upsertStore(
              Store(
                id: id,
                name: name,
                createdAt: toSyncDateTime(s['updated_at'], serverTime),
              ),
            );
          }
        }
      }

      var updated = 0;
      final items = payload['items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          final ingredient = _parseIngredient(raw, serverTime);
          if (ingredient == null) continue;
          await _repo.upsert(ingredient);

          final pictures = raw['pictures'];
          if (pictures is List) {
            for (final p in pictures) {
              if (p is! Map) continue;
              final pid = p['id'];
              final iid = p['ingredientId'] ?? ingredient.id;
              if (pid is String && iid is String) {
                await _repo.upsertPicture(
                  IngredientPicture(
                    id: pid,
                    ingredientId: iid,
                    imagePath: p['imagePath'] as String? ?? '',
                    sortOrder: (p['sortOrder'] as num?)?.toInt() ?? 0,
                    createdAt: toSyncDateTime(p['updated_at'], serverTime),
                  ),
                );
              }
            }
          }

          final prices = raw['prices'];
          if (prices is List) {
            for (final pr in prices) {
              if (pr is! Map) continue;
              final pid = pr['id'];
              final storeId = pr['storeId'];
              final currencyCode = pr['currencyCode'];
              final price = pr['price'];
              if (pid is String &&
                  storeId is String &&
                  currencyCode is String &&
                  price is num) {
                await _repo.upsertPrice(
                  IngredientPrice(
                    id: pid,
                    ingredientId: ingredient.id,
                    storeId: storeId,
                    price: price.toDouble(),
                    currencyCode: currencyCode,
                    packageGrams: (pr['packageGrams'] as num?)?.toDouble(),
                    recordedAt: toSyncDateTime(pr['recorded_at'], serverTime),
                  ),
                );
              }
            }
          }
          updated++;
        }
      }

      var deleted = 0;
      final deletedRaw = payload['deleted'];
      if (deletedRaw is List) {
        for (final id in deletedRaw) {
          if (id is String) {
            await _repo.archive(id);
            deleted++;
          }
        }
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

  /// Contributes a local ingredient (with its pictures and prices) to the shared
  /// pool: `POST /ingredients` with a Bearer API key. Idempotent by ingredient
  /// id, so re-pushing the same ingredient is safe.
  Future<SyncResult> push({
    required Ingredient ingredient,
    required List<IngredientPicture> pictures,
    required List<IngredientPrice> prices,
    required String apiKey,
  }) async {
    try {
      await _api.postJson(
        _path,
        headers: _auth(apiKey),
        body: {
          'id': ingredient.id,
          'name': ingredient.name,
          'caloriesPer100g': ingredient.caloriesPer100g,
          'proteinPer100g': ingredient.proteinPer100g,
          'carbsPer100g': ingredient.carbsPer100g,
          'fatPer100g': ingredient.fatPer100g,
          'sodiumPer100g': ingredient.sodiumPer100g,
          'fiberPer100g': ingredient.fiberPer100g,
          'sugarPer100g': ingredient.sugarPer100g,
          'isArchived': ingredient.isArchived,
          'brand': ingredient.brand,
          'barcode': ingredient.barcode,
          'createdAt': ingredient.createdAt.millisecondsSinceEpoch,
          'pictures': [
            for (final p in pictures)
              {
                'id': p.id,
                'ingredientId': p.ingredientId,
                'imagePath': p.imagePath,
                'sortOrder': p.sortOrder,
                'createdAt': p.createdAt.millisecondsSinceEpoch,
              },
          ],
          'prices': [
            for (final pr in prices)
              {
                'id': pr.id,
                'ingredientId': pr.ingredientId,
                'storeId': pr.storeId,
                'price': pr.price,
                'currencyCode': pr.currencyCode,
                'packageGrams': pr.packageGrams,
                'recordedAt': pr.recordedAt.millisecondsSinceEpoch,
              },
          ],
        },
      );
      return const SyncResult();
    } on ApiException catch (e) {
      return SyncResult(error: 'Push failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  static Map<String, String> _auth(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
  };

  static Ingredient? _parseIngredient(
    Map<Object?, Object?> raw,
    int serverTime,
  ) {
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String) return null;
    return Ingredient(
      id: id,
      name: name,
      caloriesPer100g: (raw['caloriesPer100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (raw['proteinPer100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (raw['carbsPer100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (raw['fatPer100g'] as num?)?.toDouble() ?? 0,
      sodiumPer100g: (raw['sodiumPer100g'] as num?)?.toDouble(),
      fiberPer100g: (raw['fiberPer100g'] as num?)?.toDouble(),
      sugarPer100g: (raw['sugarPer100g'] as num?)?.toDouble(),
      isArchived: (raw['isArchived'] as bool?) ?? false,
      brand: raw['brand'] as String?,
      barcode: raw['barcode'] as String?,
      createdAt: toSyncDateTime(
        raw['updated_at'] ?? raw['created_at'],
        serverTime,
      ),
    );
  }
}
