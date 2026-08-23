/// The three resources that can be pulled from the user's sync server.
enum SyncResource { exercises, ingredients, currencies }

/// Outcome of a single sync pull: how many rows were upserted / deleted, the
/// server timestamp to persist as the next `since` cursor, and an error
/// message when the pull failed.
final class SyncResult {
  final int updated;
  final int deleted;
  final int serverTime;
  final String? error;

  const SyncResult({
    this.updated = 0,
    this.deleted = 0,
    this.serverTime = 0,
    this.error,
  });

  bool get ok => error == null;
}

/// Parses a millisecond-epoch value from a JSON field, falling back to the
/// supplied server time (or now) when missing/invalid.
DateTime toSyncDateTime(Object? raw, int fallback) {
  final ms = raw is num ? raw.toInt() : null;
  return DateTime.fromMillisecondsSinceEpoch(ms ?? fallback);
}
