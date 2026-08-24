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
  String dashboardVolumeKg(String volume, String unit) {
    return '$volume $unit';
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
  String activeWorkoutPlannedSetsTitle(String exercise) {
    return 'Planned sets for $exercise';
  }

  @override
  String get activeWorkoutPlannedRepsLabel => 'Reps';

  @override
  String get activeWorkoutPlannedWeightLabel => 'Weight';

  @override
  String get commonRemove => 'Remove';

  @override
  String get activeWorkoutPrevExercise => 'Previous exercise';

  @override
  String get activeWorkoutNextExercise => 'Next exercise';

  @override
  String get activeWorkoutInThisWorkout => 'In This Workout';

  @override
  String get activeWorkoutAllExercises => 'All Exercises';

  @override
  String get activeWorkoutSearchPrompt => 'Type to search exercises';

  @override
  String get activeWorkoutExerciseNotes => 'Notes';

  @override
  String get activeWorkoutExerciseInfo => 'Exercise info';

  @override
  String get activeWorkoutExerciseNotesDialogTitle => 'Exercise notes';

  @override
  String get activeWorkoutExerciseNotesHint =>
      'Note what to repeat or change next time (sets, weight, difficulty)…';

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
  String exerciseDetailWeightDelta(String delta, String unit) {
    return '$delta $unit';
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
  String get exerciseDetailTrendSame => 'same as previous workout';

  @override
  String exerciseDetailTrendDelta(String delta, String unit) {
    return '$delta $unit vs previous workout';
  }

  @override
  String get exerciseDetailPrBadge => 'New PR';

  @override
  String get exerciseDetailSetHeader => 'Set';

  @override
  String get exerciseDetailSetHeaderPlanned => 'Planned';

  @override
  String get exerciseDetailSetHeaderActual => 'Actual';

  @override
  String get exerciseDetailSetHeaderDelta => 'Δ';

  @override
  String get exerciseDetailSetHeaderRest => 'Rest';

  @override
  String get exerciseDetailWeightTrend => 'Best weight over time';

  @override
  String get exerciseDetailRepsTrend => 'Reps over time';

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
  String get workoutFormAddExercise => 'Add exercise';

  @override
  String get workoutFormRemoveSet => 'Remove set';

  @override
  String get workoutFormReorderExercises => 'Reorder exercises';

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
  String get workoutDetailSetHeaderActual => 'Actual';

  @override
  String workoutDetailSetChipRest(String planned, String rest) {
    return '$planned · $rest';
  }

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
  String get plannerViewMonth => 'Month view';

  @override
  String get plannerViewDay => 'Day view';

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
  String get plannerTagsLabel => 'Tags';

  @override
  String get plannerTagsHint => 'Add a tag, then press + (e.g. Work, Errand)';

  @override
  String get plannerTagsAdd => 'Add tag';

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
  String get plannerStartTimeLabel => 'Start time';

  @override
  String get plannerEndTimeLabel => 'End time';

  @override
  String get plannerStartTimeNone => 'No start time';

  @override
  String get plannerEndTimeNone => 'No end time';

  @override
  String get plannerStartTimeClear => 'Clear start time';

  @override
  String get plannerEndTimeClear => 'Clear end time';

  @override
  String get plannerRepeatInvalid => 'Check the repeat settings';

  @override
  String get plannerAddTask => 'New Task';

  @override
  String get plannerEditTask => 'Edit Task';

  @override
  String get plannerEditScopeTitle => 'Edit scope';

  @override
  String get plannerDeleteScopeTitle => 'Delete scope';

  @override
  String get plannerScopeBody =>
      'This task repeats. How would you like to proceed?';

  @override
  String get plannerScopeThis => 'This one only';

  @override
  String get plannerScopeFollowing => 'This and all following ones';

  @override
  String plannerDeleted(String title) {
    return 'Task \"$title\" deleted';
  }

  @override
  String get plannerCopyPrevious => 'Copy from yesterday';

  @override
  String get plannerMoreActions => 'More actions';

  @override
  String get plannerTaskDetailAppBar => 'Task details';

  @override
  String plannerDetailUpdatedAt(String date) {
    return 'Created $date';
  }

  @override
  String plannerDetailDueDate(String date) {
    return 'Due $date';
  }

  @override
  String plannerDetailTimeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get plannerDetailNotes => 'Notes';

  @override
  String get plannerDetailTags => 'Tags';

  @override
  String get plannerDetailRepeats => 'Repeat';

  @override
  String get plannerDetailLinkedWorkout => 'Linked workout';

  @override
  String get plannerDetailEdit => 'Edit task';

  @override
  String get plannerDetailDelete => 'Delete task';

  @override
  String get plannerDetailDeleteTitle => 'Delete task?';

  @override
  String plannerDetailDeleteBody(String title) {
    return 'This deletes the task \"$title\".';
  }

  @override
  String get plannerRepeatSummaryDaily => 'Every day';

  @override
  String plannerRepeatSummaryWeekly(String days) {
    return 'Every week on $days';
  }

  @override
  String plannerRepeatSummaryInterval(int count) {
    return 'Every $count days';
  }

  @override
  String plannerRepeatSummaryMonthly(int day) {
    return 'Monthly on day $day';
  }

  @override
  String plannerRepeatSummaryEndsDate(String date) {
    return ' · until $date';
  }

  @override
  String plannerRepeatSummaryEndsCount(int count) {
    return ' · $count occurrences';
  }

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
  String get plannerRepeatLabel => 'Repeat';

  @override
  String get plannerRepeatNone => 'Does not repeat';

  @override
  String get plannerRepeatDaily => 'Daily';

  @override
  String get plannerRepeatWeekly => 'Weekly';

  @override
  String get plannerRepeatInterval => 'Every N days';

  @override
  String get plannerRepeatMonthly => 'Monthly';

  @override
  String get plannerRepeatWeekdays => 'Repeat on';

  @override
  String get plannerRepeatEvery => 'Every';

  @override
  String get plannerRepeatDays => 'days';

  @override
  String get plannerRepeatMonthDay => 'Day of month';

  @override
  String get plannerRepeatEnds => 'Ends';

  @override
  String get plannerRepeatEndsNever => 'Never';

  @override
  String get plannerRepeatEndsOnDate => 'On date';

  @override
  String get plannerRepeatEndsAfter => 'After';

  @override
  String get plannerRepeatOccurrences => 'occurrences';

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
  String get settingsLangSystem => 'System';

  @override
  String get settingsProfileSubtitle => 'Age, gender, activity and goals';

  @override
  String get settingsNotificationsSubtitle => 'Task reminders and rest alarm';

  @override
  String get settingsAppearanceLanguage => 'Appearance & Language';

  @override
  String get settingsAppearanceLanguageSubtitle => 'Theme and app language';

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
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsAdvancedSubtitle =>
      'Planner horizon, calorie adjustment, timers';

  @override
  String get settingsPlannerHorizonLabel => 'Planner look-ahead (days)';

  @override
  String get settingsCalorieAdjustmentLabel => 'Calorie goal adjustment (kcal)';

  @override
  String get settingsExperimentBaselineLabel => 'Experiment baseline (days)';

  @override
  String get settingsDefaultRestLabel => 'Default rest between sets (min)';

  @override
  String get settingsReminderLeadLabel => 'Pre-reminder lead (min)';

  @override
  String get settingsApiTimeoutLabel => 'Sync request timeout (s)';

  @override
  String get settingsPlannerHorizonHelp =>
      'How many days ahead recurring tasks are pre-created in the planner.';

  @override
  String get settingsCalorieAdjustmentHelp =>
      'kcal added to (gain) or subtracted from (lose) your daily calorie target.';

  @override
  String get settingsExperimentBaselineHelp =>
      'Days of history before an experiment starts, used as its comparison baseline.';

  @override
  String get settingsDefaultRestHelp =>
      'Prefills the rest field when adding a new set to a workout. Leave blank for none.';

  @override
  String get settingsReminderLeadHelp =>
      'Minutes before a task\'s start time when the advance notification fires.';

  @override
  String get settingsApiTimeoutHelp =>
      'How long sync requests wait for the server before giving up.';

  @override
  String get settingsValueInvalid => 'Enter a valid non-negative number.';

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
  String get ingredientFormBrandLabel => 'Brand';

  @override
  String get ingredientFormBarcodeLabel => 'Barcode';

  @override
  String get ingredientFormScanTile => 'Scan barcode';

  @override
  String get ingredientFormScanning => 'Scanning…';

  @override
  String get ingredientFormPicturesSection => 'Pictures';

  @override
  String get ingredientFormAddPicture => 'Add picture';

  @override
  String get ingredientDetailPricesTitle => 'Prices';

  @override
  String get ingredientDetailNoPrices => 'No prices recorded yet.';

  @override
  String ingredientDetailCostPerKg(String value) {
    return '$value /kg';
  }

  @override
  String get ingredientPriceAdd => 'Add price';

  @override
  String get ingredientPriceEdit => 'Edit price';

  @override
  String get ingredientPriceStoreLabel => 'Store';

  @override
  String get ingredientPriceAmountLabel => 'Price';

  @override
  String get ingredientPriceGramsLabel => 'Package size';

  @override
  String get ingredientPriceHistoryTitle => 'Price history';

  @override
  String get ingredientDetailManageStores => 'Manage stores';

  @override
  String get storeManagerTitle => 'Stores';

  @override
  String get storeManagerEmpty =>
      'No stores yet. Add one to start tracking prices.';

  @override
  String get storeManagerAddTile => 'Add store';

  @override
  String get storeNameLabel => 'Store name';

  @override
  String get storeNameRequired => 'Name is required';

  @override
  String get settingsFxAutoRefresh => 'Auto-refresh rates';

  @override
  String get settingsFxAutoRefreshSubtitle =>
      'Fetches exchange rates in the background';

  @override
  String get settingsFxRefreshInterval => 'Refresh interval';

  @override
  String get settingsExperimentReminders => 'Experiment reminders';

  @override
  String get settingsExperimentRemindersSubtitle =>
      'Daily check-in reminders while an experiment is running';

  @override
  String get settingsSyncServer => 'Sync server';

  @override
  String get settingsSyncServerHint =>
      'Point this at your sync server to pull exercises, ingredients and currencies. Leave empty to disable sync.';

  @override
  String get settingsSyncBaseUrl => 'Server URL';

  @override
  String get settingsSyncApiKey => 'API key';

  @override
  String get syncExercisesTooltip => 'Sync exercises';

  @override
  String get syncIngredientsTooltip => 'Sync ingredients';

  @override
  String get syncCurrenciesTooltip => 'Sync currencies';

  @override
  String get syncPushIngredientTooltip => 'Push to shared catalogue';

  @override
  String get syncServerNotConfigured => 'Sync server URL is not configured';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsWeightUnitLabel => 'Weight';

  @override
  String get settingsLengthUnitLabel => 'Height';

  @override
  String get settingsExportDb => 'Export database';

  @override
  String get settingsExportDbSubtitle => 'Share a copy of your data (SQLite)';

  @override
  String get settingsReplayPrefillLabel =>
      'When replaying a workout, prefill sets from';

  @override
  String get settingsReplayPrefillActuals => 'Previous actuals';

  @override
  String get settingsReplayPrefillPlanned => 'Planned values';

  @override
  String get workoutSummaryDoAgain => 'Do again';

  @override
  String get workoutActionReplay => 'Replay';

  @override
  String get workoutActionDuplicate => 'Duplicate';

  @override
  String workoutDetailPlannedSetReps(String reps, String weight, String unit) {
    return '$reps × $weight $unit';
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
  String workoutDetailActualSetReps(String reps, String weight, String unit) {
    return '$reps × $weight $unit';
  }

  @override
  String workoutDetailActualSetWeight(String weight, String unit) {
    return '$weight $unit';
  }

  @override
  String workoutDetailActualSetDuration(String reps) {
    return '$reps min';
  }

  @override
  String workoutDetailActualSetDistance(String distance) {
    return '$distance m';
  }

  @override
  String workoutDetailActualSetTime(String value, String time) {
    return '$value · $time';
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
  String bodyMetricsLatestWeight(String value, String unit) {
    return 'Latest: $value $unit';
  }

  @override
  String bodyMetricsLatestHeight(String value, String unit) {
    return 'Latest: $value $unit';
  }

  @override
  String bodyMetricsValueKg(String value, String unit) {
    return '$value $unit';
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
  String workoutSummaryValueKg(String value, String unit) {
    return '$value $unit';
  }

  @override
  String workoutSummaryDistanceValue(String distance) {
    return '$distance m';
  }

  @override
  String settingsRateRow(String target, num rate, String base) {
    return '$base → $target: $rate';
  }

  @override
  String settingsRateInverse(String base, String rate, String code) {
    return '1 $base = $rate $code';
  }

  @override
  String settingsRateUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get settingsRateManual => 'Manual';

  @override
  String transactionRateUsed(String rate, String base, String code) {
    return 'converted at $rate $base per $code';
  }

  @override
  String accountDeleteBlockedBody(int count) {
    return 'This account is used by $count transaction(s) and cannot be deleted.';
  }

  @override
  String get accountDeleteBlockedTitle => 'Account in use';

  @override
  String accountDeleteConfirmBody(String name) {
    return 'Deleting account \'$name\' will also delete its transactions and receipts.';
  }

  @override
  String get accountDeleteConfirmTitle => 'Delete account?';

  @override
  String get accountFormEditTitle => 'Edit account';

  @override
  String get accountFormNameLabel => 'Name';

  @override
  String get accountFormNameRequired => 'Enter a name';

  @override
  String get accountFormNewTitle => 'New account';

  @override
  String get accountFormOpeningHelper =>
      'How much was already in this account when you started tracking it. Leave 0 if you are not sure.';

  @override
  String get accountFormIntro => 'Track a wallet, bank account, or card.';

  @override
  String get accountFormNoteLabel => 'Account Form Note Label';

  @override
  String get accountFormOpeningLabel => 'Starting balance';

  @override
  String get accountFormTypeLabel => 'Type';

  @override
  String accountOpeningLabel(String value) {
    return 'Starting balance: $value';
  }

  @override
  String get accountReceipts => 'Receipts';

  @override
  String get accountTransactions => 'Transactions';

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeCredit => 'Credit card';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get accountTypeOther => 'Other';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get budgetAccounts => 'Accounts';

  @override
  String get budgetAdd => 'Budget Add';

  @override
  String get budgetEmptyBody => 'Budget Empty Body';

  @override
  String get budgetEmptyTitle => 'Budget Empty Title';

  @override
  String get budgetFabAccount => 'Budget Fab Account';

  @override
  String get budgetFabExpense => 'Budget Fab Expense';

  @override
  String get budgetFabIncome => 'Budget Fab Income';

  @override
  String get budgetFabTransfer => 'Budget Fab Transfer';

  @override
  String get budgetMonthExpense => 'Expenses this month';

  @override
  String get budgetMonthIncome => 'Income this month';

  @override
  String get budgetNoReceipts => 'No receipts yet';

  @override
  String get budgetNoTransactions => 'No transactions yet';

  @override
  String budgetPendingReceipts(int count) {
    return '$count receipt(s) awaiting review';
  }

  @override
  String get budgetRecentTransactions => 'Recent transactions';

  @override
  String get budgetThisMonth => 'Budget This Month';

  @override
  String get budgetViewAll => 'View all';

  @override
  String get commonDelete => 'Common Delete';

  @override
  String get receiptAppBar => 'Receipt';

  @override
  String get receiptCreateDraft => 'Create draft';

  @override
  String get receiptDeleteConfirmBody => 'Delete this receipt?';

  @override
  String get receiptDeleteConfirmTitle => 'Delete receipt?';

  @override
  String get receiptEmptyBody =>
      'No receipts yet. Take a photo of a receipt to start tracking.';

  @override
  String get receiptListAppBar => 'Receipts';

  @override
  String get receiptNotFound => 'Receipt not found';

  @override
  String get receiptNotParsed => 'Not parsed yet';

  @override
  String get receiptParsed => 'Parsed';

  @override
  String get receiptParsedData => 'Parsed data';

  @override
  String get receiptPickGallery => 'From gallery';

  @override
  String get receiptReviewDraft => 'Review draft';

  @override
  String receiptStatusLabel(String status) {
    return '$status';
  }

  @override
  String receiptStatusShort(String status) {
    return '$status';
  }

  @override
  String get receiptTakePhoto => 'Take photo';

  @override
  String get receiptUpload => 'Upload';

  @override
  String get settingsCurrencyBudget => 'Budget currency';

  @override
  String get settingsFxRates => 'Exchange rates';

  @override
  String get settingsFxRatesEmpty => 'No exchange rates configured';

  @override
  String get settingsFxRefresh => 'Refresh rates';

  @override
  String get settingsRateEdit => 'Edit rate';

  @override
  String get transactionAmountInvalid => 'Enter a valid amount';

  @override
  String get transactionCategoryLabel => 'Category';

  @override
  String transactionConvertedLabel(String amount) {
    return '≈ $amount in base currency';
  }

  @override
  String get transactionDraft => 'Draft';

  @override
  String get transactionDraftHint =>
      'Draft from a scanned receipt — check the details before saving';

  @override
  String get transactionHasReceipt => 'Receipt attached';

  @override
  String get transactionListAppBar => 'Transactions';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get budgetAppBar => 'Budget';

  @override
  String get budgetSubtitle => 'Accounts, transactions and receipts';

  @override
  String get budgetTotalBalance => 'Total balance';

  @override
  String get budgetNetWorth => 'Net worth';

  @override
  String get budgetIncomeLabel => 'Income';

  @override
  String get budgetExpenseLabel => 'Expense';

  @override
  String get budgetEmptyAccounts =>
      'No accounts yet. Add one to start tracking.';

  @override
  String get budgetAddAccount => 'Add account';

  @override
  String get budgetAddTransaction => 'Add transaction';

  @override
  String get accountFormTitleNew => 'New account';

  @override
  String get accountFormTitleEdit => 'Edit account';

  @override
  String get accountNameLabel => 'Name';

  @override
  String get accountTypeLabel => 'Type';

  @override
  String get accountCurrencyLabel => 'Currency';

  @override
  String get accountInitialBalanceLabel => 'Initial balance';

  @override
  String get accountSave => 'Save';

  @override
  String get accountDetailTitle => 'Account';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountTransactionsTitle => 'Transactions';

  @override
  String get accountBalanceLabel => 'Balance';

  @override
  String get accountEdit => 'Edit';

  @override
  String get transactionFormNewExpenseTitle => 'New expense';

  @override
  String get transactionFormNewIncomeTitle => 'New income';

  @override
  String get transactionFormTransferTitle => 'Transfer';

  @override
  String get transactionFormEditTitle => 'Edit transaction';

  @override
  String get transactionTypeLabel => 'Type';

  @override
  String get transactionAmountLabel => 'Amount';

  @override
  String get transactionCurrencyLabel => 'Currency';

  @override
  String get transactionDateLabel => 'Date';

  @override
  String get transactionNoteLabel => 'Note';

  @override
  String get transactionAccountLabel => 'Account';

  @override
  String get transactionToAccountLabel => 'To account';

  @override
  String get transactionReceiptLabel => 'Receipt';

  @override
  String get transactionSave => 'Save';

  @override
  String get transactionDelete => 'Delete';

  @override
  String get transactionDraftBadge => 'Draft';

  @override
  String get transactionConfirmDraft => 'Confirm';

  @override
  String get transactionTransferSameAccount =>
      'Transfer needs two different accounts.';

  @override
  String get transactionAccountRequired => 'An account is required.';

  @override
  String get transactionTransferAccountsRequired =>
      'Both accounts are required for a transfer.';

  @override
  String get transactionAmountPositive => 'Amount must be greater than zero.';

  @override
  String get receiptListTitle => 'Receipts';

  @override
  String get receiptCapture => 'Capture receipt';

  @override
  String get receiptCaptureStandalone => 'Standalone receipt';

  @override
  String get receiptUploadSuccess => 'Receipt uploaded';

  @override
  String get receiptUploadError => 'Failed to upload receipt';

  @override
  String get receiptViewTitle => 'Receipt';

  @override
  String get receiptStatusLocal => 'Local';

  @override
  String get receiptStatusUploading => 'Uploading';

  @override
  String get receiptStatusUploaded => 'Uploaded';

  @override
  String get receiptStatusError => 'Error';

  @override
  String get receiptAttach => 'Attach to transaction';

  @override
  String get receiptChooseSource => 'Choose source';

  @override
  String get receiptFromCamera => 'Camera';

  @override
  String get receiptFromGallery => 'Gallery';

  @override
  String get commonRetry => 'Retry';

  @override
  String get settingsBaseCurrency => 'Base currency';

  @override
  String get settingsCategoryFx => 'Exchange rates';

  @override
  String get settingsRefreshRates => 'Refresh rates';

  @override
  String get settingsEditRate => 'Edit rate';

  @override
  String settingsRateBase(Object base) {
    return 'Per 1 $base';
  }

  @override
  String get settingsRateInvalid => 'Enter a positive rate.';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabExperiments => 'Experiments';

  @override
  String get experimentsAppBar => 'Experiments';

  @override
  String get experimentsFab => 'New experiment';

  @override
  String get experimentsEmptyTitle => 'No experiments yet';

  @override
  String get experimentsEmptyBody =>
      'Create an experiment to track a habit, diet change, or training protocol with daily check-ins.';

  @override
  String get experimentsNoEndDate => 'Open-ended';

  @override
  String experimentDaysElapsed(int days) {
    return '$days days elapsed';
  }

  @override
  String get experimentStatusPlanned => 'Planned';

  @override
  String get experimentStatusActive => 'Active';

  @override
  String get experimentStatusDone => 'Done';

  @override
  String get experimentStatusAborted => 'Aborted';

  @override
  String get experimentCategoryWorkout => 'Workout';

  @override
  String get experimentCategoryDiet => 'Diet';

  @override
  String get experimentCategoryBody => 'Body';

  @override
  String get experimentCategorySteps => 'Steps';

  @override
  String get experimentFormTitleNew => 'New experiment';

  @override
  String get experimentFormTitleEdit => 'Edit experiment';

  @override
  String get experimentFormNameLabel => 'Name';

  @override
  String get experimentFormNameHint => 'e.g. 8-week hypertrophy block';

  @override
  String get experimentFormPurposeLabel => 'Hypothesis / purpose';

  @override
  String get experimentFormPurposeHint => 'What are you testing?';

  @override
  String get experimentFormStartLabel => 'Start date';

  @override
  String get experimentFormEndLabel => 'End date';

  @override
  String get experimentFormStatusLabel => 'Status';

  @override
  String get experimentFormCategoriesLabel => 'Tracked data';

  @override
  String get experimentFormReminderLabel => 'Daily check-in reminder';

  @override
  String get experimentFormReminderSubtitle =>
      'A notification opens this experiment for a quick rating.';

  @override
  String get experimentFormReminderTimeLabel => 'Reminder time';

  @override
  String get experimentFormDelete => 'Delete';

  @override
  String get experimentFormDeleteConfirmTitle => 'Delete experiment?';

  @override
  String get experimentFormDeleteConfirmBody =>
      'This also removes the experiment\'s check-ins.';

  @override
  String get experimentFormNameRequired => 'Give the experiment a name.';

  @override
  String get experimentFormInvalidDates =>
      'The end date must be on or after the start date.';

  @override
  String get experimentDetailCheckin => 'Check in';

  @override
  String get experimentDetailCheckinToday =>
      'You already checked in today. You can update it.';

  @override
  String get experimentDetailCheckinDialogTitle => 'Daily check-in';

  @override
  String get experimentDetailCheckinRatingLabel => 'Rating';

  @override
  String get experimentDetailCheckinRatingHint =>
      '1 = rough day, 5 = excellent day';

  @override
  String get experimentDetailCheckinNoteLabel => 'Note (optional)';

  @override
  String get experimentDetailCheckinNoteHint => 'How did it go?';

  @override
  String get experimentDetailProgressTitle => 'Progress';

  @override
  String get experimentDetailCheckinsTitle => 'Check-ins';

  @override
  String get experimentDetailTrackedTitle => 'Tracked data';

  @override
  String get experimentDetailBaselineTitle => '14-day baseline';

  @override
  String get experimentDetailNoData => 'No data for this period yet.';

  @override
  String get experimentDetailMarkDone => 'Mark done';

  @override
  String get experimentDetailAbort => 'Abort';

  @override
  String experimentDetailCheckinCount(int count) {
    return '$count check-ins';
  }

  @override
  String experimentRatingOf5(int rating) {
    return '$rating/5';
  }

  @override
  String get experimentChartWorkout => 'Workout volume (kg)';

  @override
  String get experimentChartDiet => 'Calories (kcal)';

  @override
  String get experimentChartDietProtein => 'Protein (g)';

  @override
  String get experimentChartWeight => 'Weight (kg)';

  @override
  String get experimentChartSteps => 'Steps';

  @override
  String experimentReminderTitle(String experiment) {
    return 'Check in on $experiment';
  }

  @override
  String get experimentReminderBody => 'Rate your day for this experiment.';

  @override
  String experimentReminderScheduled(String time) {
    return 'Daily reminder set for $time.';
  }

  @override
  String get experimentReminderCancelled => 'Daily reminder disabled.';
}
