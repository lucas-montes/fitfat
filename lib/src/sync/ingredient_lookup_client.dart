import '../network/api_client.dart';

enum LookupSource { local, openfoodfacts, none }

final class IngredientLookupResult {
  const IngredientLookupResult({
    required this.source,
    required this.barcode,
    required this.openfoodUrl,
    this.item,
    this.draft,
  });

  final LookupSource source;
  final String barcode;
  final String openfoodUrl;
  final Map<String, Object?>? item;
  final Map<String, Object?>? draft;

  static IngredientLookupResult fromJson(Map<Object?, Object?> json) {
    final source = switch (json['source']) {
      'local' => LookupSource.local,
      'openfoodfacts' => LookupSource.openfoodfacts,
      _ => LookupSource.none,
    };
    Map<String, Object?>? mapOf(Object? v) =>
        v is Map ? v.cast<String, Object?>() : null;
    return IngredientLookupResult(
      source: source,
      barcode: json['barcode'] as String? ?? '',
      openfoodUrl: json['openfoodUrl'] as String? ?? '',
      item: mapOf(json['ingredient'] ?? json['item']),
      draft: mapOf(json['draft']),
    );
  }
}

final class IngredientLookupClient {
  IngredientLookupClient(this._api);
  final ApiClient _api;

  static const lookupPath = '/ingredients/lookup';
  static const importPath = '/ingredients/import-from-barcode';

  Future<IngredientLookupResult> lookup({
    required String barcode,
    required String apiKey,
  }) async {
    final payload = await _api.getJson(
      lookupPath,
      query: {'barcode': barcode},
      headers: authHeaders(apiKey),
    );
    if (payload is! Map) throw StateError('Unexpected lookup payload');
    return IngredientLookupResult.fromJson(payload.cast<Object?, Object?>());
  }

  Future<Map<String, Object?>> importFromBarcode({
    required String barcode,
    required String apiKey,
  }) async {
    final payload = await _api.postJson(
      importPath,
      headers: authHeaders(apiKey),
      body: {'barcode': barcode},
    );
    if (payload is! Map) throw StateError('Unexpected import payload');
    return payload.cast<String, Object?>();
  }
}
