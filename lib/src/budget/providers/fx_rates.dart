import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../settings/providers/settings.dart';
import '../repositories/fx_repository.dart';

final fxRepositoryProvider = Provider<FxRepository>((ref) {
  return FxRepository(ref.watch(databaseProvider));
});

/// Cached FX rates for the current base currency, as a code -> rate map.
final fxRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final base = ref.watch(settingsProvider).baseCurrency;
  return ref.watch(fxRepositoryProvider).getRates(base);
});
