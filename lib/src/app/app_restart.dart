import 'package:flutter/foundation.dart';

/// Emits whenever the app must rebuild with a fresh `ProviderContainer`.
///
/// Replacing the database file invalidates every cached provider and closes
/// the old handle, so the only safe recovery is a full in-place restart: the
/// root widget disposes the old container (closing its database and cancelling
/// its timers) and builds a new one against the imported file. The current
/// route is preserved, so the user stays where they were.
final ValueNotifier<int> appRestartSignal = ValueNotifier<int>(0);

/// Restarts the app in place. Safe to call from any async callback.
void restartApp() => appRestartSignal.value++;
