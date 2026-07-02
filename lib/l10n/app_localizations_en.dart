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
  String get dashboardAppBar => 'Dashboard';

  @override
  String get dashboardTodayCalories => 'Today\'s Calories';

  @override
  String get dashboardLatestWorkout => 'Latest Workout';

  @override
  String get dashboardNoWorkouts => 'No completed workouts yet.';

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
  String get exerciseListAppBar => 'Exercises';

  @override
  String get exerciseListManageBtn => 'Manage Exercises';

  @override
  String get exerciseListEmpty => 'No exercises yet. Tap + to add one.';

  @override
  String get exerciseListDeleteTitle => 'Delete exercise?';

  @override
  String exerciseListDeleteConfirm(String name) {
    return 'Remove \"$name\"?';
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
  String get workoutListEmpty => 'No workouts yet. Tap + to add one.';

  @override
  String get workoutListDeleteTitle => 'Delete workout?';

  @override
  String workoutListDeleteConfirm(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get workoutFormTitle => 'New Workout';

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
  String get workoutDetailNoExercises => 'No exercises in this workout.';

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
  String get ingredientListAppBar => 'Ingredients';

  @override
  String get ingredientListEmpty => 'No ingredients yet. Tap + to add one.';

  @override
  String get ingredientListDeleteTitle => 'Delete ingredient?';

  @override
  String ingredientListDeleteConfirm(String name) {
    return 'Remove \"$name\"?';
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
  String get mealListEmpty => 'No meals yet. Tap + to add one.';

  @override
  String get mealListDeleteTitle => 'Delete meal?';

  @override
  String mealListDeleteConfirm(String name) {
    return 'Remove \"$name\"?';
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
  String get settingsAppBar => 'Settings';

  @override
  String get settingsBody => 'Settings';

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
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

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
}
