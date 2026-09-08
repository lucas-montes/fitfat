import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../budget/providers/fx_rates.dart';
import '../budget/repositories/fx_repository.dart';
import '../models/ingredient.dart';
import '../models/ingredient_picture.dart';
import '../models/ingredient_price.dart';
import '../diet/providers/ingredients.dart';
import '../diet/repositories/ingredient_repository.dart';
import '../exercise/providers/exercises.dart';
import '../exercise/repositories/exercise_repository.dart';
import '../network/api_client.dart';
import '../settings/providers/settings.dart';
import 'currency_sync_client.dart';
import 'exercise_sync_client.dart';
import 'ingredient_sync_client.dart';
import 'sync_models.dart';
import 'sync_state_store.dart';

/// Orchestrates a pull for each resource: reads the last `since` cursor, builds
/// an [ApiClient] from the configured server URL, runs the matching client, and
/// persists the new cursor on success. Keeping the cursor means subsequent
/// syncs only request changes since the last successful pull.
final class SyncService {
  final ExerciseRepository exercises;
  final IngredientRepository ingredients;
  final FxRepository currencies;
  final SyncStateStore state;
  static final _log = Logger('SyncService');

  const SyncService({
    required this.exercises,
    required this.ingredients,
    required this.currencies,
    required this.state,
  });

  Future<SyncResult> syncExercises(
    String baseUrl,
    String apiKey, {
    String endpoint = '/exercises',
    Duration? timeout,
  }) async {
    final since = state.getLastSyncedAt(SyncResource.exercises);
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final httpClient = http.Client();
    final client = HttpApiClient(httpClient, baseUrl: normalizedBase, timeout: timeout ?? const Duration(seconds: 15));
    try {
      _log.info('syncExercises since=$since base=$normalizedBase endpoint=$endpoint timeout=${timeout?.inSeconds ?? 15}s');
      final result = await ExerciseSyncClient(
        client,
        exercises,
      ).sync(since: since, apiKey: apiKey, endpoint: endpoint);
      if (!result.ok) _log.warning('syncExercises failed: ${result.error} base=$normalizedBase endpoint=$endpoint');
      else _log.info('syncExercises ok updated=${result.updated} deleted=${result.deleted} serverTime=${result.serverTime}');
      if (result.ok && result.serverTime > 0) {
        await state.setLastSyncedAt(SyncResource.exercises, result.serverTime);
      }
      return result;
    } catch (e, st) {
      _log.severe('syncExercises exception base=$normalizedBase endpoint=$endpoint', e, st);
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  Future<SyncResult> syncIngredients(
    String baseUrl,
    String apiKey, {
    String endpoint = '/ingredients',
    Duration? timeout,
  }) async {
    final since = state.getLastSyncedAt(SyncResource.ingredients);
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final httpClient = http.Client();
    final client = HttpApiClient(httpClient, baseUrl: normalizedBase, timeout: timeout ?? const Duration(seconds: 15));
    try {
      _log.info('syncIngredients since=$since base=$normalizedBase endpoint=$endpoint timeout=${timeout?.inSeconds ?? 15}s');
      final result = await IngredientSyncClient(
        client,
        ingredients,
      ).sync(since: since, apiKey: apiKey, endpoint: endpoint);
      if (!result.ok) _log.warning('syncIngredients failed: ${result.error} base=$normalizedBase endpoint=$endpoint');
      else _log.info('syncIngredients ok updated=${result.updated} deleted=${result.deleted} serverTime=${result.serverTime}');
      if (result.ok && result.serverTime > 0) {
        await state.setLastSyncedAt(SyncResource.ingredients, result.serverTime);
      }
      return result;
    } catch (e, st) {
      _log.severe('syncIngredients exception base=$normalizedBase endpoint=$endpoint', e, st);
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  Future<SyncResult> syncCurrencies(
    String baseUrl,
    String apiKey,
    String baseCode, {
    String endpoint = '/fx-rates',
    Duration? timeout,
  }) async {
    final since = state.getLastSyncedAt(SyncResource.currencies);
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final httpClient = http.Client();
    final client = HttpApiClient(httpClient, baseUrl: normalizedBase, timeout: timeout ?? const Duration(seconds: 15));
    try {
      _log.info('syncCurrencies since=$since base=$normalizedBase endpoint=$endpoint baseCode=$baseCode timeout=${timeout?.inSeconds ?? 15}s');
      final result = await CurrencySyncClient(
        client,
        currencies,
      ).sync(
        since: since,
        apiKey: apiKey,
        baseCode: baseCode,
        date: _today(),
        endpoint: endpoint,
      );
      if (!result.ok) _log.warning('syncCurrencies failed: ${result.error} base=$normalizedBase endpoint=$endpoint');
      else _log.info('syncCurrencies ok updated=${result.updated} serverTime=${result.serverTime}');
      if (result.ok && result.serverTime > 0) {
        await state.setLastSyncedAt(SyncResource.currencies, result.serverTime);
      }
      return result;
    } catch (e, st) {
      _log.severe('syncCurrencies exception base=$normalizedBase endpoint=$endpoint', e, st);
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Contributes the given ingredient (with its pictures and prices) to the
  /// shared catalogue hosted at [baseUrl]. Idempotent by ingredient id.
  Future<SyncResult> pushIngredient({
    required String baseUrl,
    required String apiKey,
    required Ingredient ingredient,
    required List<IngredientPicture> pictures,
    required List<IngredientPrice> prices,
    Duration? timeout,
  }) async {
    final normalizedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final httpClient = http.Client();
    final client = HttpApiClient(httpClient, baseUrl: normalizedBase, timeout: timeout ?? const Duration(seconds: 15));
    try {
      _log.info('pushIngredient id=${ingredient.id} base=$normalizedBase endpoint=/ingredients');
      final res = await IngredientSyncClient(client, ingredients).push(
        ingredient: ingredient,
        pictures: pictures,
        prices: prices,
        apiKey: apiKey,
      );
      if (!res.ok) _log.warning('pushIngredient failed: ${res.error}');
      else _log.info('pushIngredient ok');
      return res;
    } catch (e, st) {
      _log.severe('pushIngredient exception base=$normalizedBase', e, st);
      rethrow;
    } finally {
      httpClient.close();
    }
  }
}

/// Today's date as 'YYYY-MM-DD', matching the `date` query the currencies sync
/// sends to the server.
String _today() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    exercises: ref.watch(exerciseRepositoryProvider),
    ingredients: ref.watch(ingredientRepositoryProvider),
    currencies: ref.watch(fxRepositoryProvider),
    state: SyncStateStore(ref.watch(sharedPreferencesProvider)),
  );
});
