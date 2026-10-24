/// The resources that can be pulled from the user's sync server.
///
/// `ingredients` must be pulled **before** `foods`: a recipe references
/// ingredients by id and the two have independent cursors.
///
/// The personal pool (the last thirteen values) is the user's own data mirrored
/// by the sync server. Two roles apply, and every pull path honors them:
///
///  * **Local-first** — tasks, notes, goals, workouts, templates,
///    meals, bodyMetrics, budgetAccounts, transactions, stores: a server row
///    is applied only when the id is absent locally, so a local edit always
///    wins; the server's tombstoned ids still delete local rows (deletion
///    intent is global).
///  * **Server-wins** — tags and receipts: the server is the source of truth,
///    pulled rows overwrite local state (receipt images stay server-side; only
///    the parse rides along).
enum SyncResource {
  exercises,
  ingredients,
  foods,
  currencies,
  tasks,
  notes,
  goals,
  workouts,
  templates,
  meals,
  bodyMetrics,
  budgetAccounts,
  transactions,
  receipts,
  tags,
  stores,
}

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
