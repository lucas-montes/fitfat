import '../../l10n/app_localizations.dart';

/// The failure tag for the exercises a pull-all imports for its workouts.
const kRelatedExercisesEntity = 'Exercises (related)';

/// "never", "5m ago", "3h ago" or "2d ago" for a last-synced timestamp in
/// milliseconds (0 means never).
String lastSyncedLabel(AppLocalizations l10n, int ms) {
  if (ms == 0) return l10n.syncNever;
  final diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(ms),
  );
  if (diff.inMinutes < 60) return l10n.syncMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.syncHoursAgo(diff.inHours);
  return l10n.syncDaysAgo(diff.inDays);
}

/// The translated name of a sync or backup group.
///
/// The English names ('Tasks', 'Body', ...) double as identifiers: they key
/// the busy flags, the saved backup selection and the push/pull dispatch, so
/// only the label shown to the user is translated.
String syncEntityLabel(AppLocalizations l10n, String entity) =>
    switch (entity) {
      'Tags' => l10n.syncEntityTags,
      'Exercises' => l10n.syncEntityExercises,
      'Tasks' => l10n.syncEntityTasks,
      'Notes' => l10n.syncEntityNotes,
      'Goals' => l10n.syncEntityGoals,
      'Workouts' => l10n.syncEntityWorkouts,
      'Templates' => l10n.syncEntityTemplates,
      'Stores' => l10n.syncEntityStores,
      'Ingredients' => l10n.syncEntityIngredients,
      'Foods' => l10n.syncEntityFoods,
      'Meals' => l10n.syncEntityMeals,
      'Body' => l10n.syncEntityBody,
      'Budget' => l10n.syncEntityBudget,
      'Transactions' => l10n.syncEntityTransactions,
      'Receipts' => l10n.syncEntityReceipts,
      kRelatedExercisesEntity => l10n.syncRelatedExercises,
      _ => entity,
    };
