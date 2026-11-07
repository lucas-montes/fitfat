import '../budget/repositories/fx_repository.dart';
import '../network/api_client.dart';
import 'sync_models.dart';

/// Pulls currency/FX rates from the sync server: GET /fx-rates?base=BASE&
/// date=DATE with a Bearer API key. Each returned rate is upserted into the
/// local `fx_rates` daily snapshot (preserving any hand-edited manual flag for
/// that day). The server returns the rates for the requested day only.
final class CurrencySyncClient {
  final ApiClient _api;
  final FxRepository _repo;

  const CurrencySyncClient(this._api, this._repo);

  static const _path = '/fx-rates';

  Future<SyncResult> sync({
    required int since,
    required String apiKey,
    required String baseCode,
    required String date,
    String endpoint = _path,
  }) async {
    try {
      final payload = await _api.getJson(
        endpoint,
        query: {'since': '$since', 'base': baseCode, 'date': date},
        headers: _auth(apiKey),
      );
      if (payload is! Map) {
        return const SyncResult(error: 'Unexpected currencies payload');
      }
      final serverTime = (payload['server_time'] as num?)?.toInt() ?? since;

      var updated = 0;
      final items = payload['items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          final code = raw['code'];
          final rate = raw['rateToBase'];
          if (code is String && rate is num) {
            final rateDate = raw['date'] as String? ?? date;
            await _repo.upsertRate(
              FxRateEntry(
                code: code,
                rateToBase: rate.toDouble(),
                updatedAt: toSyncDateTime(raw['updated_at'], serverTime),
                baseCode: baseCode,
                manual: false,
                rateDate: rateDate,
              ),
            );
            updated++;
          }
        }
      }

      return SyncResult(updated: updated, serverTime: serverTime);
    } on ApiException catch (e) {
      return SyncResult(error: 'Sync failed (HTTP ${e.statusCode})');
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  static Map<String, String> _auth(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
  };
}
