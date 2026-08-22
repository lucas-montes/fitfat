import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings.dart';
import '../providers/fx_rates.dart';
import '../providers/services.dart';

/// Keeps cached FX rates fresh while the user-enabled auto-refresh is on.
///
/// Watches the settings: enabling (or changing base currency / interval)
/// (re)schedules a periodic `RemoteFxService.fetchRates` →
/// `FxRepository.replaceAll` cycle and fires one refresh immediately so the
/// change is visible without waiting a full interval. Failures (offline,
/// unconfigured endpoint) are swallowed — manual refresh still works and the
/// next tick retries. Watch this provider once from an app-lifetime widget
/// (`_BackgroundStartup`) to keep it alive.
final fxAutoRefreshProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  Timer? timer;
  ({String base, int hours})? active;

  Future<void> refresh() async {
    final settings = ref.read(settingsProvider);
    try {
      final fetched = await ref
          .read(remoteFxProvider)
          .fetchRates(settings.baseCurrency);
      await ref
          .read(fxRepositoryProvider)
          .replaceAll(settings.baseCurrency, fetched);
      ref.invalidate(fxRatesProvider);
    } catch (_) {
      // Network unavailable or endpoint unconfigured — keep the cached rates
      // and retry on the next tick.
    }
  }

  void sync() {
    final settings = ref.read(settingsProvider);
    if (!settings.fxAutoRefresh) {
      timer?.cancel();
      timer = null;
      active = null;
      return;
    }
    final config = (
      base: settings.baseCurrency,
      hours: settings.fxRefreshIntervalHours,
    );
    if (timer != null && active == config) return;

    timer?.cancel();
    active = config;
    timer = Timer.periodic(Duration(hours: config.hours), (_) {
      unawaited(refresh());
    });
    // Immediate first fetch so toggling on has a visible effect.
    unawaited(refresh());
  }

  ref.onDispose(() => timer?.cancel());
  ref.listen(settingsProvider, (_, _) => sync());
  sync();
});
