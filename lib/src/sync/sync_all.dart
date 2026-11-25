import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart' as db;
import '../settings/providers/settings.dart';
import 'data_push_service.dart';
import 'entity_labels.dart';
import 'personal_pull_service.dart';
import 'sync_models.dart';
import 'sync_service.dart';

/// Dependency order for both directions.
///
/// Tags go first so links can name them; exercises go before workouts and
/// templates because those reference exercise ids (the server enforces the
/// foreign key on push). Stores precede ingredients (their prices name a
/// store), ingredients precede foods, and foods precede meals: the server
/// skips a logged food whose recipe it does not know yet, and budget accounts
/// precede transactions for the same reason.
const syncOrder = [
  'Tags',
  'Exercises',
  'Tasks',
  'Notes',
  'Goals',
  'Workouts',
  'Templates',
  'Stores',
  'Ingredients',
  'Foods',
  'Meals',
  'Body',
  'Budget',
  'Transactions',
  'Receipts',
];

/// Entities the phone only pulls. Accounts and transactions are the server's:
/// the desktop and the statement imports make them, and a push would put the
/// phone's stale copy back over them.
const syncPullOnly = {'Budget', 'Transactions'};

/// Entities the phone only pushes. A receipt is sent, parsed by the server and
/// forgotten here; pulling would only bring the forgotten back.
const syncPushOnly = {'Receipts'};

/// The pull half of a full sync skips the exercise library. Workouts and
/// templates bring only the exercises they reference (see
/// [importRelatedExercises]); the rest are cherry-picked by the user.
final syncPullOrder = List<String>.unmodifiable(
  syncOrder.where((entity) => entity != 'Exercises'),
);

/// The push/pull type name for an entity label.
String syncEntityType(String entity) => switch (entity) {
  'Tags' => 'tags',
  'Exercises' => 'exercises',
  'Tasks' => 'tasks',
  'Notes' => 'notes',
  'Goals' => 'goals',
  'Workouts' => 'workouts',
  'Templates' => 'templates',
  'Meals' => 'meals',
  'Body' => 'bodyMetrics',
  'Budget' => 'budgetAccounts',
  'Transactions' => 'transactions',
  'Receipts' => 'receiptPictures',
  'Stores' => 'stores',
  'Ingredients' => 'ingredients',
  'Foods' => 'foods',
  _ => 'tasks',
};

/// The cursor an entity's last-synced time is read from.
SyncResource? syncResourceOf(String entity) => switch (entity) {
  'Tags' => SyncResource.tags,
  'Exercises' => SyncResource.exercises,
  'Tasks' => SyncResource.tasks,
  'Notes' => SyncResource.notes,
  'Goals' => SyncResource.goals,
  'Workouts' => SyncResource.workouts,
  'Templates' => SyncResource.templates,
  'Meals' => SyncResource.meals,
  'Body' => SyncResource.bodyMetrics,
  'Budget' => SyncResource.budgetAccounts,
  'Transactions' => SyncResource.transactions,
  'Receipts' => SyncResource.receipts,
  'Stores' => SyncResource.stores,
  'Ingredients' => SyncResource.ingredients,
  'Foods' => SyncResource.foods,
  _ => null,
};

/// When the last complete "Sync now" finished without errors.
const lastFullSyncPrefKey = 'sync_last_full_at';

/// Outcome of [syncEverything]. A failed push stops the run before anything
/// is pulled, so [pushFailedEntity] and [pullFailures] never both appear.
final class SyncAllOutcome {
  const SyncAllOutcome({
    this.pushFailedEntity,
    this.pushError,
    this.pullFailures = const [],
  });

  final String? pushFailedEntity;
  final String? pushError;
  final List<String> pullFailures;

  bool get ok => pushFailedEntity == null && pullFailures.isEmpty;
}

/// One-tap two-way sync: pushes the phone's data in dependency order, then
/// pulls the server's, then imports the exercises the pulled workouts and
/// templates reference. Stops before pulling if a push fails, because a pull
/// mirrors the server and would overwrite the phone's unsent changes.
///
/// [onStep] reports the entity being worked on, for progress text.
Future<SyncAllOutcome> syncEverything(
  WidgetRef ref, {
  void Function(String entity)? onStep,
}) async {
  // Read everything that outlives a disposed caller up front.
  final prefs = ref.read(sharedPreferencesProvider);

  for (final entity in syncOrder) {
    if (syncPullOnly.contains(entity)) continue;
    onStep?.call(entity);
    try {
      final res = await pushDataType(ref, syncEntityType(entity));
      if (!res.ok) {
        return SyncAllOutcome(
          pushFailedEntity: entity,
          pushError: res.error ?? 'unknown error',
        );
      }
    } catch (e) {
      return SyncAllOutcome(pushFailedEntity: entity, pushError: '$e');
    }
  }

  final failures = <String>[];
  for (final entity in syncPullOrder) {
    if (syncPushOnly.contains(entity)) continue;
    onStep?.call(entity);
    try {
      final res = await pullDataType(ref, syncEntityType(entity));
      if (!res.ok) failures.add(entity);
    } catch (_) {
      failures.add(entity);
    }
  }
  try {
    if (!await importRelatedExercises(ref)) {
      failures.add(kRelatedExercisesEntity);
    }
  } catch (_) {
    failures.add(kRelatedExercisesEntity);
  }

  if (failures.isEmpty) {
    await prefs.setInt(
      lastFullSyncPrefKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  return SyncAllOutcome(pullFailures: failures);
}

/// Imports the exercise definitions referenced by workouts and template
/// blueprints that the phone does not have yet. The library is never pulled
/// in bulk: only missing ids are fetched, one by one, through the selective
/// import path (which also downloads their media). Returns false on failure.
Future<bool> importRelatedExercises(WidgetRef ref) async {
  // Read everything up front: the caller can be disposed while the queries
  // and downloads below are in flight, and a `ref.read` after that throws.
  final database = ref.read(db.databaseProvider);
  final settings = ref.read(settingsProvider);
  final sync = ref.read(syncServiceProvider);
  final rows = await database.customSelect('''
    SELECT DISTINCT we.exercise_id
    FROM workout_exercises we
    JOIN workouts w ON w.id = we.workout_id
    WHERE w.deleted_at IS NULL
      AND we.exercise_id NOT IN (SELECT id FROM exercises)
    UNION
    SELECT DISTINCT wte.exercise_id
    FROM workout_template_exercises wte
    JOIN workout_templates wt ON wt.id = wte.template_id
    WHERE wt.deleted_at IS NULL
      AND wte.exercise_id NOT IN (SELECT id FROM exercises)
  ''').get();
  final ids = {for (final row in rows) row.read<String>('exercise_id')};
  if (ids.isEmpty) return true;

  final result = await sync.importSelectedExercises(
    settings.remoteSyncBaseUrl,
    settings.remoteSyncApiKey,
    ids,
    endpoint: settings.endpointExercises,
    timeout: Duration(seconds: settings.apiTimeoutSeconds),
  );
  return result.ok;
}
