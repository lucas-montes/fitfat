import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../settings/providers/settings.dart';
import '../repositories/fx_repository.dart';

export '../repositories/fx_repository.dart' show FxRateEntry;

final fxRepositoryProvider = Provider<FxRepository>((ref) {
  return FxRepository(ref.watch(databaseProvider));
});

/// Cached FX rates for the current base currency, as a code -> rate map.
final fxRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final base = ref.watch(settingsProvider).baseCurrency;
  return ref.watch(fxRepositoryProvider).getRates(base);
});

/// Cached FX rates for the current base currency with provenance (updated-at +
/// manual flag), for the Settings display.
final fxRateEntriesProvider = FutureProvider<List<FxRateEntry>>((ref) async {
  final base = ref.watch(settingsProvider).baseCurrency;
  return ref.watch(fxRepositoryProvider).getRateEntries(base);
});
