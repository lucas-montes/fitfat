import 'dart:async';

/// Abstraction over a remote FX-rates backend. Returns rates from every
/// supported non-base currency to [base]. Swapped for a real implementation
/// later via the provider; the app caches results locally in `fx_rates`.
abstract class RemoteFxService {
  Future<Map<String, double>> fetchRates(String base);
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
