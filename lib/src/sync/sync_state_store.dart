import 'package:shared_preferences/shared_preferences.dart';

import 'sync_models.dart';

/// Tracks the last successful sync timestamp (epoch ms) per [SyncResource], so
/// the next pull only requests changes since then (server-side `since` cursor).
abstract interface class SyncStateStore {
  int getLastSyncedAt(SyncResource resource);

  Future<void> setLastSyncedAt(SyncResource resource, int ms);
}

/// The production store, backed by `SharedPreferences` so cursors survive
/// restarts without a DB migration.
final class PrefsSyncStateStore implements SyncStateStore {
  final SharedPreferences _prefs;

  const PrefsSyncStateStore(this._prefs);

  static const _prefix = 'sync_last_';

  @override
  int getLastSyncedAt(SyncResource resource) =>
      _prefs.getInt('$_prefix${resource.name}') ?? 0;

  @override
  Future<void> setLastSyncedAt(SyncResource resource, int ms) async {
    await _prefs.setInt('$_prefix${resource.name}', ms);
  }
}

/// An in-memory store for tests — a plain `flutter test` run has no platform for
/// SharedPreferences.
final class MemorySyncStateStore implements SyncStateStore {
  final Map<SyncResource, int> _cursors = {};

  @override
  int getLastSyncedAt(SyncResource resource) => _cursors[resource] ?? 0;

  @override
  Future<void> setLastSyncedAt(SyncResource resource, int ms) async {
    _cursors[resource] = ms;
  }
}
