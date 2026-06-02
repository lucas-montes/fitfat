// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'fitfat';

  @override
  String get mealsTab => 'Meals';

  @override
  String get ingredientsTab => 'Ingredients';

  @override
  String get addMeal => 'Add Meal';

  @override
  String get addIngredient => 'Add Ingredient';

  @override
  String get editIngredient => 'Edit Ingredient';

  @override
  String get editMeal => 'Edit Meal';

  @override
  String get archivedIngredients => 'Archived Ingredients';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get archive => 'Archive';

  @override
  String get restore => 'Restore';

  @override
  String get add => 'Add';

  @override
  String get change => 'Change';

  @override
  String get clear => 'Clear';

  @override
  String get ingredientName => 'Ingredient name';

  @override
  String get buildFromIngredients => 'Build from ingredients';

  @override
  String get components => 'Components';

  @override
  String get noComponentsAdded => 'No components added yet';

  @override
  String get addComponents => 'Add ingredients';

  @override
  String get searchIngredients => 'Search ingredients';

  @override
  String get typeToSearchIngredient => 'Type to search ingredients';

  @override
  String get caloriesPer100g => 'Calories per 100g';

  @override
  String get proteinPer100g => 'Protein per 100g (g)';

  @override
  String get carbsPer100g => 'Carbs per 100g (g)';

  @override
  String get fatPer100g => 'Fat per 100g (g)';

  @override
  String get sodiumPer100g => 'Sodium per 100g (mg)';

  @override
  String get fiberPer100g => 'Fiber per 100g (g)';

  @override
  String get amountInGrams => 'Amount in grams';

  @override
  String get gramsHint => 'e.g. 80';

  @override
  String get gramsHintMeal => 'e.g. 120';

  @override
  String get createNewIngredient => 'Create new ingredient';

  @override
  String get mealNameOptional => 'Meal name (optional)';

  @override
  String get selectedIngredients => 'Selected ingredients';

  @override
  String get noIngredientsSelected => 'No ingredients selected yet';

  @override
  String get noIngredientsFound => 'No ingredients found';

  @override
  String get archiveIngredientTitle => 'Archive Ingredient';

  @override
  String get archiveIngredientContent =>
      'This ingredient will be hidden from regular views. Use the Archived Ingredients tab to restore or delete it.';

  @override
  String get deleteMealTitle => 'Delete meal?';

  @override
  String get deleteMealContent => 'This will remove the meal from your log.';

  @override
  String get deleteIngredientTitle => 'Delete ingredient?';

  @override
  String get deleteIngredientContent =>
      'This will remove the ingredient and any portions from meals.';

  @override
  String get permanentlyDeleteTitle => 'Permanently Delete Ingredient';

  @override
  String get permanentlyDeleteContent =>
      'This ingredient will be deleted permanently. It cannot be restored.';

  @override
  String get restoreIngredientTitle => 'Restore Ingredient';

  @override
  String get deleteMealTooltip => 'Delete meal';

  @override
  String get deleteIngredientTooltip => 'Delete';

  @override
  String get ingredientArchived => 'Ingredient archived successfully';

  @override
  String get ingredientDeleted => 'Ingredient deleted successfully';

  @override
  String get ingredientRestored => 'Ingredient restored successfully';

  @override
  String get meal => 'Meal';

  @override
  String get sortAZ => 'Sort A-Z';

  @override
  String get sortZA => 'Sort Z-A';

  @override
  String get noIngredientsFoundSubtext =>
      'Try a different search or add a new ingredient';

  @override
  String get kcalAbbrev => 'kcal';

  @override
  String get proteinAbbrev => 'P';

  @override
  String get carbsAbbrev => 'C';

  @override
  String get fatAbbrev => 'F';

  @override
  String eatenAtLabel(Object time) {
    return 'Eaten at: $time';
  }

  @override
  String failedToSave(Object error) {
    return 'Failed to save meal: $error';
  }

  @override
  String failedToUpdate(Object error) {
    return 'Failed to update meal: $error';
  }

  @override
  String items(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items',
      one: '$countString item',
    );
    return '$_temp0';
  }

  @override
  String formatMacros(Object kcal, Object protein, Object carbs, Object fat) {
    return '$kcal kcal · P ${protein}g · C ${carbs}g · F ${fat}g';
  }

  @override
  String formatPer100g(Object kcal, Object protein, Object carbs, Object fat) {
    return 'Per 100g: $kcal kcal · P ${protein}g · C ${carbs}g · F ${fat}g';
  }

  @override
  String formatTotal(Object total) {
    return 'Total: $total';
  }

  @override
  String get exercises => 'Exercises';

  @override
  String get exercise => 'Exercise';

  @override
  String get activeWorkout => 'Active Workout';

  @override
  String get noActiveSeance => 'No active workout';

  @override
  String get guidedMode => 'Guided';

  @override
  String get freeformMode => 'Free-form';

  @override
  String get cancelSeance => 'Cancel workout';

  @override
  String get backToApp => 'Back to app';

  @override
  String get discardEmptySeance => 'Discard empty workout?';

  @override
  String get discardEmptySeanceContent =>
      'This workout has no exercises and will not be saved to history.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get completeSeance => 'Complete Workout';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get followPlan => 'Follow the plan';

  @override
  String get searchToAdd => 'Search to add';

  @override
  String get searchExercises => 'Search exercises';

  @override
  String get exerciseTypeToSearch => 'Type to search exercises...';

  @override
  String get typeToFindExercises => 'Type to find exercises...';

  @override
  String get sets => 'Sets';

  @override
  String get set => 'Set';

  @override
  String get setsLower => 'sets';

  @override
  String get done => 'done';

  @override
  String get summary => 'Summary';

  @override
  String get totalReps => 'Total Reps';

  @override
  String get totalWeight => 'Total Weight';

  @override
  String get addSet => 'Add Set';

  @override
  String get tapToComplete => 'Tap to complete';

  @override
  String get noExercisesFound => 'No exercises found matching';

  @override
  String get repsLower => 'reps';

  @override
  String get preFilledFrom => 'Pre-filled from';

  @override
  String get allSetsComplete => 'All sets complete!';

  @override
  String get restTimer => 'Rest Timer';

  @override
  String get skip => 'Skip';

  @override
  String get restOver => 'Rest over!';

  @override
  String get getReadyNextSet => 'Get ready for your next set!';

  @override
  String get editSet => 'Edit Set';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get history => 'History';

  @override
  String get records => 'Records';

  @override
  String get noHistory => 'No history yet';

  @override
  String get sessions => 'Sessions';

  @override
  String get volume => 'Volume';

  @override
  String get time => 'Time';

  @override
  String get searchHistory => 'Search history';

  @override
  String get searchByDateHint => 'Search by date or workout name...';

  @override
  String get volumeProgression => 'Volume Progression';

  @override
  String get estimated1RM => 'Estimated 1RM Progression';

  @override
  String get bestEstimated1RM => 'Best Estimated 1RM';

  @override
  String get maxWeight => 'Max Weight';

  @override
  String get maxVolume => 'Max Volume (Set)';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get noHistoryContent =>
      'Complete a workout with this exercise to see it here';

  @override
  String get library => 'Library';

  @override
  String get createExercise => 'Create Exercise';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get category => 'Category';

  @override
  String get templates => 'Templates';

  @override
  String get createTemplate => 'Create Template';

  @override
  String exercisesCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString exercises',
      one: '$countString exercise',
    );
    return '$_temp0';
  }

  @override
  String setsCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sets',
      one: '$countString set',
    );
    return '$_temp0';
  }

  @override
  String get workoutsTab => 'Workouts';

  @override
  String get statsTab => 'Stats';

  @override
  String get searchExercisesHint => 'Search exercises...';

  @override
  String get noExercisesFoundSimple => 'No exercises found';

  @override
  String get noExercisesFoundAction =>
      'Try a different search or clear filters';

  @override
  String get runningWorkout => 'Running Seance';

  @override
  String get viewWorkout => 'View';

  @override
  String get stopWorkout => 'Stop';

  @override
  String get newSeance => 'New Seance';

  @override
  String get startBlankSeance => 'Start Blank Seance';

  @override
  String get create => 'Create';

  @override
  String get noTemplatesYet =>
      'No templates yet. Create one to quickly start a workout!';

  @override
  String get browseAllTemplates => 'Browse all templates';

  @override
  String get noWorkoutsYet => 'No workouts yet. Start your first one above!';

  @override
  String get allTime => 'All Time';

  @override
  String get workouts => 'Workouts';

  @override
  String get duration => 'Duration';

  @override
  String get thisWeek => 'This Week';

  @override
  String get activity => 'Activity';

  @override
  String get trends => 'Trends';

  @override
  String get edit => 'Edit';

  @override
  String get clone => 'Clone';

  @override
  String get start => 'Start';

  @override
  String get createTemplateFrom => 'Create template from this';

  @override
  String get workoutAlreadyRunning => 'Workout already running';

  @override
  String get workoutAlreadyRunningContent =>
      'A workout is already in progress. Cancel it and start a new one?';

  @override
  String get startNewWorkout => 'Start new workout';

  @override
  String get workout => 'Workout';

  @override
  String get noExercises => 'No exercises';

  @override
  String get pr => 'PR!';

  @override
  String get oneRM => 'e1RM';

  @override
  String get workoutSummary => 'Workout Summary';

  @override
  String get exerciseBreakdown => 'Exercise Breakdown';

  @override
  String get best => 'Best';

  @override
  String get finish => 'Finish';

  @override
  String previousSessions(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return 'Previous sessions ($countString)';
  }

  @override
  String get tapToExpand => 'Tap to expand';

  @override
  String get reps => 'Reps';

  @override
  String get templateLibrary => 'Template Library';

  @override
  String get createFirstTemplate => 'Create your first template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get templateNameLabel => 'Template name';

  @override
  String get addCustom => 'Add as custom';

  @override
  String get searchAboveHint =>
      'Search an exercise above to add it. Tap an exercise in the list to configure sets and reps.';

  @override
  String get noExercisesAdded => 'No exercises added yet';

  @override
  String get noSetsConfigured => 'No sets configured — tap to edit';

  @override
  String get remove => 'Remove';

  @override
  String get restSeconds => 'Rest (s)';

  @override
  String get pastMonth => 'Past month';

  @override
  String get past3Months => 'Past 3 months';

  @override
  String get pastYear => 'Past year';

  @override
  String noHistoryFor(Object name) {
    return 'No history for $name yet';
  }

  @override
  String get completeWorkoutToSee =>
      'Complete a workout with this exercise to see it here';

  @override
  String get date => 'Date';

  @override
  String get searchByDateWorkout => 'Search by date or workout name...';

  @override
  String sessionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '$count session',
    );
    return '$_temp0';
  }

  @override
  String get maxVolumeSet => 'Max Volume (Set)';

  @override
  String get notAvailable => 'N/A';

  @override
  String get across => 'Across';

  @override
  String get overviewTab => 'Overview';

  @override
  String get goalsTab => 'Goals';

  @override
  String get settingsTab => 'Settings';

  @override
  String get weight => 'Weight';

  @override
  String get weightLogged => 'Weight logged!';

  @override
  String get enterWeightKg => 'Enter weight (kg)';

  @override
  String get log => 'Log';

  @override
  String get weightTracker => 'Weight Tracker';

  @override
  String get noWeightEntries => 'No weight entries yet.';

  @override
  String get latest => 'Latest';

  @override
  String get logWeight => 'Log Weight';

  @override
  String get historyLast7Entries => 'History (last 7 entries)';

  @override
  String get waterIntake => 'Water Intake';

  @override
  String get goal => 'Goal';

  @override
  String get setDailyWaterGoal => 'Set Daily Water Goal';

  @override
  String get litersExample => 'Liters (e.g., 2.5)';

  @override
  String get todaysActivity => 'Today\'s activity';

  @override
  String get workoutInProgress => 'Workout in progress';

  @override
  String get exercisesCompleted => 'exercises completed';

  @override
  String get noWorkoutsToday =>
      'No workouts yet. Start a session to see today\'s summary here.';

  @override
  String get elapsed => 'elapsed';

  @override
  String get last84Days => 'Last 84 days';

  @override
  String get noTrainingRecorded => 'No training recorded on this day.';

  @override
  String get today => 'Today';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get setProfileForTargets =>
      'Set a bodyweight goal and your profile to see daily targets.';

  @override
  String get bodyWeightGoal => 'Body Weight Goal';

  @override
  String get noBodyweightGoalSet => 'No bodyweight goal set.';

  @override
  String get addBodyWeightGoal => 'Add Body Weight Goal';

  @override
  String get target => 'Target';

  @override
  String get by => 'By';

  @override
  String get strengthGoals => 'Strength Goals';

  @override
  String get addStrengthGoalTooltip => 'Add strength goal';

  @override
  String get noStrengthGoalsYet =>
      'No strength goals yet. Tap + to add (one per exercise).';

  @override
  String get setUpProfileFirst => 'Set up your profile first';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get birthdate => 'Birthdate';

  @override
  String get sex => 'Sex';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get addBodyWeightGoalTitle => 'Add Body Weight Goal';

  @override
  String get editBodyWeightGoalTitle => 'Edit Body Weight Goal';

  @override
  String get direction => 'Direction';

  @override
  String get targetWeightKg => 'Target Weight (kg)';

  @override
  String get targetDate => 'Target date';

  @override
  String get notSet => 'Not set';

  @override
  String get addStrengthGoalTitle => 'Add Strength Goal';

  @override
  String get editStrengthGoalTitle => 'Edit Strength Goal';

  @override
  String get searchOrTypeCustom => 'Search or type custom name';

  @override
  String get deleteBodyweightGoal => 'Delete bodyweight goal?';

  @override
  String get deleteBodyweightGoalContent =>
      'This will clear your weight target and macro targets.';

  @override
  String deleteStrengthGoalTitle(Object exercise) {
    return 'Delete strength goal for $exercise?';
  }

  @override
  String get deleteStrengthGoalContent => 'This will remove the goal.';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get goalReached => 'Goal reached!';

  @override
  String get toGo => 'to go';

  @override
  String get strengthTrend => 'Strength Trend';

  @override
  String get noStrengthData => 'No strength data';

  @override
  String get weightTrend90Days => 'Weight Trend (90 days)';

  @override
  String get profile => 'Profile';

  @override
  String get setUpProfile => 'Set up Profile';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get visibleMacros => 'Visible macros';

  @override
  String get defaultRestTimer => 'Default rest timer';

  @override
  String get secondsBetweenSets => '60 seconds between sets';

  @override
  String get restTimerComingSoon => 'Rest timer settings coming soon';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get systemDefault => 'System default';

  @override
  String get themeComingSoon => 'Theme settings coming soon';

  @override
  String get data => 'Data';

  @override
  String get exportDatabase => 'Export database';

  @override
  String get shareDbFile => 'Share the SQLite database file';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get removeEverything => 'Remove everything and restart fresh';

  @override
  String get noDbFound => 'No database file found';

  @override
  String get deleteAllDataTitle => 'Delete all data?';

  @override
  String get deleteAllDataContent =>
      'This will remove all your data including meals, exercises, workouts, goals, and profile. A fresh database will be created on next launch.';

  @override
  String get dbDeleted => 'Database deleted. Restart the app to recreate it.';

  @override
  String get thisMonth => 'This month';

  @override
  String get couldNotLoadWeightHistory => 'Could not load weight history.';

  @override
  String get trainingHeatmap => 'Training heatmap';

  @override
  String get heatmapLegendLow => 'Low';

  @override
  String get heatmapLegendMid => 'Mid';

  @override
  String get heatmapLegendHigh => 'High';

  @override
  String get benchPress => 'Bench Press';

  @override
  String get deadlift => 'Deadlift';

  @override
  String get squat => 'Squat';

  @override
  String get enterDetailsForMacros =>
      'Enter your details for macro calculations';

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String deleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get navDiet => 'Diet';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navExercise => 'Exercise';
}
