import '../diet/repositories/ingredient_repository.dart';
import '../exercise/repositories/exercise_repository.dart';
import '../network/api_client.dart';
import 'exercise_sync_client.dart';
import 'ingredient_sync_client.dart';
import 'repositories/catalog_repository.dart';
import 'sync_models.dart';

/// Thin selective-sync engine: catalog refresh (background, cache-only) and
/// per-id selective import. Never touches [SyncStateStore] cursors and never
/// applies server `deleted[]` — deletions stay local-only.
///
/// Catalog endpoints serve minimal rows (`exercises: id/name`,
/// `ingredients: id/name/barcode`); item endpoints serve the selective shapes
/// the bulk clients already parse (`ExerciseSyncClient.importItem`,
/// `IngredientSyncClient.upsertAggregate`). Picker thumbnails are live server
/// fetches; offline assets are downloaded only by the import path below.
final class CatalogSyncClient {
  CatalogSyncClient(
    this._api,
    this._exerciseCatalog,
    this._ingredientCatalog,
    this._exercises,
    this._ingredients,
  );

  final ApiClient _api;
  final ExerciseCatalogRepository _exerciseCatalog;
  final IngredientCatalogRepository _ingredientCatalog;
  final ExerciseRepository _exercises;
  final IngredientRepository _ingredients;

  static const exerciseCatalogPath = '/exercises/catalog';
  static const ingredientCatalogPath = '/ingredients/catalog';

  /// Fetches the minimal exercise catalog and replaces the local cache.
  /// Returns the number of rows cached. Touches catalog tables only.
  Future<int> refreshExercises({
    required String apiKey,
    String endpoint = exerciseCatalogPath,
  }) async {
    final payload = await _api.getJson(endpoint, headers: authHeaders(apiKey));
    if (payload is! Map) throw StateError('Unexpected exercise catalog payload');
    final entries = <ExerciseCatalogEntry>[];
    final items = payload['items'];
    if (items is List) {
      for (final raw in items) {
        if (raw is! Map) continue;
        final id = raw['id'];
        final name = raw['name'];
        if (id is String && name is String) {
          entries.add(
            ExerciseCatalogEntry(
              id: id,
              name: name,
              hasImage: raw['has_image'] == true,
            ),
          );
        }
      }
    }
    await _exerciseCatalog.upsertAll(entries);
    return entries.length;
  }

  /// Fetches the minimal ingredient catalog and replaces the local cache.
  Future<int> refreshIngredients({
    required String apiKey,
    String endpoint = ingredientCatalogPath,
  }) async {
    final payload = await _api.getJson(endpoint, headers: authHeaders(apiKey));
    if (payload is! Map) {
      throw StateError('Unexpected ingredient catalog payload');
    }
    final entries = <IngredientCatalogEntry>[];
    final items = payload['items'];
    if (items is List) {
      for (final raw in items) {
        if (raw is! Map) continue;
        final id = raw['id'];
        final name = raw['name'];
        if (id is String && name is String) {
          entries.add(
            IngredientCatalogEntry(
              id: id,
              name: name,
              barcode: raw['barcode'] as String?,
            ),
          );
        }
      }
    }
    await _ingredientCatalog.upsertAll(entries);
    return entries.length;
  }

  /// Imports exactly [ids] via per-id fetch → upsert + media download for
  /// offline. A `404` id is skipped (gone server-side; the local row, if any,
  /// stays — deletions are local-only). Any other failure aborts with
  /// `SyncResult.error`; no cursor is advanced either way.
  Future<SyncResult> importExercises({
    required Set<String> ids,
    required String apiKey,
    String endpoint = '/exercises',
  }) async {
    final client = ExerciseSyncClient(_api, _exercises);
    final now = DateTime.now().millisecondsSinceEpoch;
    var updated = 0;
    var mediaFailed = false;
    for (final id in ids) {
      try {
        final raw = await _api.getJson(
          '$endpoint/item/$id',
          headers: authHeaders(apiKey),
        );
        if (raw is! Map) continue;
        final (imported, mediaOk) = await client.importItem(raw, now, apiKey);
        if (imported) updated++;
        if (!mediaOk) mediaFailed = true;
      } on ApiException catch (e) {
        if (e.statusCode == 404) continue;
        return SyncResult(error: 'Sync failed (HTTP ${e.statusCode})', updated: updated);
      } catch (e) {
        return SyncResult(error: e.toString(), updated: updated);
      }
    }
    if (mediaFailed) {
      return SyncResult(error: 'Exercise media download failed', updated: updated);
    }
    return SyncResult(updated: updated);
  }

  /// Imports exactly [ids] as minimal aggregates (image metadata + name +
  /// macros/nutriments + brand/barcode + pictures; no stores/prices).
  Future<SyncResult> importIngredients({
    required Set<String> ids,
    required String apiKey,
    String endpoint = '/ingredients',
  }) async {
    final client = IngredientSyncClient(_api, _ingredients);
    final now = DateTime.now().millisecondsSinceEpoch;
    var updated = 0;
    for (final id in ids) {
      try {
        final raw = await _api.getJson(
          '$endpoint/item/$id',
          headers: authHeaders(apiKey),
        );
        if (raw is! Map) continue;
        if (await client.upsertAggregate(raw, now)) updated++;
      } on ApiException catch (e) {
        if (e.statusCode == 404) continue;
        return SyncResult(error: 'Sync failed (HTTP ${e.statusCode})', updated: updated);
      } catch (e) {
        return SyncResult(error: e.toString(), updated: updated);
      }
    }
    return SyncResult(updated: updated);
  }
}
