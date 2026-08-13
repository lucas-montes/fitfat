// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FitFat';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabExercise => 'Exercise';

  @override
  String get tabDiet => 'Diet';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabNotes => 'Notes';

  @override
  String get dashboardAppBar => 'Dashboard';

  @override
  String get dashboardTodayCalories => 'Today\'s Calories';

  @override
  String get dashboardLatestWorkout => 'Latest Workout';

  @override
  String get dashboardNoWorkouts => 'No completed workouts yet.';

  @override
  String get dashboardWelcomeTitle => 'Welcome to FitFat';

  @override
  String get dashboardWelcomeBody =>
      'Start by adding an ingredient, a meal, or a workout.';

  @override
  String get dashboardWelcomeActionIngredients => 'Add an ingredient';

  @override
  String get dashboardWelcomeActionMeals => 'Log a meal';

  @override
  String get dashboardWelcomeActionWorkouts => 'Add a workout';

  @override
  String dashboardDurationMin(int minutes) {
    return 'Duration: $minutes min';
  }

  @override
  String dashboardCaloriesValue(String calories) {
    return '$calories kcal';
  }

  @override
  String dashboardError(String message) {
    return 'Error: $message';
  }

  @override
  String get dashboardGreetingMorning => 'Good morning';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String get dashboardMacroProtein => 'Protein';

  @override
  String get dashboardMacroCarbs => 'Carbs';

  @override
  String get dashboardMacroFat => 'Fat';

  @override
  String get dashboardContinueWorkout => 'Continue workout';

  @override
  String get dashboardOpenWorkout => 'Open workout';

  @override
  String get dashboardCalorieTarget => 'Daily calorie target';

  @override
  String get dashboardRemaining => 'remaining';

  @override
  String dashboardConsumedOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String dashboardOverTarget(String kcal) {
    return '$kcal kcal over target';
  }

  @override
  String get dashboardMacroTargets => 'Macro targets';

  @override
  String dashboardMacroProgress(String consumed, String target) {
    return '$consumed / $target g';
  }

  @override
  String get dashboardWeightTrend => 'Weight trend';

  @override
  String get dashboardWeeklyWorkout => 'Weekly workout';

  @override
  String get dashboardVolume => 'Volume';

  @override
  String dashboardVolumeKg(String volume) {
    return '$volume kg';
  }

  @override
  String get dashboardMinutes => 'Minutes';

  @override
  String get dashboardUpcomingTasks => 'Upcoming tasks';

  @override
  String get dashboardNoUpcomingTasks => 'No upcoming timed tasks.';

  @override
  String dashboardSeeAllTasks(String count) {
    return 'See all $count tasks';
  }

  @override
  String get exerciseListAppBar => 'Exercises';

  @override
  String get exerciseListManageBtn => 'Manage Exercises';

  @override
  String get exerciseListSearchHint => 'Search exercises';

  @override
  String get exerciseFilterType => 'Type';

  @override
  String get exerciseFilterBodyPart => 'Body part';

  @override
  String get exerciseFilterEquipment => 'Equipment';

  @override
  String get exerciseFilterMuscle => 'Muscle';

  @override
  String exerciseFilterResults(int count) {
    return '$count exercises';
  }

  @override
  String get exerciseFilterClear => 'Clear';

  @override
  String get exerciseFilterApply => 'Apply';

  @override
  String get exerciseFilterNoResults => 'No exercises match';

  @override
  String get exerciseFilterSearchOptions => 'Search options';

  @override
  String get exerciseDetailTabHistory => 'History';

  @override
  String get exerciseDetailTabDetails => 'Details';

  @override
  String get emptyExercisesTitle => 'No exercises yet';

  @override
  String get emptyExercisesBody => 'Create exercises to plan your workouts.';

  @override
  String get emptyExercisesCta => 'Add exercise';

  @override
  String get activeWorkoutAddExercise => 'Add Exercise';

  @override
  String get activeWorkoutAddExerciseTooltip =>
      'Search and add exercises to this workout';

  @override
  String get activeWorkoutInThisWorkout => 'In This Workout';

  @override
  String get activeWorkoutAllExercises => 'All Exercises';

  @override
  String get activeWorkoutSearchPrompt => 'Type to search exercises';

  @override
  String get exerciseUsedTitle => 'Exercise in use';

  @override
  String exerciseUsedBody(int count) {
    return 'Used in $count workout. Delete the workout first to remove this exercise.';
  }

  @override
  String exerciseUsedBody_plural(Object count) {
    return 'Used in $count workouts. Delete the workouts first to remove this exercise.';
  }

  @override
  String get exerciseLockedEdit => 'Built-in exercises can\'t be edited.';

  @override
  String get exerciseLockedDelete => 'Built-in exercises can\'t be deleted.';

  @override
  String get exerciseDetailAppBar => 'Exercise';

  @override
  String get exerciseDetailNotFound => 'Exercise not found.';

  @override
  String get exerciseDetailType => 'Type';

  @override
  String get exerciseDetailBodyPart => 'Body part';

  @override
  String get exerciseDetailEquipment => 'Equipment';

  @override
  String get exerciseDetailPrimaryMuscle => 'Primary muscles';

  @override
  String get exerciseDetailSecondaryMuscle => 'Secondary muscles';

  @override
  String get exerciseDetailInstructions => 'Instructions';

  @override
  String get exerciseDetailTips => 'Tips';

  @override
  String get exerciseDetailFaqs => 'FAQs';

  @override
  String get exerciseDetailKeywords => 'Keywords';

  @override
  String get exerciseDetailHistory => 'History';

  @override
  String get exerciseDetailHistoryEmpty =>
      'No history yet. Add this exercise to a workout to see your stats.';

  @override
  String get exerciseDetailBestWeight => 'Best weight';

  @override
  String get exerciseDetailBestVolume => 'Best volume';

  @override
  String get exerciseDetailBestDuration => 'Best duration';

  @override
  String get exerciseDetailTotalWorkouts => 'Workouts';

  @override
  String get exerciseDetailTotalSets => 'Sets';

  @override
  String get exerciseDetailVolumeOverTime => 'Volume over time';

  @override
  String get exerciseDetailDurationOverTime => 'Duration over time';

  @override
  String get exerciseDetailPlannedVsActual => 'Planned vs actual';

  @override
  String get exerciseDetailVolumeAdherence => 'Volume adherence';

  @override
  String get exerciseDetailSetsCompleted => 'Sets completed';

  @override
  String exerciseDetailAdherenceValue(String percent) {
    return '$percent%';
  }

  @override
  String exerciseDetailSetNumber(int number) {
    return 'Set $number';
  }

  @override
  String get exerciseDetailSetCompleted => 'Completed';

  @override
  String get exerciseDetailSetNotCompleted => 'Not completed';

  @override
  String get exerciseDetailSetEmpty => '—';

  @override
  String exerciseDetailRepsDelta(String delta) {
    return '$delta reps';
  }

  @override
  String exerciseDetailWeightDelta(String delta) {
    return '$delta kg';
  }

  @override
  String exerciseDetailSetRest(String rest) {
    return 'rest $rest';
  }

  @override
  String exerciseDetailSetRestTook(String rest) {
    return '(took $rest)';
  }

  @override
  String get exerciseFormNewTitle => 'New Exercise';

  @override
  String get exerciseFormEditTitle => 'Edit Exercise';

  @override
  String get exerciseFormNameLabel => 'Exercise Name';

  @override
  String get exerciseFormNameHint => 'e.g. Bench Press';

  @override
  String get exerciseFormNameRequired => 'Name is required';

  @override
  String get exerciseFormTypeLabel => 'Type';

  @override
  String get exerciseFormSave => 'Save';

  @override
  String get exerciseFormSaving => 'Saving…';

  @override
  String get workoutListAppBar => 'Workouts';

  @override
  String get workoutListManageBtn => 'Manage Exercises';

  @override
  String get emptyWorkoutsTitle => 'No workouts yet';

  @override
  String get emptyWorkoutsBody => 'Plan your first workout and start training.';

  @override
  String get emptyWorkoutsCta => 'Add workout';

  @override
  String workoutDeleted(String name) {
    return 'Workout \"$name\" deleted';
  }

  @override
  String workoutDuplicated(String name) {
    return 'Workout \"$name\" duplicated';
  }

  @override
  String get workoutFormTitle => 'New Workout';

  @override
  String get workoutFormEditTitle => 'Edit Workout';

  @override
  String get workoutFormNameLabel => 'Workout Name';

  @override
  String get workoutFormNameHint => 'e.g. Morning Push';

  @override
  String get workoutFormNameRequired => 'Name is required';

  @override
  String get workoutFormDate => 'Date';

  @override
  String get workoutFormExercises => 'Exercises';

  @override
  String get workoutFormNoExercises =>
      'No exercises available. Add some first.';

  @override
  String get workoutFormSave => 'Save';

  @override
  String get workoutFormSaving => 'Saving…';

  @override
  String get workoutFormAddSet => 'Add set';

  @override
  String get workoutFormRepsLabel => 'Reps';

  @override
  String get workoutFormWeightLabel => 'kg';

  @override
  String get workoutFormDurationLabel => 'min';

  @override
  String get workoutFormSelectExercise => 'Select at least one exercise';

  @override
  String get workoutFormSearchHint => 'Search exercises';

  @override
  String get workoutFormRestLabel => 'Rest (min)';

  @override
  String get workoutFormSetIncomplete =>
      'Complete every added set with its values and rest time (or remove the empty set)';

  @override
  String get workoutFormRemoveExercise => 'Remove exercise';

  @override
  String workoutFormCreateExercise(Object query) {
    return 'Create new exercise “$query”';
  }

  @override
  String get workoutDetailAppBar => 'Workout';

  @override
  String get workoutDetailNotFound => 'Workout not found';

  @override
  String get workoutDetailBtnStart => 'Start';

  @override
  String get workoutDetailBtnComplete => 'Complete';

  @override
  String workoutDetailStartedAt(String time) {
    return 'Started: $time';
  }

  @override
  String get workoutDetailExercises => 'Exercises';

  @override
  String get emptyWorkoutDetailTitle => 'No exercises in this workout';

  @override
  String get emptyWorkoutDetailBody => 'Add exercises when creating a workout.';

  @override
  String get workoutDetailSetHeaderHash => '#';

  @override
  String get workoutDetailSetHeaderPlanned => 'Planned';

  @override
  String get workoutDetailSetHeaderActual => 'Actual';

  @override
  String workoutDetailSetActualsTitle(int number) {
    return 'Set $number — Actuals';
  }

  @override
  String get workoutDetailActualRepsLabel => 'Actual Reps';

  @override
  String get workoutDetailActualWeightLabel => 'Actual Weight (kg)';

  @override
  String get workoutDetailActualDurationLabel => 'Duration (min)';

  @override
  String get workoutDetailActualDistanceLabel => 'Distance (m)';

  @override
  String workoutDetailSetCount(int count) {
    return '$count set';
  }

  @override
  String workoutDetailSetCount_plural(Object count) {
    return '$count sets';
  }

  @override
  String get workoutStarted => 'Workout started';

  @override
  String get workoutCompleted => 'Workout completed';

  @override
  String get ingredientListAppBar => 'Ingredients';

  @override
  String get emptyIngredientsTitle => 'No ingredients yet';

  @override
  String get emptyIngredientsBody =>
      'Add your first ingredient to start building meals.';

  @override
  String get emptyIngredientsCta => 'Add ingredient';

  @override
  String ingredientArchived(String name) {
    return 'Ingredient \"$name\" archived';
  }

  @override
  String get ingredientFormNewTitle => 'New Ingredient';

  @override
  String get ingredientFormEditTitle => 'Edit Ingredient';

  @override
  String get ingredientFormNameLabel => 'Name';

  @override
  String get ingredientFormNameHint => 'e.g. Chicken Breast';

  @override
  String get ingredientFormNameRequired => 'Name is required';

  @override
  String get ingredientFormCaloriesLabel => 'Calories (per 100g)';

  @override
  String get ingredientFormCaloriesSuffix => 'kcal';

  @override
  String get ingredientFormProteinLabel => 'Protein (per 100g)';

  @override
  String get ingredientFormProteinSuffix => 'g';

  @override
  String get ingredientFormCarbsLabel => 'Carbs (per 100g)';

  @override
  String get ingredientFormCarbsSuffix => 'g';

  @override
  String get ingredientFormFatLabel => 'Fat (per 100g)';

  @override
  String get ingredientFormFatSuffix => 'g';

  @override
  String get ingredientFormSodiumLabel => 'Sodium (per 100g)';

  @override
  String get ingredientFormSodiumSuffix => 'mg';

  @override
  String get ingredientFormFiberLabel => 'Fiber (per 100g)';

  @override
  String get ingredientFormFiberSuffix => 'g';

  @override
  String get ingredientFormSugarLabel => 'Sugar (per 100g)';

  @override
  String get ingredientFormSugarSuffix => 'g';

  @override
  String ingredientFormFieldRequired(String label) {
    return '$label is required';
  }

  @override
  String ingredientFormFieldPositive(String label) {
    return '$label must be positive';
  }

  @override
  String ingredientFormFieldNonNegative(String label) {
    return '$label cannot be negative';
  }

  @override
  String get mealListAppBar => 'Meals';

  @override
  String get mealListManageBtn => 'Manage Ingredients';

  @override
  String get emptyMealsTitle => 'No meals yet';

  @override
  String get emptyMealsBody =>
      'Log your first meal to track calories and macros.';

  @override
  String get emptyMealsCta => 'Log a meal';

  @override
  String mealDeleted(String name) {
    return 'Meal \"$name\" deleted';
  }

  @override
  String mealListIngredientCount(int count) {
    return '$count ingredient';
  }

  @override
  String mealListIngredientCount_plural(Object count) {
    return '$count ingredients';
  }

  @override
  String mealListCaloriesValue(String calories) {
    return '$calories kcal';
  }

  @override
  String mealListMacroFormat(
    String grams,
    String calories,
    String protein,
    String carbs,
    String fat,
  ) {
    return '${grams}g  ·  $calories kcal  ·  P ${protein}g  ·  C ${carbs}g  ·  F ${fat}g';
  }

  @override
  String get mealFormNewTitle => 'New Meal';

  @override
  String get mealFormEditTitle => 'Edit Meal';

  @override
  String get mealFormNameLabel => 'Meal Name';

  @override
  String get mealFormNameHint => 'e.g. Breakfast';

  @override
  String get mealFormNameRequired => 'Name is required';

  @override
  String get mealFormDateTime => 'Date & Time';

  @override
  String get mealFormIngredients => 'Ingredients';

  @override
  String get mealFormNoIngredients =>
      'No ingredients available. Add some first.';

  @override
  String get mealFormAddIngredient => 'Add at least one ingredient with grams';

  @override
  String get mealFormGramsLabel => 'g';

  @override
  String get mealFormSave => 'Save';

  @override
  String get mealFormSaving => 'Saving…';

  @override
  String get plannerAppBar => 'Daily Plan';

  @override
  String get plannerToday => 'Today';

  @override
  String get plannerPreviousDay => 'Previous day';

  @override
  String get plannerNextDay => 'Next day';

  @override
  String get plannerAnytime => 'Anytime';

  @override
  String get plannerTimelineScheduled => 'Scheduled';

  @override
  String get emptyPlannerTitle => 'No tasks for this day';

  @override
  String get emptyPlannerBody => 'Add a task to plan your routine.';

  @override
  String get emptyPlannerCta => 'Add task';

  @override
  String get plannerTaskLabel => 'Task';

  @override
  String get plannerTaskHint => 'e.g. Morning run';

  @override
  String get plannerTaskRequired => 'Title is required';

  @override
  String get plannerNotesLabel => 'Notes';

  @override
  String get plannerWorkoutLabel => 'Workout (optional)';

  @override
  String get plannerWorkoutHint => 'Link a workout';

  @override
  String get plannerWorkoutNone => 'No workout';

  @override
  String get plannerLinkedWorkout => 'Open linked workout';

  @override
  String get plannerDueDateNone => 'No due date';

  @override
  String get plannerDueDateClear => 'Clear due date';

  @override
  String get plannerDueTimeNone => 'No due time';

  @override
  String get plannerDueTimeClear => 'Clear due time';

  @override
  String get plannerAddTask => 'New Task';

  @override
  String get plannerEditTask => 'Edit Task';

  @override
  String plannerDeleted(String title) {
    return 'Task \"$title\" deleted';
  }

  @override
  String get plannerCopyPrevious => 'Copy from yesterday';

  @override
  String get plannerCopyConfirmTitle => 'Copy pending tasks?';

  @override
  String plannerCopyConfirmBody(int count) {
    return '$count pending task from yesterday will be copied to today.';
  }

  @override
  String plannerCopyConfirmBody_plural(Object count) {
    return '$count pending tasks from yesterday will be copied to today.';
  }

  @override
  String get plannerCopyNothing => 'No pending tasks from yesterday to copy.';

  @override
  String plannerCopyDone(int count) {
    return 'Copied $count task to today.';
  }

  @override
  String plannerCopyDone_plural(Object count) {
    return 'Copied $count tasks to today.';
  }

  @override
  String get notesAppBar => 'Notes';

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyBody =>
      'Capture anything on your mind — routines, recipes, lessons from a workout. Notes are private to this device.';

  @override
  String get notesFab => 'New note';

  @override
  String get notesEditorNewTitle => 'New Note';

  @override
  String get notesEditorEditTitle => 'Edit Note';

  @override
  String get notesTitleLabel => 'Title';

  @override
  String get notesBodyLabel => 'Note';

  @override
  String get notesTitleRequired => 'Title is required';

  @override
  String get notesSave => 'Save';

  @override
  String get notesEditing => 'Saving…';

  @override
  String get notesDelete => 'Delete note';

  @override
  String get notesDeleteConfirmTitle => 'Delete note?';

  @override
  String notesDeleteConfirmBody(Object title) {
    return '“$title” will be permanently deleted. This can’t be undone.';
  }

  @override
  String get settingsAppBar => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAgeLabel => 'Age (years)';

  @override
  String get settingsAgeInvalid => 'Enter an age between 0 and 120';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangFr => 'Français';

  @override
  String get settingsLangEs => 'Español';

  @override
  String get settingsBodyWeightGoal => 'Body weight goal';

  @override
  String get settingsGoalLose => 'Lose weight';

  @override
  String get settingsGoalMaintain => 'Maintain weight';

  @override
  String get settingsGoalGain => 'Gain weight';

  @override
  String get settingsGender => 'Gender';

  @override
  String get settingsGenderMale => 'Male';

  @override
  String get settingsGenderFemale => 'Female';

  @override
  String get settingsActivityLevel => 'Activity level';

  @override
  String get settingsActivitySedentary => 'Sedentary';

  @override
  String get settingsActivityLight => 'Light';

  @override
  String get settingsActivityModerate => 'Moderate';

  @override
  String get settingsActivityActive => 'Active';

  @override
  String get settingsActivityVeryActive => 'Very active';

  @override
  String get settingsComputeActivity =>
      'Compute activity from workouts and steps';

  @override
  String get settingsTrackBodyFat => 'Track body fat';

  @override
  String get settingsBodyFatLabel => 'Body fat (%)';

  @override
  String get settingsBodyFatInvalid =>
      'Enter a body fat percentage between 0 and 70';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPlannerNotifications => 'Task reminders';

  @override
  String get settingsPlannerNotificationsSubtitle =>
      'Notify me about planner tasks with a due time.';

  @override
  String get settingsRestAlarmSound => 'Rest alarm sound';

  @override
  String get settingsRestAlarmVibration => 'Rest alarm vibration';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsResetData => 'Reset all data';

  @override
  String get settingsResetDataSubtitle =>
      'Erase all workouts, meals, metrics, planner tasks and notes, and restore default settings.';

  @override
  String get settingsResetDataConfirmTitle => 'Reset all data?';

  @override
  String get settingsResetDataConfirmBody =>
      'This permanently deletes all of your data and resets your settings. This cannot be undone.';

  @override
  String get settingsResetDataConfirmAction => 'Delete everything';

  @override
  String get settingsResetDataDone => 'All data has been reset.';

  @override
  String get taskReminderDueSoon => 'Due in 30 minutes';

  @override
  String get taskReminderDueNow => 'Due now';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPending => 'Pending';

  @override
  String get exerciseTypeWeightlifting => 'Weightlifting';

  @override
  String get exerciseTypeCardio => 'Cardio';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonSearch => 'Search';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String errorLoadingResource(String resource, String message) {
    return 'Error loading $resource: $message';
  }

  @override
  String macroGrams(String value) {
    return '${value}g';
  }

  @override
  String macroKcal(String value) {
    return '$value kcal';
  }

  @override
  String ingredientMacroRow(
    String grams,
    String calories,
    String protein,
    String carbs,
    String fat,
  ) {
    return '${grams}g  ·  $calories kcal  ·  P ${protein}g  ·  C ${carbs}g  ·  F ${fat}g';
  }

  @override
  String ingredientNutrientSodium(String value) {
    return 'Na ${value}mg';
  }

  @override
  String ingredientNutrientFiber(String value) {
    return 'Fiber ${value}g';
  }

  @override
  String ingredientNutrientSugar(String value) {
    return 'Sugar ${value}g';
  }

  @override
  String workoutDetailPlannedSetReps(String reps, String weight) {
    return '$reps × $weight kg';
  }

  @override
  String workoutDetailPlannedSetDuration(String minutes) {
    return '$minutes min';
  }

  @override
  String get workoutDetailPlannedSetEmpty => '—';

  @override
  String workoutDetailPlannedSetRest(Object planned, Object rest) {
    return '$planned · rest $rest';
  }

  @override
  String workoutDetailActualSetReps(String reps, String weight) {
    return '$reps × $weight kg';
  }

  @override
  String workoutDetailActualSetWeight(String weight) {
    return '$weight kg';
  }

  @override
  String workoutDetailActualSetDuration(String reps) {
    return '$reps min';
  }

  @override
  String get workoutDetailActualSetEmpty => '—';

  @override
  String get bodyMetricsTitle => 'Body Metrics';

  @override
  String get bodyMetricsAddWeight => 'Add weight';

  @override
  String get bodyMetricsAddHeight => 'Add height';

  @override
  String get bodyMetricsWeightLabel => 'Weight (kg)';

  @override
  String get bodyMetricsHeightLabel => 'Height (cm)';

  @override
  String get bodyMetricsDialogWeightTitle => 'New weight entry';

  @override
  String get bodyMetricsDialogHeightTitle => 'New height entry';

  @override
  String get bodyMetricsValueRequired => 'Enter a value';

  @override
  String get bodyMetricsValuePositive => 'Value must be greater than 0';

  @override
  String get bodyMetricsEmptyWeight => 'No weight entries yet.';

  @override
  String get bodyMetricsEmptyHeight => 'No height entries yet.';

  @override
  String bodyMetricsLatestWeight(String value) {
    return 'Latest: $value kg';
  }

  @override
  String bodyMetricsLatestHeight(String value) {
    return 'Latest: $value cm';
  }

  @override
  String bodyMetricsValueKg(String value) {
    return '$value kg';
  }

  @override
  String bodyMetricsValueCm(String value) {
    return '$value cm';
  }

  @override
  String bodyMetricsGoal(String goal) {
    return 'Goal: $goal';
  }

  @override
  String get restTimerTitle => 'Rest timer';

  @override
  String get restTimerCancel => 'Cancel rest';

  @override
  String restTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get activeWorkoutElapsedLabel => 'Elapsed';

  @override
  String get activeWorkoutRestLabel => 'Rest';

  @override
  String get activeWorkoutResume => 'Resume';

  @override
  String get restAlarmTitle => 'Rest is over';

  @override
  String get restAlarmBody => 'Your planned rest is complete.';

  @override
  String restAlarmBodyWithDuration(String duration) {
    return 'Your planned rest of $duration is complete.';
  }

  @override
  String get workoutSummaryAppBar => 'Summary';

  @override
  String get workoutSummaryDone => 'Done';

  @override
  String get workoutSummaryDurationLabel => 'Duration';

  @override
  String get workoutSummaryAvgRest => 'Average rest';

  @override
  String get workoutSummaryVolume => 'Volume';

  @override
  String get workoutSummaryMaxWeight => 'Max weight';

  @override
  String get workoutSummaryTotalReps => 'Total reps';

  @override
  String get workoutSummaryTotalDuration => 'Total duration';

  @override
  String get workoutSummaryTotalDistance => 'Total distance';

  @override
  String workoutSummaryValueKg(String value) {
    return '$value kg';
  }

  @override
  String workoutSummaryDistanceValue(String distance) {
    return '$distance m';
  }
}
