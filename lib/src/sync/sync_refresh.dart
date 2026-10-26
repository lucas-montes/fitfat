import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../body/providers/body_metrics.dart';
import '../budget/providers/accounts.dart';
import '../budget/providers/budget_overview.dart';
import '../budget/providers/fx_rates.dart';
import '../budget/providers/receipts.dart';
import '../budget/providers/transactions.dart';
import '../dashboard/providers/dashboard.dart';
import '../diet/providers/calories.dart';
import '../diet/providers/foods.dart';
import '../diet/providers/ingredients.dart';
import '../diet/providers/meals.dart';
import '../exercise/providers/exercises.dart';
import '../exercise/providers/workout_templates.dart';
import '../exercise/providers/workouts.dart';
import '../goals/providers/goals.dart';
import '../notes/providers/notes.dart';
import '../planner/providers/planner.dart';
import '../tags/providers/tags.dart';

/// Drops every cached data provider so rows written by a sync pull or a JSON
/// import become visible without restarting the app.
///
/// Every list in the app is a `FutureProvider`: it queries once and then keeps
/// its result until something invalidates it. A pull writes straight to the
/// database, so without this the tabs keep rendering whatever they cached
/// before the pull. Manual edits already invalidate the providers they touch;
/// sync has to invalidate all of them because it can touch any table.
void invalidateAllData(WidgetRef ref) {
  // Planner entries (tasks and everything derived from them).
  ref.invalidate(dayEntriesProvider);
  ref.invalidate(monthEntriesProvider);
  ref.invalidate(rangeEntriesProvider);

  // Exercises, workouts and templates.
  ref.invalidate(exerciseListProvider);
  ref.invalidate(exerciseByIdProvider);
  ref.invalidate(workoutListProvider);
  ref.invalidate(workoutDetailProvider);
  ref.invalidate(exerciseHistoryProvider);
  ref.invalidate(workoutTemplateListProvider);
  ref.invalidate(workoutTemplateDetailsProvider);

  // Diet.
  ref.invalidate(mealListProvider);
  ref.invalidate(foodListProvider);
  ref.invalidate(foodByIdProvider);
  ref.invalidate(foodIngredientsProvider);
  ref.invalidate(foodCombinationProvider);
  ref.invalidate(ingredientListProvider);
  ref.invalidate(ingredientByIdProvider);
  ref.invalidate(ingredientPicturesProvider);
  ref.invalidate(ingredientPricesProvider);
  ref.invalidate(storesProvider);
  ref.invalidate(calorieTargetMetaProvider);
  ref.invalidate(calorieTargetProvider);
  ref.invalidate(macroTargetsProvider);

  // Tags, notes and goals.
  ref.invalidate(tagListProvider);
  ref.invalidate(tagNamesProvider);
  ref.invalidate(tagUsageCountsProvider);
  ref.invalidate(noteListProvider);
  ref.invalidate(goalListProvider);
  ref.invalidate(goalByIdProvider);
  ref.invalidate(goalProgressProvider);
  ref.invalidate(latestGoalProgressProvider);
  ref.invalidate(tasksByGoalProvider);

  // Body and budget.
  ref.invalidate(bodyMetricsProvider);
  ref.invalidate(latestBodyMetricsProvider);
  ref.invalidate(accountListProvider);
  ref.invalidate(transactionListProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(transactionByAccountProvider);
  ref.invalidate(budgetOverviewProvider);
  ref.invalidate(fxRatesProvider);
  ref.invalidate(fxRateEntriesProvider);
  ref.invalidate(receiptListProvider);
  ref.invalidate(receiptByIdProvider);
  ref.invalidate(receiptsByAccountProvider);
  ref.invalidate(receiptPendingProvider);

  // Dashboard cards compose several of the providers above.
  invalidateDashboard(ref);
}
