import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FitFat'**
  String get appTitle;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get tabExercise;

  /// No description provided for @tabDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get tabDiet;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @dashboardAppBar.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardAppBar;

  /// No description provided for @dashboardTodayCalories.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Calories'**
  String get dashboardTodayCalories;

  /// No description provided for @dashboardLatestWorkout.
  ///
  /// In en, this message translates to:
  /// **'Latest Workout'**
  String get dashboardLatestWorkout;

  /// No description provided for @dashboardNoWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts yet.'**
  String get dashboardNoWorkouts;

  /// No description provided for @dashboardDurationMin.
  ///
  /// In en, this message translates to:
  /// **'Duration: {minutes} min'**
  String dashboardDurationMin(int minutes);

  /// No description provided for @dashboardCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String dashboardCaloriesValue(String calories);

  /// No description provided for @dashboardError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String dashboardError(String message);

  /// No description provided for @exerciseListAppBar.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exerciseListAppBar;

  /// No description provided for @exerciseListManageBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage Exercises'**
  String get exerciseListManageBtn;

  /// No description provided for @exerciseListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet. Tap + to add one.'**
  String get exerciseListEmpty;

  /// No description provided for @exerciseListDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise?'**
  String get exerciseListDeleteTitle;

  /// No description provided for @exerciseListDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String exerciseListDeleteConfirm(String name);

  /// No description provided for @exerciseFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Exercise'**
  String get exerciseFormNewTitle;

  /// No description provided for @exerciseFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get exerciseFormEditTitle;

  /// No description provided for @exerciseFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseFormNameLabel;

  /// No description provided for @exerciseFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bench Press'**
  String get exerciseFormNameHint;

  /// No description provided for @exerciseFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get exerciseFormNameRequired;

  /// No description provided for @exerciseFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get exerciseFormTypeLabel;

  /// No description provided for @exerciseFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get exerciseFormSave;

  /// No description provided for @exerciseFormSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get exerciseFormSaving;

  /// No description provided for @workoutListAppBar.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutListAppBar;

  /// No description provided for @workoutListManageBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage Exercises'**
  String get workoutListManageBtn;

  /// No description provided for @workoutListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet. Tap + to add one.'**
  String get workoutListEmpty;

  /// No description provided for @workoutListDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get workoutListDeleteTitle;

  /// No description provided for @workoutListDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String workoutListDeleteConfirm(String name);

  /// No description provided for @workoutFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New Workout'**
  String get workoutFormTitle;

  /// No description provided for @workoutFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout Name'**
  String get workoutFormNameLabel;

  /// No description provided for @workoutFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Morning Push'**
  String get workoutFormNameHint;

  /// No description provided for @workoutFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get workoutFormNameRequired;

  /// No description provided for @workoutFormDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get workoutFormDate;

  /// No description provided for @workoutFormExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get workoutFormExercises;

  /// No description provided for @workoutFormNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises available. Add some first.'**
  String get workoutFormNoExercises;

  /// No description provided for @workoutFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get workoutFormSave;

  /// No description provided for @workoutFormSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get workoutFormSaving;

  /// No description provided for @workoutFormAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get workoutFormAddSet;

  /// No description provided for @workoutFormRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutFormRepsLabel;

  /// No description provided for @workoutFormWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get workoutFormWeightLabel;

  /// No description provided for @workoutFormDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get workoutFormDurationLabel;

  /// No description provided for @workoutFormSelectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select at least one exercise'**
  String get workoutFormSelectExercise;

  /// No description provided for @workoutDetailAppBar.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutDetailAppBar;

  /// No description provided for @workoutDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found'**
  String get workoutDetailNotFound;

  /// No description provided for @workoutDetailBtnStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get workoutDetailBtnStart;

  /// No description provided for @workoutDetailBtnComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get workoutDetailBtnComplete;

  /// No description provided for @workoutDetailStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started: {time}'**
  String workoutDetailStartedAt(String time);

  /// No description provided for @workoutDetailExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get workoutDetailExercises;

  /// No description provided for @workoutDetailNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises in this workout.'**
  String get workoutDetailNoExercises;

  /// No description provided for @workoutDetailSetHeaderHash.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get workoutDetailSetHeaderHash;

  /// No description provided for @workoutDetailSetHeaderPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get workoutDetailSetHeaderPlanned;

  /// No description provided for @workoutDetailSetHeaderActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get workoutDetailSetHeaderActual;

  /// No description provided for @workoutDetailSetActualsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set {number} — Actuals'**
  String workoutDetailSetActualsTitle(int number);

  /// No description provided for @workoutDetailActualRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual Reps'**
  String get workoutDetailActualRepsLabel;

  /// No description provided for @workoutDetailActualWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual Weight (kg)'**
  String get workoutDetailActualWeightLabel;

  /// No description provided for @workoutDetailActualDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get workoutDetailActualDurationLabel;

  /// No description provided for @workoutDetailActualDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance (m)'**
  String get workoutDetailActualDistanceLabel;

  /// No description provided for @workoutDetailSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} set'**
  String workoutDetailSetCount(int count);

  /// No description provided for @workoutDetailSetCount_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String workoutDetailSetCount_plural(Object count);

  /// No description provided for @ingredientListAppBar.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientListAppBar;

  /// No description provided for @ingredientListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ingredients yet. Tap + to add one.'**
  String get ingredientListEmpty;

  /// No description provided for @ingredientListDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ingredient?'**
  String get ingredientListDeleteTitle;

  /// No description provided for @ingredientListDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String ingredientListDeleteConfirm(String name);

  /// No description provided for @ingredientFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Ingredient'**
  String get ingredientFormNewTitle;

  /// No description provided for @ingredientFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get ingredientFormEditTitle;

  /// No description provided for @ingredientFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ingredientFormNameLabel;

  /// No description provided for @ingredientFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chicken Breast'**
  String get ingredientFormNameHint;

  /// No description provided for @ingredientFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get ingredientFormNameRequired;

  /// No description provided for @ingredientFormCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (per 100g)'**
  String get ingredientFormCaloriesLabel;

  /// No description provided for @ingredientFormCaloriesSuffix.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get ingredientFormCaloriesSuffix;

  /// No description provided for @ingredientFormProteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein (per 100g)'**
  String get ingredientFormProteinLabel;

  /// No description provided for @ingredientFormProteinSuffix.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get ingredientFormProteinSuffix;

  /// No description provided for @ingredientFormCarbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs (per 100g)'**
  String get ingredientFormCarbsLabel;

  /// No description provided for @ingredientFormCarbsSuffix.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get ingredientFormCarbsSuffix;

  /// No description provided for @ingredientFormFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat (per 100g)'**
  String get ingredientFormFatLabel;

  /// No description provided for @ingredientFormFatSuffix.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get ingredientFormFatSuffix;

  /// No description provided for @ingredientFormFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String ingredientFormFieldRequired(String label);

  /// No description provided for @ingredientFormFieldPositive.
  ///
  /// In en, this message translates to:
  /// **'{label} must be positive'**
  String ingredientFormFieldPositive(String label);

  /// No description provided for @ingredientFormFieldNonNegative.
  ///
  /// In en, this message translates to:
  /// **'{label} cannot be negative'**
  String ingredientFormFieldNonNegative(String label);

  /// No description provided for @mealListAppBar.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get mealListAppBar;

  /// No description provided for @mealListManageBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage Ingredients'**
  String get mealListManageBtn;

  /// No description provided for @mealListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meals yet. Tap + to add one.'**
  String get mealListEmpty;

  /// No description provided for @mealListDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete meal?'**
  String get mealListDeleteTitle;

  /// No description provided for @mealListDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String mealListDeleteConfirm(String name);

  /// No description provided for @mealListIngredientCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ingredient'**
  String mealListIngredientCount(int count);

  /// No description provided for @mealListIngredientCount_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} ingredients'**
  String mealListIngredientCount_plural(Object count);

  /// No description provided for @mealListCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String mealListCaloriesValue(String calories);

  /// No description provided for @mealListMacroFormat.
  ///
  /// In en, this message translates to:
  /// **'{grams}g  ·  {calories} kcal  ·  P {protein}g  ·  C {carbs}g  ·  F {fat}g'**
  String mealListMacroFormat(
    String grams,
    String calories,
    String protein,
    String carbs,
    String fat,
  );

  /// No description provided for @mealFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Meal'**
  String get mealFormNewTitle;

  /// No description provided for @mealFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Meal'**
  String get mealFormEditTitle;

  /// No description provided for @mealFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal Name'**
  String get mealFormNameLabel;

  /// No description provided for @mealFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Breakfast'**
  String get mealFormNameHint;

  /// No description provided for @mealFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get mealFormNameRequired;

  /// No description provided for @mealFormDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get mealFormDateTime;

  /// No description provided for @mealFormIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get mealFormIngredients;

  /// No description provided for @mealFormNoIngredients.
  ///
  /// In en, this message translates to:
  /// **'No ingredients available. Add some first.'**
  String get mealFormNoIngredients;

  /// No description provided for @mealFormAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient with grams'**
  String get mealFormAddIngredient;

  /// No description provided for @mealFormGramsLabel.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get mealFormGramsLabel;

  /// No description provided for @mealFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mealFormSave;

  /// No description provided for @mealFormSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get mealFormSaving;

  /// No description provided for @settingsAppBar.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAppBar;

  /// No description provided for @settingsBody.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsBody;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @exerciseTypeWeightlifting.
  ///
  /// In en, this message translates to:
  /// **'Weightlifting'**
  String get exerciseTypeWeightlifting;

  /// No description provided for @exerciseTypeCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get exerciseTypeCardio;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @errorLoadingResource.
  ///
  /// In en, this message translates to:
  /// **'Error loading {resource}: {message}'**
  String errorLoadingResource(String resource, String message);

  /// No description provided for @macroGrams.
  ///
  /// In en, this message translates to:
  /// **'{value}g'**
  String macroGrams(String value);

  /// No description provided for @macroKcal.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String macroKcal(String value);

  /// No description provided for @ingredientMacroRow.
  ///
  /// In en, this message translates to:
  /// **'{grams}g  ·  {calories} kcal  ·  P {protein}g  ·  C {carbs}g  ·  F {fat}g'**
  String ingredientMacroRow(
    String grams,
    String calories,
    String protein,
    String carbs,
    String fat,
  );

  /// No description provided for @workoutDetailPlannedSetReps.
  ///
  /// In en, this message translates to:
  /// **'{reps} × {weight} kg'**
  String workoutDetailPlannedSetReps(String reps, String weight);

  /// No description provided for @workoutDetailPlannedSetDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String workoutDetailPlannedSetDuration(String minutes);

  /// No description provided for @workoutDetailPlannedSetEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get workoutDetailPlannedSetEmpty;

  /// No description provided for @workoutDetailActualSetReps.
  ///
  /// In en, this message translates to:
  /// **'{reps} × {weight} kg'**
  String workoutDetailActualSetReps(String reps, String weight);

  /// No description provided for @workoutDetailActualSetWeight.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String workoutDetailActualSetWeight(String weight);

  /// No description provided for @workoutDetailActualSetDuration.
  ///
  /// In en, this message translates to:
  /// **'{reps} min'**
  String workoutDetailActualSetDuration(String reps);

  /// No description provided for @workoutDetailActualSetEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get workoutDetailActualSetEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
