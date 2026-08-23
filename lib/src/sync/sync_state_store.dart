import 'package:shared_preferences/shared_preferences.dart';

import 'sync_models.dart';

/// Tracks the last successful sync timestamp (epoch ms) per [SyncResource], so
/// the next pull only requests changes since then (server-side `since` cursor).
/// Backed by `SharedPreferences`; survives restarts without a DB migration.
final class SyncStateStore {
  final SharedPreferences _prefs;

  const SyncStateStore(this._prefs);

  static const _prefix = 'sync_last_';

  int getLastSyncedAt(SyncResource resource) =>
      _prefs.getInt('$_prefix${resource.name}') ?? 0;

  Future<void> setLastSyncedAt(SyncResource resource, int ms) async {
    await _prefs.setInt('$_prefix${resource.name}', ms);
  }
}
