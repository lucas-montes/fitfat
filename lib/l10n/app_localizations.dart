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
  /// **'fitfat'**
  String get appTitle;

  /// No description provided for @mealsTab.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get mealsTab;

  /// No description provided for @ingredientsTab.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTab;

  /// No description provided for @addMeal.
  ///
  /// In en, this message translates to:
  /// **'Add Meal'**
  String get addMeal;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// No description provided for @editIngredient.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get editIngredient;

  /// No description provided for @editMeal.
  ///
  /// In en, this message translates to:
  /// **'Edit Meal'**
  String get editMeal;

  /// No description provided for @archivedIngredients.
  ///
  /// In en, this message translates to:
  /// **'Archived Ingredients'**
  String get archivedIngredients;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @ingredientName.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name'**
  String get ingredientName;

  /// No description provided for @buildFromIngredients.
  ///
  /// In en, this message translates to:
  /// **'Build from ingredients'**
  String get buildFromIngredients;

  /// No description provided for @components.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get components;

  /// No description provided for @noComponentsAdded.
  ///
  /// In en, this message translates to:
  /// **'No components added yet'**
  String get noComponentsAdded;

  /// No description provided for @addComponents.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients'**
  String get addComponents;

  /// No description provided for @searchIngredients.
  ///
  /// In en, this message translates to:
  /// **'Search ingredients'**
  String get searchIngredients;

  /// No description provided for @typeToSearchIngredient.
  ///
  /// In en, this message translates to:
  /// **'Type to search ingredients'**
  String get typeToSearchIngredient;

  /// No description provided for @caloriesPer100g.
  ///
  /// In en, this message translates to:
  /// **'Calories per 100g'**
  String get caloriesPer100g;

  /// No description provided for @proteinPer100g.
  ///
  /// In en, this message translates to:
  /// **'Protein per 100g (g)'**
  String get proteinPer100g;

  /// No description provided for @carbsPer100g.
  ///
  /// In en, this message translates to:
  /// **'Carbs per 100g (g)'**
  String get carbsPer100g;

  /// No description provided for @fatPer100g.
  ///
  /// In en, this message translates to:
  /// **'Fat per 100g (g)'**
  String get fatPer100g;

  /// No description provided for @sodiumPer100g.
  ///
  /// In en, this message translates to:
  /// **'Sodium per 100g (mg)'**
  String get sodiumPer100g;

  /// No description provided for @fiberPer100g.
  ///
  /// In en, this message translates to:
  /// **'Fiber per 100g (g)'**
  String get fiberPer100g;

  /// No description provided for @amountInGrams.
  ///
  /// In en, this message translates to:
  /// **'Amount in grams'**
  String get amountInGrams;

  /// No description provided for @gramsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 80'**
  String get gramsHint;

  /// No description provided for @gramsHintMeal.
  ///
  /// In en, this message translates to:
  /// **'e.g. 120'**
  String get gramsHintMeal;

  /// No description provided for @createNewIngredient.
  ///
  /// In en, this message translates to:
  /// **'Create new ingredient'**
  String get createNewIngredient;

  /// No description provided for @mealNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Meal name (optional)'**
  String get mealNameOptional;

  /// No description provided for @selectedIngredients.
  ///
  /// In en, this message translates to:
  /// **'Selected ingredients'**
  String get selectedIngredients;

  /// No description provided for @noIngredientsSelected.
  ///
  /// In en, this message translates to:
  /// **'No ingredients selected yet'**
  String get noIngredientsSelected;

  /// No description provided for @noIngredientsFound.
  ///
  /// In en, this message translates to:
  /// **'No ingredients found'**
  String get noIngredientsFound;

  /// No description provided for @archiveIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Ingredient'**
  String get archiveIngredientTitle;

  /// No description provided for @archiveIngredientContent.
  ///
  /// In en, this message translates to:
  /// **'This ingredient will be hidden from regular views. Use the Archived Ingredients tab to restore or delete it.'**
  String get archiveIngredientContent;

  /// No description provided for @deleteMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete meal?'**
  String get deleteMealTitle;

  /// No description provided for @deleteMealContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the meal from your log.'**
  String get deleteMealContent;

  /// No description provided for @deleteIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ingredient?'**
  String get deleteIngredientTitle;

  /// No description provided for @deleteIngredientContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the ingredient and any portions from meals.'**
  String get deleteIngredientContent;

  /// No description provided for @permanentlyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Ingredient'**
  String get permanentlyDeleteTitle;

  /// No description provided for @permanentlyDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This ingredient will be deleted permanently. It cannot be restored.'**
  String get permanentlyDeleteContent;

  /// No description provided for @restoreIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Ingredient'**
  String get restoreIngredientTitle;

  /// No description provided for @deleteMealTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get deleteMealTooltip;

  /// No description provided for @deleteIngredientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteIngredientTooltip;

  /// No description provided for @ingredientArchived.
  ///
  /// In en, this message translates to:
  /// **'Ingredient archived successfully'**
  String get ingredientArchived;

  /// No description provided for @ingredientDeleted.
  ///
  /// In en, this message translates to:
  /// **'Ingredient deleted successfully'**
  String get ingredientDeleted;

  /// No description provided for @ingredientRestored.
  ///
  /// In en, this message translates to:
  /// **'Ingredient restored successfully'**
  String get ingredientRestored;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal;

  /// No description provided for @sortAZ.
  ///
  /// In en, this message translates to:
  /// **'Sort A-Z'**
  String get sortAZ;

  /// No description provided for @sortZA.
  ///
  /// In en, this message translates to:
  /// **'Sort Z-A'**
  String get sortZA;

  /// No description provided for @noIngredientsFoundSubtext.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or add a new ingredient'**
  String get noIngredientsFoundSubtext;

  /// No description provided for @kcalAbbrev.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalAbbrev;

  /// No description provided for @proteinAbbrev.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get proteinAbbrev;

  /// No description provided for @carbsAbbrev.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get carbsAbbrev;

  /// No description provided for @fatAbbrev.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get fatAbbrev;

  /// No description provided for @eatenAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Eaten at: {time}'**
  String eatenAtLabel(Object time);

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save meal: {error}'**
  String failedToSave(Object error);

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update meal: {error}'**
  String failedToUpdate(Object error);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} item} other{{count} items}}'**
  String items(int count);

  /// No description provided for @formatMacros.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · P {protein}g · C {carbs}g · F {fat}g'**
  String formatMacros(Object kcal, Object protein, Object carbs, Object fat);

  /// No description provided for @formatPer100g.
  ///
  /// In en, this message translates to:
  /// **'Per 100g: {kcal} kcal · P {protein}g · C {carbs}g · F {fat}g'**
  String formatPer100g(Object kcal, Object protein, Object carbs, Object fat);

  /// No description provided for @formatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String formatTotal(Object total);

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @activeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Active Workout'**
  String get activeWorkout;

  /// No description provided for @noActiveSeance.
  ///
  /// In en, this message translates to:
  /// **'No active workout'**
  String get noActiveSeance;

  /// No description provided for @guidedMode.
  ///
  /// In en, this message translates to:
  /// **'Guided'**
  String get guidedMode;

  /// No description provided for @freeformMode.
  ///
  /// In en, this message translates to:
  /// **'Free-form'**
  String get freeformMode;

  /// No description provided for @cancelSeance.
  ///
  /// In en, this message translates to:
  /// **'Cancel workout'**
  String get cancelSeance;

  /// No description provided for @backToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to app'**
  String get backToApp;

  /// No description provided for @discardEmptySeance.
  ///
  /// In en, this message translates to:
  /// **'Discard empty workout?'**
  String get discardEmptySeance;

  /// No description provided for @discardEmptySeanceContent.
  ///
  /// In en, this message translates to:
  /// **'This workout has no exercises and will not be saved to history.'**
  String get discardEmptySeanceContent;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @completeSeance.
  ///
  /// In en, this message translates to:
  /// **'Complete Workout'**
  String get completeSeance;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExercise;

  /// No description provided for @followPlan.
  ///
  /// In en, this message translates to:
  /// **'Follow the plan'**
  String get followPlan;

  /// No description provided for @searchToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search to add'**
  String get searchToAdd;

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercises;

  /// No description provided for @exerciseTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search exercises...'**
  String get exerciseTypeToSearch;

  /// No description provided for @typeToFindExercises.
  ///
  /// In en, this message translates to:
  /// **'Type to find exercises...'**
  String get typeToFindExercises;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @setsLower.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get setsLower;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get done;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @totalReps.
  ///
  /// In en, this message translates to:
  /// **'Total Reps'**
  String get totalReps;

  /// No description provided for @totalWeight.
  ///
  /// In en, this message translates to:
  /// **'Total Weight'**
  String get totalWeight;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// No description provided for @tapToComplete.
  ///
  /// In en, this message translates to:
  /// **'Tap to complete'**
  String get tapToComplete;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found matching'**
  String get noExercisesFound;

  /// No description provided for @repsLower.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsLower;

  /// No description provided for @preFilledFrom.
  ///
  /// In en, this message translates to:
  /// **'Pre-filled from'**
  String get preFilledFrom;

  /// No description provided for @allSetsComplete.
  ///
  /// In en, this message translates to:
  /// **'All sets complete!'**
  String get allSetsComplete;

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get restTimer;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @restOver.
  ///
  /// In en, this message translates to:
  /// **'Rest over!'**
  String get restOver;

  /// No description provided for @getReadyNextSet.
  ///
  /// In en, this message translates to:
  /// **'Get ready for your next set!'**
  String get getReadyNextSet;

  /// No description provided for @editSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Set'**
  String get editSet;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistory;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get searchHistory;

  /// No description provided for @searchByDateHint.
  ///
  /// In en, this message translates to:
  /// **'Search by date or workout name...'**
  String get searchByDateHint;

  /// No description provided for @volumeProgression.
  ///
  /// In en, this message translates to:
  /// **'Volume Progression'**
  String get volumeProgression;

  /// No description provided for @estimated1RM.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM Progression'**
  String get estimated1RM;

  /// No description provided for @bestEstimated1RM.
  ///
  /// In en, this message translates to:
  /// **'Best Estimated 1RM'**
  String get bestEstimated1RM;

  /// No description provided for @maxWeight.
  ///
  /// In en, this message translates to:
  /// **'Max Weight'**
  String get maxWeight;

  /// No description provided for @maxVolume.
  ///
  /// In en, this message translates to:
  /// **'Max Volume (Set)'**
  String get maxVolume;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// No description provided for @noHistoryContent.
  ///
  /// In en, this message translates to:
  /// **'Complete a workout with this exercise to see it here'**
  String get noHistoryContent;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @createExercise.
  ///
  /// In en, this message translates to:
  /// **'Create Exercise'**
  String get createExercise;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} exercise} other{{count} exercises}}'**
  String exercisesCount(int count);

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} set} other{{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @workoutsTab.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsTab;

  /// No description provided for @trainingTab.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get trainingTab;

  /// No description provided for @quickLog.
  ///
  /// In en, this message translates to:
  /// **'Quick Log'**
  String get quickLog;

  /// No description provided for @followTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Follow today\'s plan'**
  String get followTodaysPlan;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @searchExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises...'**
  String get searchExercisesHint;

  /// No description provided for @noExercisesFoundSimple.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFoundSimple;

  /// No description provided for @noExercisesFoundAction.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear filters'**
  String get noExercisesFoundAction;

  /// No description provided for @cardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardio;

  /// No description provided for @weightlifting.
  ///
  /// In en, this message translates to:
  /// **'Weightlifting'**
  String get weightlifting;

  /// No description provided for @cardioDuration.
  ///
  /// In en, this message translates to:
  /// **'Cardio Duration'**
  String get cardioDuration;

  /// No description provided for @minutesLower.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesLower;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @setDuration.
  ///
  /// In en, this message translates to:
  /// **'Set Duration'**
  String get setDuration;

  /// No description provided for @quickLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Log'**
  String get quickLogTitle;

  /// No description provided for @quickLogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type to search exercises...'**
  String get quickLogSearchHint;

  /// No description provided for @quickLogSelectExercise.
  ///
  /// In en, this message translates to:
  /// **'Please select an exercise'**
  String get quickLogSelectExercise;

  /// No description provided for @quickLogEnterDuration.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid duration'**
  String get quickLogEnterDuration;

  /// No description provided for @quickLogEnterReps.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number of reps'**
  String get quickLogEnterReps;

  /// No description provided for @quickLogEnterWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get quickLogEnterWeight;

  /// No description provided for @quickLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout logged!'**
  String get quickLogSaved;

  /// No description provided for @quickLogDurationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 30'**
  String get quickLogDurationHint;

  /// No description provided for @quickLogRepsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get quickLogRepsHint;

  /// No description provided for @quickLogWeightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get quickLogWeightHint;

  /// No description provided for @quickLogNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get quickLogNotes;

  /// No description provided for @quickLogNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes...'**
  String get quickLogNotesHint;

  /// No description provided for @logWorkout.
  ///
  /// In en, this message translates to:
  /// **'Log Workout'**
  String get logWorkout;

  /// No description provided for @noPlannedWorkoutsForDay.
  ///
  /// In en, this message translates to:
  /// **'No planned workouts for this day'**
  String get noPlannedWorkoutsForDay;

  /// No description provided for @addPlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add planned workout'**
  String get addPlannedWorkout;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @startPlan.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPlan;

  /// No description provided for @deletePlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Delete planned workout'**
  String get deletePlannedWorkout;

  /// No description provided for @deletePlannedWorkoutContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this planned workout?'**
  String get deletePlannedWorkoutContent;

  /// No description provided for @noTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get noTemplatesAvailable;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select template'**
  String get selectTemplate;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @enterWorkoutName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a workout name'**
  String get enterWorkoutName;

  /// No description provided for @addAtLeastOneExercise.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one exercise'**
  String get addAtLeastOneExercise;

  /// No description provided for @plannedWorkoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Planned workout saved!'**
  String get plannedWorkoutSaved;

  /// No description provided for @editPlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Edit planned workout'**
  String get editPlannedWorkout;

  /// No description provided for @planWorkout.
  ///
  /// In en, this message translates to:
  /// **'Plan workout'**
  String get planWorkout;

  /// No description provided for @workoutName.
  ///
  /// In en, this message translates to:
  /// **'Workout name'**
  String get workoutName;

  /// No description provided for @copyFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Copy from template'**
  String get copyFromTemplate;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get savePlan;

  /// No description provided for @runningWorkout.
  ///
  /// In en, this message translates to:
  /// **'Running Workout'**
  String get runningWorkout;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume Workout'**
  String get resumeWorkout;

  /// No description provided for @viewWorkout.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewWorkout;

  /// No description provided for @stopWorkout.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopWorkout;

  /// No description provided for @newSeance.
  ///
  /// In en, this message translates to:
  /// **'New Workout'**
  String get newSeance;

  /// No description provided for @startBlankSeance.
  ///
  /// In en, this message translates to:
  /// **'Start Blank Workout'**
  String get startBlankSeance;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet. Create one to quickly start a workout!'**
  String get noTemplatesYet;

  /// No description provided for @browseAllTemplates.
  ///
  /// In en, this message translates to:
  /// **'Browse all templates'**
  String get browseAllTemplates;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet. Start your first one above!'**
  String get noWorkoutsYet;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @clone.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get clone;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @createTemplateFrom.
  ///
  /// In en, this message translates to:
  /// **'Create template from this'**
  String get createTemplateFrom;

  /// No description provided for @workoutAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'Workout already running'**
  String get workoutAlreadyRunning;

  /// No description provided for @workoutAlreadyRunningContent.
  ///
  /// In en, this message translates to:
  /// **'A workout is already in progress. Cancel it and start a new one?'**
  String get workoutAlreadyRunningContent;

  /// No description provided for @startNewWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start new workout'**
  String get startNewWorkout;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @noExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercises;

  /// No description provided for @pr.
  ///
  /// In en, this message translates to:
  /// **'PR!'**
  String get pr;

  /// No description provided for @oneRM.
  ///
  /// In en, this message translates to:
  /// **'e1RM'**
  String get oneRM;

  /// No description provided for @workoutSummary.
  ///
  /// In en, this message translates to:
  /// **'Workout Summary'**
  String get workoutSummary;

  /// No description provided for @exerciseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Exercise Breakdown'**
  String get exerciseBreakdown;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @previousSessions.
  ///
  /// In en, this message translates to:
  /// **'Previous sessions ({count})'**
  String previousSessions(int count);

  /// No description provided for @tapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get tapToExpand;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @templateLibrary.
  ///
  /// In en, this message translates to:
  /// **'Template Library'**
  String get templateLibrary;

  /// No description provided for @createFirstTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create your first template'**
  String get createFirstTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// No description provided for @templateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateNameLabel;

  /// No description provided for @addCustom.
  ///
  /// In en, this message translates to:
  /// **'Add as custom'**
  String get addCustom;

  /// No description provided for @searchAboveHint.
  ///
  /// In en, this message translates to:
  /// **'Search an exercise above to add it. Tap an exercise in the list to configure sets and reps.'**
  String get searchAboveHint;

  /// No description provided for @noExercisesAdded.
  ///
  /// In en, this message translates to:
  /// **'No exercises added yet'**
  String get noExercisesAdded;

  /// No description provided for @noSetsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No sets configured — tap to edit'**
  String get noSetsConfigured;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @restSeconds.
  ///
  /// In en, this message translates to:
  /// **'Rest (s)'**
  String get restSeconds;

  /// No description provided for @pastMonth.
  ///
  /// In en, this message translates to:
  /// **'Past month'**
  String get pastMonth;

  /// No description provided for @past3Months.
  ///
  /// In en, this message translates to:
  /// **'Past 3 months'**
  String get past3Months;

  /// No description provided for @pastYear.
  ///
  /// In en, this message translates to:
  /// **'Past year'**
  String get pastYear;

  /// No description provided for @noHistoryFor.
  ///
  /// In en, this message translates to:
  /// **'No history for {name} yet'**
  String noHistoryFor(Object name);

  /// No description provided for @completeWorkoutToSee.
  ///
  /// In en, this message translates to:
  /// **'Complete a workout with this exercise to see it here'**
  String get completeWorkoutToSee;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @searchByDateWorkout.
  ///
  /// In en, this message translates to:
  /// **'Search by date or workout name...'**
  String get searchByDateWorkout;

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, one{{count} session} other{{count} sessions}}'**
  String sessionsCount(num count);

  /// No description provided for @maxVolumeSet.
  ///
  /// In en, this message translates to:
  /// **'Max Volume (Set)'**
  String get maxVolumeSet;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @across.
  ///
  /// In en, this message translates to:
  /// **'Across'**
  String get across;

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @goalsTab.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @weightLogged.
  ///
  /// In en, this message translates to:
  /// **'Weight logged!'**
  String get weightLogged;

  /// No description provided for @enterWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Enter weight (kg)'**
  String get enterWeightKg;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @weightTracker.
  ///
  /// In en, this message translates to:
  /// **'Weight Tracker'**
  String get weightTracker;

  /// No description provided for @noWeightEntries.
  ///
  /// In en, this message translates to:
  /// **'No weight entries yet.'**
  String get noWeightEntries;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @logWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get logWeight;

  /// No description provided for @historyLast7Entries.
  ///
  /// In en, this message translates to:
  /// **'History (last 7 entries)'**
  String get historyLast7Entries;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntake;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @setDailyWaterGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Water Goal'**
  String get setDailyWaterGoal;

  /// No description provided for @litersExample.
  ///
  /// In en, this message translates to:
  /// **'Liters (e.g., 2.5)'**
  String get litersExample;

  /// No description provided for @todaysActivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activity'**
  String get todaysActivity;

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get workoutInProgress;

  /// No description provided for @exercisesCompleted.
  ///
  /// In en, this message translates to:
  /// **'exercises completed'**
  String get exercisesCompleted;

  /// No description provided for @noWorkoutsToday.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet. Start a session to see today\'s summary here.'**
  String get noWorkoutsToday;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get elapsed;

  /// No description provided for @last84Days.
  ///
  /// In en, this message translates to:
  /// **'Last 84 days'**
  String get last84Days;

  /// No description provided for @noTrainingRecorded.
  ///
  /// In en, this message translates to:
  /// **'No training recorded on this day.'**
  String get noTrainingRecorded;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @setProfileForTargets.
  ///
  /// In en, this message translates to:
  /// **'Set a bodyweight goal and your profile to see daily targets.'**
  String get setProfileForTargets;

  /// No description provided for @bodyWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Body Weight Goal'**
  String get bodyWeightGoal;

  /// No description provided for @noBodyweightGoalSet.
  ///
  /// In en, this message translates to:
  /// **'No bodyweight goal set.'**
  String get noBodyweightGoalSet;

  /// No description provided for @addBodyWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Body Weight Goal'**
  String get addBodyWeightGoal;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get by;

  /// No description provided for @strengthGoals.
  ///
  /// In en, this message translates to:
  /// **'Strength Goals'**
  String get strengthGoals;

  /// No description provided for @addStrengthGoalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add strength goal'**
  String get addStrengthGoalTooltip;

  /// No description provided for @noStrengthGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No strength goals yet. Tap + to add (one per exercise).'**
  String get noStrengthGoalsYet;

  /// No description provided for @setUpProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile first'**
  String get setUpProfileFirst;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @birthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sex;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get activityLevel;

  /// No description provided for @addBodyWeightGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Body Weight Goal'**
  String get addBodyWeightGoalTitle;

  /// No description provided for @editBodyWeightGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Body Weight Goal'**
  String get editBodyWeightGoalTitle;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @targetWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Target Weight (kg)'**
  String get targetWeightKg;

  /// No description provided for @targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get targetDate;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @addStrengthGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Strength Goal'**
  String get addStrengthGoalTitle;

  /// No description provided for @editStrengthGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Strength Goal'**
  String get editStrengthGoalTitle;

  /// No description provided for @searchOrTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Search or type custom name'**
  String get searchOrTypeCustom;

  /// No description provided for @deleteBodyweightGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete bodyweight goal?'**
  String get deleteBodyweightGoal;

  /// No description provided for @deleteBodyweightGoalContent.
  ///
  /// In en, this message translates to:
  /// **'This will clear your weight target and macro targets.'**
  String get deleteBodyweightGoalContent;

  /// No description provided for @deleteStrengthGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete strength goal for {exercise}?'**
  String deleteStrengthGoalTitle(Object exercise);

  /// No description provided for @deleteStrengthGoalContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the goal.'**
  String get deleteStrengthGoalContent;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteEverything;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get goalReached;

  /// No description provided for @toGo.
  ///
  /// In en, this message translates to:
  /// **'to go'**
  String get toGo;

  /// No description provided for @strengthTrend.
  ///
  /// In en, this message translates to:
  /// **'Strength Trend'**
  String get strengthTrend;

  /// No description provided for @noStrengthData.
  ///
  /// In en, this message translates to:
  /// **'No strength data'**
  String get noStrengthData;

  /// No description provided for @weightTrend90Days.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend (90 days)'**
  String get weightTrend90Days;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @setUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up Profile'**
  String get setUpProfile;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @visibleMacros.
  ///
  /// In en, this message translates to:
  /// **'Visible macros'**
  String get visibleMacros;

  /// No description provided for @defaultRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Default rest timer'**
  String get defaultRestTimer;

  /// No description provided for @secondsBetweenSets.
  ///
  /// In en, this message translates to:
  /// **'60 seconds between sets'**
  String get secondsBetweenSets;

  /// No description provided for @restTimerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Rest timer settings coming soon'**
  String get restTimerComingSoon;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @themeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Theme settings coming soon'**
  String get themeComingSoon;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export database'**
  String get exportDatabase;

  /// No description provided for @shareDbFile.
  ///
  /// In en, this message translates to:
  /// **'Share the SQLite database file'**
  String get shareDbFile;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @removeEverything.
  ///
  /// In en, this message translates to:
  /// **'Remove everything and restart fresh'**
  String get removeEverything;

  /// No description provided for @noDbFound.
  ///
  /// In en, this message translates to:
  /// **'No database file found'**
  String get noDbFound;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove all your data including meals, exercises, workouts, goals, and profile. A fresh database will be created on next launch.'**
  String get deleteAllDataContent;

  /// No description provided for @dbDeleted.
  ///
  /// In en, this message translates to:
  /// **'Database deleted. Restart the app to recreate it.'**
  String get dbDeleted;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @couldNotLoadWeightHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load weight history.'**
  String get couldNotLoadWeightHistory;

  /// No description provided for @trainingHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Training heatmap'**
  String get trainingHeatmap;

  /// No description provided for @heatmapLegendLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get heatmapLegendLow;

  /// No description provided for @heatmapLegendMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get heatmapLegendMid;

  /// No description provided for @heatmapLegendHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get heatmapLegendHigh;

  /// No description provided for @benchPress.
  ///
  /// In en, this message translates to:
  /// **'Bench Press'**
  String get benchPress;

  /// No description provided for @deadlift.
  ///
  /// In en, this message translates to:
  /// **'Deadlift'**
  String get deadlift;

  /// No description provided for @squat.
  ///
  /// In en, this message translates to:
  /// **'Squat'**
  String get squat;

  /// No description provided for @enterDetailsForMacros.
  ///
  /// In en, this message translates to:
  /// **'Enter your details for macro calculations'**
  String get enterDetailsForMacros;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @navDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get navDiet;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get navExercise;
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
