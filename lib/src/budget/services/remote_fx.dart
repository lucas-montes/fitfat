import 'dart:async';

import '../../network/api_client.dart';

/// Abstraction over a remote FX-rates backend. Returns rates from every
/// supported non-base currency to [base]. Swapped for a real implementation
/// later via the provider; the app caches results locally in `fx_rates`.
abstract class RemoteFxService {
  Future<Map<String, double>> fetchRates(String base);
}

/// Compile-time FX endpoint base URL. Intentionally unset until a provider is
/// chosen ("other/later") — set via `--dart-define=FX_API_BASE_URL=...`.
const fxRatesApiBaseUrl = String.fromEnvironment(
  'FX_API_BASE_URL',
  defaultValue: '',
);

/// Real [RemoteFxService] backed by [ApiClient]. Expects the endpoint to
/// return `{"base": "<base>", "rates": {"<CODE>": rate, ...}}` at
/// `{baseUrl}/rates?base=<base>`.
final class FxRateRemoteService implements RemoteFxService {
  FxRateRemoteService(this._api, {required this.baseUrl});

  static const String _path = '/rates';

  final ApiClient _api;
  final String baseUrl;

  @override
  Future<Map<String, double>> fetchRates(String base) async {
    final endpoint = baseUrl.trim();
    if (endpoint.isEmpty) {
      throw StateError(
        'FX endpoint not configured — set FX_API_BASE_URL '
        '(see context/network/network.md).',
      );
    }
    final payload = await _api.getJson(_path, query: {'base': base});
    if (payload is! Map) {
      throw const FormatException('Unexpected FX rates payload');
    }
    final rates = payload['rates'];
    if (rates is! Map) {
      throw const FormatException('Unexpected FX rates payload');
    }
    return rates.map(
      (code, rate) => MapEntry('$code', (rate as num).toDouble()),
    );
  }
}

/// Local mock returning a static rate table. Rates are expressed as
/// "1 unit of currency = rateToBase units of base".
final class MockRemoteFxService implements RemoteFxService {
  static const Map<String, Map<String, double>> _tables = {
    'USD': {'EUR': 0.92, 'GBP': 0.79, 'JPY': 149.0, 'CAD': 1.36},
    'EUR': {'USD': 1.08, 'GBP': 0.86, 'JPY': 162.0, 'CAD': 1.48},
    'GBP': {'USD': 1.27, 'EUR': 1.16, 'JPY': 188.0, 'CAD': 1.72},
  };

  @override
  Future<Map<String, double>> fetchRates(String base) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return Map<String, double>.from(_tables[base] ?? const {});
  }
}
