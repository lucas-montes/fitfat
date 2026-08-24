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

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// No description provided for @tabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tabNotes;

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

  /// No description provided for @dashboardWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FitFat'**
  String get dashboardWelcomeTitle;

  /// No description provided for @dashboardWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Start by adding an ingredient, a meal, or a workout.'**
  String get dashboardWelcomeBody;

  /// No description provided for @dashboardWelcomeActionIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add an ingredient'**
  String get dashboardWelcomeActionIngredients;

  /// No description provided for @dashboardWelcomeActionMeals.
  ///
  /// In en, this message translates to:
  /// **'Log a meal'**
  String get dashboardWelcomeActionMeals;

  /// No description provided for @dashboardWelcomeActionWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Add a workout'**
  String get dashboardWelcomeActionWorkouts;

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

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get dashboardMacroProtein;

  /// No description provided for @dashboardMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get dashboardMacroCarbs;

  /// No description provided for @dashboardMacroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get dashboardMacroFat;

  /// No description provided for @dashboardContinueWorkout.
  ///
  /// In en, this message translates to:
  /// **'Continue workout'**
  String get dashboardContinueWorkout;

  /// No description provided for @dashboardOpenWorkout.
  ///
  /// In en, this message translates to:
  /// **'Open workout'**
  String get dashboardOpenWorkout;

  /// No description provided for @dashboardCalorieTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie target'**
  String get dashboardCalorieTarget;

  /// No description provided for @dashboardRemaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get dashboardRemaining;

  /// No description provided for @dashboardConsumedOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{consumed} / {target} kcal'**
  String dashboardConsumedOfTarget(String consumed, String target);

  /// No description provided for @dashboardOverTarget.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over target'**
  String dashboardOverTarget(String kcal);

  /// No description provided for @dashboardMacroTargets.
  ///
  /// In en, this message translates to:
  /// **'Macro targets'**
  String get dashboardMacroTargets;

  /// No description provided for @dashboardMacroProgress.
  ///
  /// In en, this message translates to:
  /// **'{consumed} / {target} g'**
  String dashboardMacroProgress(String consumed, String target);

  /// No description provided for @dashboardWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight trend'**
  String get dashboardWeightTrend;

  /// No description provided for @dashboardWeeklyWorkout.
  ///
  /// In en, this message translates to:
  /// **'Weekly workout'**
  String get dashboardWeeklyWorkout;

  /// No description provided for @dashboardVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get dashboardVolume;

  /// No description provided for @dashboardVolumeKg.
  ///
  /// In en, this message translates to:
  /// **'{volume} {unit}'**
  String dashboardVolumeKg(String volume, String unit);

  /// No description provided for @dashboardMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get dashboardMinutes;

  /// No description provided for @dashboardUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming tasks'**
  String get dashboardUpcomingTasks;

  /// No description provided for @dashboardNoUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming timed tasks.'**
  String get dashboardNoUpcomingTasks;

  /// No description provided for @dashboardSeeAllTasks.
  ///
  /// In en, this message translates to:
  /// **'See all {count} tasks'**
  String dashboardSeeAllTasks(String count);

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

  /// No description provided for @exerciseListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get exerciseListSearchHint;

  /// No description provided for @exerciseFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get exerciseFilterType;

  /// No description provided for @exerciseFilterBodyPart.
  ///
  /// In en, this message translates to:
  /// **'Body part'**
  String get exerciseFilterBodyPart;

  /// No description provided for @exerciseFilterEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get exerciseFilterEquipment;

  /// No description provided for @exerciseFilterMuscle.
  ///
  /// In en, this message translates to:
  /// **'Muscle'**
  String get exerciseFilterMuscle;

  /// No description provided for @exerciseFilterResults.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exerciseFilterResults(int count);

  /// No description provided for @exerciseFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get exerciseFilterClear;

  /// No description provided for @exerciseFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get exerciseFilterApply;

  /// No description provided for @exerciseFilterNoResults.
  ///
  /// In en, this message translates to:
  /// **'No exercises match'**
  String get exerciseFilterNoResults;

  /// No description provided for @exerciseFilterSearchOptions.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get exerciseFilterSearchOptions;

  /// No description provided for @exerciseDetailTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get exerciseDetailTabHistory;

  /// No description provided for @exerciseDetailTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get exerciseDetailTabDetails;

  /// No description provided for @emptyExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get emptyExercisesTitle;

  /// No description provided for @emptyExercisesBody.
  ///
  /// In en, this message translates to:
  /// **'Create exercises to plan your workouts.'**
  String get emptyExercisesBody;

  /// No description provided for @emptyExercisesCta.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get emptyExercisesCta;

  /// No description provided for @activeWorkoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get activeWorkoutAddExercise;

  /// No description provided for @activeWorkoutAddExerciseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search and add exercises to this workout'**
  String get activeWorkoutAddExerciseTooltip;

  /// No description provided for @activeWorkoutPlannedSetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Planned sets for {exercise}'**
  String activeWorkoutPlannedSetsTitle(String exercise);

  /// No description provided for @activeWorkoutPlannedRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get activeWorkoutPlannedRepsLabel;

  /// No description provided for @activeWorkoutPlannedWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get activeWorkoutPlannedWeightLabel;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @activeWorkoutPrevExercise.
  ///
  /// In en, this message translates to:
  /// **'Previous exercise'**
  String get activeWorkoutPrevExercise;

  /// No description provided for @activeWorkoutNextExercise.
  ///
  /// In en, this message translates to:
  /// **'Next exercise'**
  String get activeWorkoutNextExercise;

  /// No description provided for @activeWorkoutInThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'In This Workout'**
  String get activeWorkoutInThisWorkout;

  /// No description provided for @activeWorkoutAllExercises.
  ///
  /// In en, this message translates to:
  /// **'All Exercises'**
  String get activeWorkoutAllExercises;

  /// No description provided for @activeWorkoutSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type to search exercises'**
  String get activeWorkoutSearchPrompt;

  /// No description provided for @activeWorkoutExerciseNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get activeWorkoutExerciseNotes;

  /// No description provided for @activeWorkoutExerciseInfo.
  ///
  /// In en, this message translates to:
  /// **'Exercise info'**
  String get activeWorkoutExerciseInfo;

  /// No description provided for @activeWorkoutExerciseNotesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise notes'**
  String get activeWorkoutExerciseNotesDialogTitle;

  /// No description provided for @activeWorkoutExerciseNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Note what to repeat or change next time (sets, weight, difficulty)…'**
  String get activeWorkoutExerciseNotesHint;

  /// No description provided for @exerciseUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise in use'**
  String get exerciseUsedTitle;

  /// No description provided for @exerciseUsedBody.
  ///
  /// In en, this message translates to:
  /// **'Used in {count} workout. Delete the workout first to remove this exercise.'**
  String exerciseUsedBody(int count);

  /// No description provided for @exerciseUsedBody_plural.
  ///
  /// In en, this message translates to:
  /// **'Used in {count} workouts. Delete the workouts first to remove this exercise.'**
  String exerciseUsedBody_plural(Object count);

  /// No description provided for @exerciseDetailAppBar.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseDetailAppBar;

  /// No description provided for @exerciseDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found.'**
  String get exerciseDetailNotFound;

  /// No description provided for @exerciseDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get exerciseDetailType;

  /// No description provided for @exerciseDetailBodyPart.
  ///
  /// In en, this message translates to:
  /// **'Body part'**
  String get exerciseDetailBodyPart;

  /// No description provided for @exerciseDetailEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get exerciseDetailEquipment;

  /// No description provided for @exerciseDetailPrimaryMuscle.
  ///
  /// In en, this message translates to:
  /// **'Primary muscles'**
  String get exerciseDetailPrimaryMuscle;

  /// No description provided for @exerciseDetailSecondaryMuscle.
  ///
  /// In en, this message translates to:
  /// **'Secondary muscles'**
  String get exerciseDetailSecondaryMuscle;

  /// No description provided for @exerciseDetailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get exerciseDetailInstructions;

  /// No description provided for @exerciseDetailTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get exerciseDetailTips;

  /// No description provided for @exerciseDetailFaqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get exerciseDetailFaqs;

  /// No description provided for @exerciseDetailKeywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get exerciseDetailKeywords;

  /// No description provided for @exerciseDetailHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get exerciseDetailHistory;

  /// No description provided for @exerciseDetailHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet. Add this exercise to a workout to see your stats.'**
  String get exerciseDetailHistoryEmpty;

  /// No description provided for @exerciseDetailBestWeight.
  ///
  /// In en, this message translates to:
  /// **'Best weight'**
  String get exerciseDetailBestWeight;

  /// No description provided for @exerciseDetailBestVolume.
  ///
  /// In en, this message translates to:
  /// **'Best volume'**
  String get exerciseDetailBestVolume;

  /// No description provided for @exerciseDetailBestDuration.
  ///
  /// In en, this message translates to:
  /// **'Best duration'**
  String get exerciseDetailBestDuration;

  /// No description provided for @exerciseDetailTotalWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get exerciseDetailTotalWorkouts;

  /// No description provided for @exerciseDetailTotalSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get exerciseDetailTotalSets;

  /// No description provided for @exerciseDetailVolumeOverTime.
  ///
  /// In en, this message translates to:
  /// **'Volume over time'**
  String get exerciseDetailVolumeOverTime;

  /// No description provided for @exerciseDetailDurationOverTime.
  ///
  /// In en, this message translates to:
  /// **'Duration over time'**
  String get exerciseDetailDurationOverTime;

  /// No description provided for @exerciseDetailPlannedVsActual.
  ///
  /// In en, this message translates to:
  /// **'Planned vs actual'**
  String get exerciseDetailPlannedVsActual;

  /// No description provided for @exerciseDetailVolumeAdherence.
  ///
  /// In en, this message translates to:
  /// **'Volume adherence'**
  String get exerciseDetailVolumeAdherence;

  /// No description provided for @exerciseDetailSetsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sets completed'**
  String get exerciseDetailSetsCompleted;

  /// No description provided for @exerciseDetailAdherenceValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String exerciseDetailAdherenceValue(String percent);

  /// No description provided for @exerciseDetailSetNumber.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String exerciseDetailSetNumber(int number);

  /// No description provided for @exerciseDetailSetCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get exerciseDetailSetCompleted;

  /// No description provided for @exerciseDetailSetNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get exerciseDetailSetNotCompleted;

  /// No description provided for @exerciseDetailSetEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get exerciseDetailSetEmpty;

  /// No description provided for @exerciseDetailRepsDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} reps'**
  String exerciseDetailRepsDelta(String delta);

  /// No description provided for @exerciseDetailWeightDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} {unit}'**
  String exerciseDetailWeightDelta(String delta, String unit);

  /// No description provided for @exerciseDetailSetRest.
  ///
  /// In en, this message translates to:
  /// **'rest {rest}'**
  String exerciseDetailSetRest(String rest);

  /// No description provided for @exerciseDetailSetRestTook.
  ///
  /// In en, this message translates to:
  /// **'(took {rest})'**
  String exerciseDetailSetRestTook(String rest);

  /// No description provided for @exerciseDetailTrendSame.
  ///
  /// In en, this message translates to:
  /// **'same as previous workout'**
  String get exerciseDetailTrendSame;

  /// No description provided for @exerciseDetailTrendDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} {unit} vs previous workout'**
  String exerciseDetailTrendDelta(String delta, String unit);

  /// No description provided for @exerciseDetailPrBadge.
  ///
  /// In en, this message translates to:
  /// **'New PR'**
  String get exerciseDetailPrBadge;

  /// No description provided for @exerciseDetailSetHeader.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get exerciseDetailSetHeader;

  /// No description provided for @exerciseDetailSetHeaderPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get exerciseDetailSetHeaderPlanned;

  /// No description provided for @exerciseDetailSetHeaderActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get exerciseDetailSetHeaderActual;

  /// No description provided for @exerciseDetailSetHeaderDelta.
  ///
  /// In en, this message translates to:
  /// **'Δ'**
  String get exerciseDetailSetHeaderDelta;

  /// No description provided for @exerciseDetailSetHeaderRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get exerciseDetailSetHeaderRest;

  /// No description provided for @exerciseDetailWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'Best weight over time'**
  String get exerciseDetailWeightTrend;

  /// No description provided for @exerciseDetailRepsTrend.
  ///
  /// In en, this message translates to:
  /// **'Reps over time'**
  String get exerciseDetailRepsTrend;

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

  /// No description provided for @emptyWorkoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get emptyWorkoutsTitle;

  /// No description provided for @emptyWorkoutsBody.
  ///
  /// In en, this message translates to:
  /// **'Plan your first workout and start training.'**
  String get emptyWorkoutsBody;

  /// No description provided for @emptyWorkoutsCta.
  ///
  /// In en, this message translates to:
  /// **'Add workout'**
  String get emptyWorkoutsCta;

  /// No description provided for @workoutDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout \"{name}\" deleted'**
  String workoutDeleted(String name);

  /// No description provided for @workoutFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New Workout'**
  String get workoutFormTitle;

  /// No description provided for @workoutFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Workout'**
  String get workoutFormEditTitle;

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

  /// No description provided for @workoutFormAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get workoutFormAddExercise;

  /// No description provided for @workoutFormRemoveSet.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get workoutFormRemoveSet;

  /// No description provided for @workoutFormReorderExercises.
  ///
  /// In en, this message translates to:
  /// **'Reorder exercises'**
  String get workoutFormReorderExercises;

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

  /// No description provided for @workoutFormSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get workoutFormSearchHint;

  /// No description provided for @workoutFormRestLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest (min)'**
  String get workoutFormRestLabel;

  /// No description provided for @workoutFormSetIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Complete every added set with its values and rest time (or remove the empty set)'**
  String get workoutFormSetIncomplete;

  /// No description provided for @workoutFormRemoveExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get workoutFormRemoveExercise;

  /// No description provided for @workoutFormCreateExercise.
  ///
  /// In en, this message translates to:
  /// **'Create new exercise “{query}”'**
  String workoutFormCreateExercise(Object query);

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

  /// No description provided for @emptyWorkoutDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises in this workout'**
  String get emptyWorkoutDetailTitle;

  /// No description provided for @emptyWorkoutDetailBody.
  ///
  /// In en, this message translates to:
  /// **'Add exercises when creating a workout.'**
  String get emptyWorkoutDetailBody;

  /// No description provided for @workoutDetailSetHeaderActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get workoutDetailSetHeaderActual;

  /// No description provided for @workoutDetailSetChipRest.
  ///
  /// In en, this message translates to:
  /// **'{planned} · {rest}'**
  String workoutDetailSetChipRest(String planned, String rest);

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

  /// No description provided for @emptyIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'No ingredients yet'**
  String get emptyIngredientsTitle;

  /// No description provided for @emptyIngredientsBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first ingredient to start building meals.'**
  String get emptyIngredientsBody;

  /// No description provided for @emptyIngredientsCta.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get emptyIngredientsCta;

  /// No description provided for @ingredientArchived.
  ///
  /// In en, this message translates to:
  /// **'Ingredient \"{name}\" archived'**
  String ingredientArchived(String name);

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

  /// No description provided for @ingredientFormSodiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Sodium (per 100g)'**
  String get ingredientFormSodiumLabel;

  /// No description provided for @ingredientFormSodiumSuffix.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get ingredientFormSodiumSuffix;

  /// No description provided for @ingredientFormFiberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fiber (per 100g)'**
  String get ingredientFormFiberLabel;

  /// No description provided for @ingredientFormFiberSuffix.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get ingredientFormFiberSuffix;

  /// No description provided for @ingredientFormSugarLabel.
  ///
  /// In en, this message translates to:
  /// **'Sugar (per 100g)'**
  String get ingredientFormSugarLabel;

  /// No description provided for @ingredientFormSugarSuffix.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get ingredientFormSugarSuffix;

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

  /// No description provided for @emptyMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'No meals yet'**
  String get emptyMealsTitle;

  /// No description provided for @emptyMealsBody.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal to track calories and macros.'**
  String get emptyMealsBody;

  /// No description provided for @emptyMealsCta.
  ///
  /// In en, this message translates to:
  /// **'Log a meal'**
  String get emptyMealsCta;

  /// No description provided for @mealDeleted.
  ///
  /// In en, this message translates to:
  /// **'Meal \"{name}\" deleted'**
  String mealDeleted(String name);

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

  /// No description provided for @plannerAppBar.
  ///
  /// In en, this message translates to:
  /// **'Daily Plan'**
  String get plannerAppBar;

  /// No description provided for @plannerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get plannerToday;

  /// No description provided for @plannerPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get plannerPreviousDay;

  /// No description provided for @plannerNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get plannerNextDay;

  /// No description provided for @plannerAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get plannerAnytime;

  /// No description provided for @plannerTimelineScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get plannerTimelineScheduled;

  /// No description provided for @emptyPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this day'**
  String get emptyPlannerTitle;

  /// No description provided for @emptyPlannerBody.
  ///
  /// In en, this message translates to:
  /// **'Add a task to plan your routine.'**
  String get emptyPlannerBody;

  /// No description provided for @emptyPlannerCta.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get emptyPlannerCta;

  /// No description provided for @plannerTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get plannerTaskLabel;

  /// No description provided for @plannerTaskHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Morning run'**
  String get plannerTaskHint;

  /// No description provided for @plannerTaskRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get plannerTaskRequired;

  /// No description provided for @plannerTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get plannerTagsLabel;

  /// No description provided for @plannerTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag, then press + (e.g. Work, Errand)'**
  String get plannerTagsHint;

  /// No description provided for @plannerTagsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get plannerTagsAdd;

  /// No description provided for @plannerNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get plannerNotesLabel;

  /// No description provided for @plannerWorkoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout (optional)'**
  String get plannerWorkoutLabel;

  /// No description provided for @plannerWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Link a workout'**
  String get plannerWorkoutHint;

  /// No description provided for @plannerWorkoutNone.
  ///
  /// In en, this message translates to:
  /// **'No workout'**
  String get plannerWorkoutNone;

  /// No description provided for @plannerLinkedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Open linked workout'**
  String get plannerLinkedWorkout;

  /// No description provided for @plannerDueDateNone.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get plannerDueDateNone;

  /// No description provided for @plannerDueDateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get plannerDueDateClear;

  /// No description provided for @plannerDueTimeNone.
  ///
  /// In en, this message translates to:
  /// **'No due time'**
  String get plannerDueTimeNone;

  /// No description provided for @plannerDueTimeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear due time'**
  String get plannerDueTimeClear;

  /// No description provided for @plannerStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get plannerStartTimeLabel;

  /// No description provided for @plannerEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get plannerEndTimeLabel;

  /// No description provided for @plannerStartTimeNone.
  ///
  /// In en, this message translates to:
  /// **'No start time'**
  String get plannerStartTimeNone;

  /// No description provided for @plannerEndTimeNone.
  ///
  /// In en, this message translates to:
  /// **'No end time'**
  String get plannerEndTimeNone;

  /// No description provided for @plannerStartTimeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear start time'**
  String get plannerStartTimeClear;

  /// No description provided for @plannerEndTimeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear end time'**
  String get plannerEndTimeClear;

  /// No description provided for @plannerRepeatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the repeat settings'**
  String get plannerRepeatInvalid;

  /// No description provided for @plannerAddTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get plannerAddTask;

  /// No description provided for @plannerEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get plannerEditTask;

  /// No description provided for @plannerEditScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit scope'**
  String get plannerEditScopeTitle;

  /// No description provided for @plannerDeleteScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete scope'**
  String get plannerDeleteScopeTitle;

  /// No description provided for @plannerScopeBody.
  ///
  /// In en, this message translates to:
  /// **'This task repeats. How would you like to proceed?'**
  String get plannerScopeBody;

  /// No description provided for @plannerScopeThis.
  ///
  /// In en, this message translates to:
  /// **'This one only'**
  String get plannerScopeThis;

  /// No description provided for @plannerScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and all following ones'**
  String get plannerScopeFollowing;

  /// No description provided for @plannerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task \"{title}\" deleted'**
  String plannerDeleted(String title);

  /// No description provided for @plannerCopyPrevious.
  ///
  /// In en, this message translates to:
  /// **'Copy from yesterday'**
  String get plannerCopyPrevious;

  /// No description provided for @plannerMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get plannerMoreActions;

  /// No description provided for @plannerTaskDetailAppBar.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get plannerTaskDetailAppBar;

  /// plannerDetailUpdatedAt
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String plannerDetailUpdatedAt(String date);

  /// plannerDetailDueDate
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String plannerDetailDueDate(String date);

  /// plannerDetailTimeRange
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String plannerDetailTimeRange(String start, String end);

  /// No description provided for @plannerDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get plannerDetailNotes;

  /// No description provided for @plannerDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get plannerDetailTags;

  /// No description provided for @plannerDetailRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get plannerDetailRepeats;

  /// No description provided for @plannerDetailLinkedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Linked workout'**
  String get plannerDetailLinkedWorkout;

  /// No description provided for @plannerDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get plannerDetailEdit;

  /// No description provided for @plannerDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get plannerDetailDelete;

  /// No description provided for @plannerDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get plannerDetailDeleteTitle;

  /// plannerDetailDeleteBody
  ///
  /// In en, this message translates to:
  /// **'This deletes the task \"{title}\".'**
  String plannerDetailDeleteBody(String title);

  /// No description provided for @plannerRepeatSummaryDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get plannerRepeatSummaryDaily;

  /// plannerRepeatSummaryWeekly
  ///
  /// In en, this message translates to:
  /// **'Every week on {days}'**
  String plannerRepeatSummaryWeekly(String days);

  /// plannerRepeatSummaryInterval
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String plannerRepeatSummaryInterval(int count);

  /// plannerRepeatSummaryMonthly
  ///
  /// In en, this message translates to:
  /// **'Monthly on day {day}'**
  String plannerRepeatSummaryMonthly(int day);

  /// plannerRepeatSummaryEndsDate
  ///
  /// In en, this message translates to:
  /// **' · until {date}'**
  String plannerRepeatSummaryEndsDate(String date);

  /// plannerRepeatSummaryEndsCount
  ///
  /// In en, this message translates to:
  /// **' · {count} occurrences'**
  String plannerRepeatSummaryEndsCount(int count);

  /// No description provided for @plannerCopyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy pending tasks?'**
  String get plannerCopyConfirmTitle;

  /// No description provided for @plannerCopyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count} pending task from yesterday will be copied to today.'**
  String plannerCopyConfirmBody(int count);

  /// No description provided for @plannerCopyConfirmBody_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} pending tasks from yesterday will be copied to today.'**
  String plannerCopyConfirmBody_plural(Object count);

  /// No description provided for @plannerRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get plannerRepeatLabel;

  /// No description provided for @plannerRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get plannerRepeatNone;

  /// No description provided for @plannerRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get plannerRepeatDaily;

  /// No description provided for @plannerRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get plannerRepeatWeekly;

  /// No description provided for @plannerRepeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get plannerRepeatInterval;

  /// No description provided for @plannerRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get plannerRepeatMonthly;

  /// No description provided for @plannerRepeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get plannerRepeatWeekdays;

  /// No description provided for @plannerRepeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get plannerRepeatEvery;

  /// No description provided for @plannerRepeatDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get plannerRepeatDays;

  /// No description provided for @plannerRepeatMonthDay.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get plannerRepeatMonthDay;

  /// No description provided for @plannerRepeatEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get plannerRepeatEnds;

  /// No description provided for @plannerRepeatEndsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get plannerRepeatEndsNever;

  /// No description provided for @plannerRepeatEndsOnDate.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get plannerRepeatEndsOnDate;

  /// No description provided for @plannerRepeatEndsAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get plannerRepeatEndsAfter;

  /// No description provided for @plannerRepeatOccurrences.
  ///
  /// In en, this message translates to:
  /// **'occurrences'**
  String get plannerRepeatOccurrences;

  /// No description provided for @notesAppBar.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesAppBar;

  /// No description provided for @notesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmptyTitle;

  /// No description provided for @notesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Capture anything on your mind — routines, recipes, lessons from a workout. Notes are private to this device.'**
  String get notesEmptyBody;

  /// No description provided for @notesFab.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get notesFab;

  /// No description provided for @notesEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get notesEditorNewTitle;

  /// No description provided for @notesEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get notesEditorEditTitle;

  /// No description provided for @notesTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notesTitleLabel;

  /// No description provided for @notesBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get notesBodyLabel;

  /// No description provided for @notesTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get notesTitleRequired;

  /// No description provided for @notesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get notesSave;

  /// No description provided for @notesEditing.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get notesEditing;

  /// No description provided for @notesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get notesDelete;

  /// No description provided for @notesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get notesDeleteConfirmTitle;

  /// No description provided for @notesDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be permanently deleted. This can’t be undone.'**
  String notesDeleteConfirmBody(Object title);

  /// No description provided for @settingsAppBar.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAppBar;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age (years)'**
  String get settingsAgeLabel;

  /// No description provided for @settingsAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an age between 0 and 120'**
  String get settingsAgeInvalid;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLangEn;

  /// No description provided for @settingsLangFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get settingsLangFr;

  /// No description provided for @settingsLangEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get settingsLangEs;

  /// No description provided for @settingsLangSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLangSystem;

  /// No description provided for @settingsProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Age, gender, activity and goals'**
  String get settingsProfileSubtitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Task reminders and rest alarm'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsAppearanceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Language'**
  String get settingsAppearanceLanguage;

  /// No description provided for @settingsAppearanceLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme and app language'**
  String get settingsAppearanceLanguageSubtitle;

  /// No description provided for @settingsBodyWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Body weight goal'**
  String get settingsBodyWeightGoal;

  /// No description provided for @settingsGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get settingsGoalLose;

  /// No description provided for @settingsGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get settingsGoalMaintain;

  /// No description provided for @settingsGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get settingsGoalGain;

  /// No description provided for @settingsGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get settingsGender;

  /// No description provided for @settingsGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settingsGenderMale;

  /// No description provided for @settingsGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settingsGenderFemale;

  /// No description provided for @settingsActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get settingsActivityLevel;

  /// No description provided for @settingsActivitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get settingsActivitySedentary;

  /// No description provided for @settingsActivityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsActivityLight;

  /// No description provided for @settingsActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get settingsActivityModerate;

  /// No description provided for @settingsActivityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsActivityActive;

  /// No description provided for @settingsActivityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get settingsActivityVeryActive;

  /// No description provided for @settingsComputeActivity.
  ///
  /// In en, this message translates to:
  /// **'Compute activity from workouts and steps'**
  String get settingsComputeActivity;

  /// No description provided for @settingsTrackBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Track body fat'**
  String get settingsTrackBodyFat;

  /// No description provided for @settingsBodyFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Body fat (%)'**
  String get settingsBodyFatLabel;

  /// No description provided for @settingsBodyFatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a body fat percentage between 0 and 70'**
  String get settingsBodyFatInvalid;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPlannerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get settingsPlannerNotifications;

  /// No description provided for @settingsPlannerNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify me about planner tasks with a due time.'**
  String get settingsPlannerNotificationsSubtitle;

  /// No description provided for @settingsRestAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Rest alarm sound'**
  String get settingsRestAlarmSound;

  /// No description provided for @settingsRestAlarmVibration.
  ///
  /// In en, this message translates to:
  /// **'Rest alarm vibration'**
  String get settingsRestAlarmVibration;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsResetData.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get settingsResetData;

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// No description provided for @settingsAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Planner horizon, calorie adjustment, timers'**
  String get settingsAdvancedSubtitle;

  /// No description provided for @settingsPlannerHorizonLabel.
  ///
  /// In en, this message translates to:
  /// **'Planner look-ahead (days)'**
  String get settingsPlannerHorizonLabel;

  /// No description provided for @settingsCalorieAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Calorie goal adjustment (kcal)'**
  String get settingsCalorieAdjustmentLabel;

  /// No description provided for @settingsExperimentBaselineLabel.
  ///
  /// In en, this message translates to:
  /// **'Experiment baseline (days)'**
  String get settingsExperimentBaselineLabel;

  /// No description provided for @settingsDefaultRestLabel.
  ///
  /// In en, this message translates to:
  /// **'Default rest between sets (min)'**
  String get settingsDefaultRestLabel;

  /// No description provided for @settingsReminderLeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre-reminder lead (min)'**
  String get settingsReminderLeadLabel;

  /// No description provided for @settingsApiTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync request timeout (s)'**
  String get settingsApiTimeoutLabel;

  /// No description provided for @settingsPlannerHorizonHelp.
  ///
  /// In en, this message translates to:
  /// **'How many days ahead recurring tasks are pre-created in the planner.'**
  String get settingsPlannerHorizonHelp;

  /// No description provided for @settingsCalorieAdjustmentHelp.
  ///
  /// In en, this message translates to:
  /// **'kcal added to (gain) or subtracted from (lose) your daily calorie target.'**
  String get settingsCalorieAdjustmentHelp;

  /// No description provided for @settingsExperimentBaselineHelp.
  ///
  /// In en, this message translates to:
  /// **'Days of history before an experiment starts, used as its comparison baseline.'**
  String get settingsExperimentBaselineHelp;

  /// No description provided for @settingsDefaultRestHelp.
  ///
  /// In en, this message translates to:
  /// **'Prefills the rest field when adding a new set to a workout. Leave blank for none.'**
  String get settingsDefaultRestHelp;

  /// No description provided for @settingsReminderLeadHelp.
  ///
  /// In en, this message translates to:
  /// **'Minutes before a task\'s start time when the advance notification fires.'**
  String get settingsReminderLeadHelp;

  /// No description provided for @settingsApiTimeoutHelp.
  ///
  /// In en, this message translates to:
  /// **'How long sync requests wait for the server before giving up.'**
  String get settingsApiTimeoutHelp;

  /// No description provided for @settingsValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid non-negative number.'**
  String get settingsValueInvalid;

  /// No description provided for @settingsResetDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all workouts, meals, metrics, planner tasks and notes, and restore default settings.'**
  String get settingsResetDataSubtitle;

  /// No description provided for @settingsResetDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all data?'**
  String get settingsResetDataConfirmTitle;

  /// No description provided for @settingsResetDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all of your data and resets your settings. This cannot be undone.'**
  String get settingsResetDataConfirmBody;

  /// No description provided for @settingsResetDataConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get settingsResetDataConfirmAction;

  /// No description provided for @taskReminderDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due in 30 minutes'**
  String get taskReminderDueSoon;

  /// No description provided for @taskReminderDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get taskReminderDueNow;

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

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

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

  /// No description provided for @ingredientNutrientSodium.
  ///
  /// In en, this message translates to:
  /// **'Na {value}mg'**
  String ingredientNutrientSodium(String value);

  /// No description provided for @ingredientNutrientFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber {value}g'**
  String ingredientNutrientFiber(String value);

  /// No description provided for @ingredientNutrientSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar {value}g'**
  String ingredientNutrientSugar(String value);

  /// No description provided for @ingredientFormBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get ingredientFormBrandLabel;

  /// No description provided for @ingredientFormBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get ingredientFormBarcodeLabel;

  /// No description provided for @ingredientFormScanTile.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get ingredientFormScanTile;

  /// No description provided for @ingredientFormScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get ingredientFormScanning;

  /// No description provided for @ingredientFormPicturesSection.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get ingredientFormPicturesSection;

  /// No description provided for @ingredientFormAddPicture.
  ///
  /// In en, this message translates to:
  /// **'Add picture'**
  String get ingredientFormAddPicture;

  /// No description provided for @ingredientDetailPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get ingredientDetailPricesTitle;

  /// No description provided for @ingredientDetailNoPrices.
  ///
  /// In en, this message translates to:
  /// **'No prices recorded yet.'**
  String get ingredientDetailNoPrices;

  /// No description provided for @ingredientDetailCostPerKg.
  ///
  /// In en, this message translates to:
  /// **'{value} /kg'**
  String ingredientDetailCostPerKg(String value);

  /// No description provided for @ingredientPriceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add price'**
  String get ingredientPriceAdd;

  /// No description provided for @ingredientPriceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit price'**
  String get ingredientPriceEdit;

  /// No description provided for @ingredientPriceStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get ingredientPriceStoreLabel;

  /// No description provided for @ingredientPriceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get ingredientPriceAmountLabel;

  /// No description provided for @ingredientPriceGramsLabel.
  ///
  /// In en, this message translates to:
  /// **'Package size'**
  String get ingredientPriceGramsLabel;

  /// No description provided for @ingredientPriceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get ingredientPriceHistoryTitle;

  /// No description provided for @ingredientDetailManageStores.
  ///
  /// In en, this message translates to:
  /// **'Manage stores'**
  String get ingredientDetailManageStores;

  /// No description provided for @storeManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get storeManagerTitle;

  /// No description provided for @storeManagerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stores yet. Add one to start tracking prices.'**
  String get storeManagerEmpty;

  /// No description provided for @storeManagerAddTile.
  ///
  /// In en, this message translates to:
  /// **'Add store'**
  String get storeManagerAddTile;

  /// No description provided for @storeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get storeNameLabel;

  /// No description provided for @storeNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get storeNameRequired;

  /// No description provided for @settingsFxAutoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh rates'**
  String get settingsFxAutoRefresh;

  /// No description provided for @settingsFxAutoRefreshSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetches exchange rates in the background'**
  String get settingsFxAutoRefreshSubtitle;

  /// No description provided for @settingsFxRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Refresh interval'**
  String get settingsFxRefreshInterval;

  /// No description provided for @settingsExperimentReminders.
  ///
  /// In en, this message translates to:
  /// **'Experiment reminders'**
  String get settingsExperimentReminders;

  /// No description provided for @settingsExperimentRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in reminders while an experiment is running'**
  String get settingsExperimentRemindersSubtitle;

  /// No description provided for @settingsSyncServer.
  ///
  /// In en, this message translates to:
  /// **'Sync server'**
  String get settingsSyncServer;

  /// No description provided for @settingsSyncServerHint.
  ///
  /// In en, this message translates to:
  /// **'Point this at your sync server to pull exercises, ingredients and currencies. Leave empty to disable sync.'**
  String get settingsSyncServerHint;

  /// No description provided for @settingsSyncBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsSyncBaseUrl;

  /// No description provided for @settingsSyncApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsSyncApiKey;

  /// No description provided for @syncExercisesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync exercises'**
  String get syncExercisesTooltip;

  /// No description provided for @syncIngredientsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync ingredients'**
  String get syncIngredientsTooltip;

  /// No description provided for @syncCurrenciesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync currencies'**
  String get syncCurrenciesTooltip;

  /// No description provided for @syncPushIngredientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Push to shared catalogue'**
  String get syncPushIngredientTooltip;

  /// No description provided for @syncServerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync server URL is not configured'**
  String get syncServerNotConfigured;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsWeightUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get settingsWeightUnitLabel;

  /// No description provided for @settingsLengthUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsLengthUnitLabel;

  /// No description provided for @settingsExportDb.
  ///
  /// In en, this message translates to:
  /// **'Export database'**
  String get settingsExportDb;

  /// No description provided for @settingsExportDbSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a copy of your data (SQLite)'**
  String get settingsExportDbSubtitle;

  /// No description provided for @settingsReplayPrefillLabel.
  ///
  /// In en, this message translates to:
  /// **'When replaying a workout, prefill sets from'**
  String get settingsReplayPrefillLabel;

  /// No description provided for @settingsReplayPrefillActuals.
  ///
  /// In en, this message translates to:
  /// **'Previous actuals'**
  String get settingsReplayPrefillActuals;

  /// No description provided for @settingsReplayPrefillPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned values'**
  String get settingsReplayPrefillPlanned;

  /// No description provided for @workoutSummaryDoAgain.
  ///
  /// In en, this message translates to:
  /// **'Do again'**
  String get workoutSummaryDoAgain;

  /// No description provided for @workoutActionReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get workoutActionReplay;

  /// No description provided for @workoutActionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get workoutActionDuplicate;

  /// No description provided for @workoutDetailPlannedSetReps.
  ///
  /// In en, this message translates to:
  /// **'{reps} × {weight} {unit}'**
  String workoutDetailPlannedSetReps(String reps, String weight, String unit);

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

  /// No description provided for @workoutDetailPlannedSetRest.
  ///
  /// In en, this message translates to:
  /// **'{planned} · rest {rest}'**
  String workoutDetailPlannedSetRest(Object planned, Object rest);

  /// No description provided for @workoutDetailActualSetReps.
  ///
  /// In en, this message translates to:
  /// **'{reps} × {weight} {unit}'**
  String workoutDetailActualSetReps(String reps, String weight, String unit);

  /// No description provided for @workoutDetailActualSetWeight.
  ///
  /// In en, this message translates to:
  /// **'{weight} {unit}'**
  String workoutDetailActualSetWeight(String weight, String unit);

  /// No description provided for @workoutDetailActualSetDuration.
  ///
  /// In en, this message translates to:
  /// **'{reps} min'**
  String workoutDetailActualSetDuration(String reps);

  /// No description provided for @workoutDetailActualSetDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} m'**
  String workoutDetailActualSetDistance(String distance);

  /// No description provided for @workoutDetailActualSetTime.
  ///
  /// In en, this message translates to:
  /// **'{value} · {time}'**
  String workoutDetailActualSetTime(String value, String time);

  /// No description provided for @workoutDetailActualSetEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get workoutDetailActualSetEmpty;

  /// No description provided for @bodyMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Metrics'**
  String get bodyMetricsTitle;

  /// No description provided for @bodyMetricsAddWeight.
  ///
  /// In en, this message translates to:
  /// **'Add weight'**
  String get bodyMetricsAddWeight;

  /// No description provided for @bodyMetricsAddHeight.
  ///
  /// In en, this message translates to:
  /// **'Add height'**
  String get bodyMetricsAddHeight;

  /// No description provided for @bodyMetricsWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get bodyMetricsWeightLabel;

  /// No description provided for @bodyMetricsHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get bodyMetricsHeightLabel;

  /// No description provided for @bodyMetricsDialogWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'New weight entry'**
  String get bodyMetricsDialogWeightTitle;

  /// No description provided for @bodyMetricsDialogHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'New height entry'**
  String get bodyMetricsDialogHeightTitle;

  /// No description provided for @bodyMetricsValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get bodyMetricsValueRequired;

  /// No description provided for @bodyMetricsValuePositive.
  ///
  /// In en, this message translates to:
  /// **'Value must be greater than 0'**
  String get bodyMetricsValuePositive;

  /// No description provided for @bodyMetricsEmptyWeight.
  ///
  /// In en, this message translates to:
  /// **'No weight entries yet.'**
  String get bodyMetricsEmptyWeight;

  /// No description provided for @bodyMetricsEmptyHeight.
  ///
  /// In en, this message translates to:
  /// **'No height entries yet.'**
  String get bodyMetricsEmptyHeight;

  /// No description provided for @bodyMetricsLatestWeight.
  ///
  /// In en, this message translates to:
  /// **'Latest: {value} {unit}'**
  String bodyMetricsLatestWeight(String value, String unit);

  /// No description provided for @bodyMetricsLatestHeight.
  ///
  /// In en, this message translates to:
  /// **'Latest: {value} {unit}'**
  String bodyMetricsLatestHeight(String value, String unit);

  /// No description provided for @bodyMetricsValueKg.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String bodyMetricsValueKg(String value, String unit);

  /// No description provided for @bodyMetricsValueCm.
  ///
  /// In en, this message translates to:
  /// **'{value} cm'**
  String bodyMetricsValueCm(String value);

  /// No description provided for @bodyMetricsGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal}'**
  String bodyMetricsGoal(String goal);

  /// No description provided for @restTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get restTimerTitle;

  /// No description provided for @restTimerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel rest'**
  String get restTimerCancel;

  /// No description provided for @restTimerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String restTimerMinutes(int minutes);

  /// No description provided for @activeWorkoutElapsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get activeWorkoutElapsedLabel;

  /// No description provided for @activeWorkoutRestLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get activeWorkoutRestLabel;

  /// No description provided for @activeWorkoutResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get activeWorkoutResume;

  /// No description provided for @restAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest is over'**
  String get restAlarmTitle;

  /// No description provided for @restAlarmBody.
  ///
  /// In en, this message translates to:
  /// **'Your planned rest is complete.'**
  String get restAlarmBody;

  /// No description provided for @restAlarmBodyWithDuration.
  ///
  /// In en, this message translates to:
  /// **'Your planned rest of {duration} is complete.'**
  String restAlarmBodyWithDuration(String duration);

  /// No description provided for @workoutSummaryAppBar.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get workoutSummaryAppBar;

  /// No description provided for @workoutSummaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get workoutSummaryDone;

  /// No description provided for @workoutSummaryDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutSummaryDurationLabel;

  /// No description provided for @workoutSummaryAvgRest.
  ///
  /// In en, this message translates to:
  /// **'Average rest'**
  String get workoutSummaryAvgRest;

  /// No description provided for @workoutSummaryVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get workoutSummaryVolume;

  /// No description provided for @workoutSummaryMaxWeight.
  ///
  /// In en, this message translates to:
  /// **'Max weight'**
  String get workoutSummaryMaxWeight;

  /// No description provided for @workoutSummaryTotalReps.
  ///
  /// In en, this message translates to:
  /// **'Total reps'**
  String get workoutSummaryTotalReps;

  /// No description provided for @workoutSummaryTotalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get workoutSummaryTotalDuration;

  /// No description provided for @workoutSummaryTotalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get workoutSummaryTotalDistance;

  /// No description provided for @workoutSummaryValueKg.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String workoutSummaryValueKg(String value, String unit);

  /// No description provided for @workoutSummaryDistanceValue.
  ///
  /// In en, this message translates to:
  /// **'{distance} m'**
  String workoutSummaryDistanceValue(String distance);

  /// settingsRateRow
  ///
  /// In en, this message translates to:
  /// **'{base} → {target}: {rate}'**
  String settingsRateRow(String target, num rate, String base);

  /// settingsRateInverse
  ///
  /// In en, this message translates to:
  /// **'1 {base} = {rate} {code}'**
  String settingsRateInverse(String base, String rate, String code);

  /// settingsRateUpdated
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String settingsRateUpdated(String date);

  /// settingsRateManual
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get settingsRateManual;

  /// transactionRateUsed
  ///
  /// In en, this message translates to:
  /// **'converted at {rate} {base} per {code}'**
  String transactionRateUsed(String rate, String base, String code);

  /// accountDeleteBlockedBody
  ///
  /// In en, this message translates to:
  /// **'This account is used by {count} transaction(s) and cannot be deleted.'**
  String accountDeleteBlockedBody(int count);

  /// accountDeleteBlockedTitle
  ///
  /// In en, this message translates to:
  /// **'Account in use'**
  String get accountDeleteBlockedTitle;

  /// accountDeleteConfirmBody
  ///
  /// In en, this message translates to:
  /// **'Deleting account \'{name}\' will also delete its transactions and receipts.'**
  String accountDeleteConfirmBody(String name);

  /// accountDeleteConfirmTitle
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountDeleteConfirmTitle;

  /// accountFormEditTitle
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountFormEditTitle;

  /// accountFormNameLabel
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountFormNameLabel;

  /// accountFormNameRequired
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get accountFormNameRequired;

  /// accountFormNewTitle
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountFormNewTitle;

  /// accountFormOpeningHelper
  ///
  /// In en, this message translates to:
  /// **'How much was already in this account when you started tracking it. Leave 0 if you are not sure.'**
  String get accountFormOpeningHelper;

  /// accountFormIntro
  ///
  /// In en, this message translates to:
  /// **'Track a wallet, bank account, or card.'**
  String get accountFormIntro;

  /// accountFormNoteLabel
  ///
  /// In en, this message translates to:
  /// **'Account Form Note Label'**
  String get accountFormNoteLabel;

  /// accountFormOpeningLabel
  ///
  /// In en, this message translates to:
  /// **'Starting balance'**
  String get accountFormOpeningLabel;

  /// accountFormTypeLabel
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountFormTypeLabel;

  /// accountOpeningLabel
  ///
  /// In en, this message translates to:
  /// **'Starting balance: {value}'**
  String accountOpeningLabel(String value);

  /// accountReceipts
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get accountReceipts;

  /// accountTransactions
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get accountTransactions;

  /// accountTypeBank
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// accountTypeCash
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// accountTypeCredit
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCredit;

  /// accountTypeInvestment
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get accountTypeInvestment;

  /// accountTypeOther
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountTypeOther;

  /// accountTypeSavings
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavings;

  /// budgetAccounts
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get budgetAccounts;

  /// budgetAdd
  ///
  /// In en, this message translates to:
  /// **'Budget Add'**
  String get budgetAdd;

  /// budgetEmptyBody
  ///
  /// In en, this message translates to:
  /// **'Budget Empty Body'**
  String get budgetEmptyBody;

  /// budgetEmptyTitle
  ///
  /// In en, this message translates to:
  /// **'Budget Empty Title'**
  String get budgetEmptyTitle;

  /// budgetFabAccount
  ///
  /// In en, this message translates to:
  /// **'Budget Fab Account'**
  String get budgetFabAccount;

  /// budgetFabExpense
  ///
  /// In en, this message translates to:
  /// **'Budget Fab Expense'**
  String get budgetFabExpense;

  /// budgetFabIncome
  ///
  /// In en, this message translates to:
  /// **'Budget Fab Income'**
  String get budgetFabIncome;

  /// budgetFabTransfer
  ///
  /// In en, this message translates to:
  /// **'Budget Fab Transfer'**
  String get budgetFabTransfer;

  /// budgetMonthExpense
  ///
  /// In en, this message translates to:
  /// **'Expenses this month'**
  String get budgetMonthExpense;

  /// budgetMonthIncome
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get budgetMonthIncome;

  /// budgetNoReceipts
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get budgetNoReceipts;

  /// budgetNoTransactions
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get budgetNoTransactions;

  /// budgetPendingReceipts
  ///
  /// In en, this message translates to:
  /// **'{count} receipt(s) awaiting review'**
  String budgetPendingReceipts(int count);

  /// budgetRecentTransactions
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get budgetRecentTransactions;

  /// budgetThisMonth
  ///
  /// In en, this message translates to:
  /// **'Budget This Month'**
  String get budgetThisMonth;

  /// budgetViewAll
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get budgetViewAll;

  /// commonDelete
  ///
  /// In en, this message translates to:
  /// **'Common Delete'**
  String get commonDelete;

  /// receiptAppBar
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptAppBar;

  /// receiptCreateDraft
  ///
  /// In en, this message translates to:
  /// **'Create draft'**
  String get receiptCreateDraft;

  /// receiptDeleteConfirmBody
  ///
  /// In en, this message translates to:
  /// **'Delete this receipt?'**
  String get receiptDeleteConfirmBody;

  /// receiptDeleteConfirmTitle
  ///
  /// In en, this message translates to:
  /// **'Delete receipt?'**
  String get receiptDeleteConfirmTitle;

  /// receiptEmptyBody
  ///
  /// In en, this message translates to:
  /// **'No receipts yet. Take a photo of a receipt to start tracking.'**
  String get receiptEmptyBody;

  /// receiptListAppBar
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptListAppBar;

  /// receiptNotFound
  ///
  /// In en, this message translates to:
  /// **'Receipt not found'**
  String get receiptNotFound;

  /// receiptNotParsed
  ///
  /// In en, this message translates to:
  /// **'Not parsed yet'**
  String get receiptNotParsed;

  /// receiptParsed
  ///
  /// In en, this message translates to:
  /// **'Parsed'**
  String get receiptParsed;

  /// receiptParsedData
  ///
  /// In en, this message translates to:
  /// **'Parsed data'**
  String get receiptParsedData;

  /// receiptPickGallery
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get receiptPickGallery;

  /// receiptReviewDraft
  ///
  /// In en, this message translates to:
  /// **'Review draft'**
  String get receiptReviewDraft;

  /// receiptStatusLabel
  ///
  /// In en, this message translates to:
  /// **'{status}'**
  String receiptStatusLabel(String status);

  /// receiptStatusShort
  ///
  /// In en, this message translates to:
  /// **'{status}'**
  String receiptStatusShort(String status);

  /// receiptTakePhoto
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get receiptTakePhoto;

  /// receiptUpload
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get receiptUpload;

  /// settingsCurrencyBudget
  ///
  /// In en, this message translates to:
  /// **'Budget currency'**
  String get settingsCurrencyBudget;

  /// settingsFxRates
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get settingsFxRates;

  /// settingsFxRatesEmpty
  ///
  /// In en, this message translates to:
  /// **'No exchange rates configured'**
  String get settingsFxRatesEmpty;

  /// settingsFxRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh rates'**
  String get settingsFxRefresh;

  /// settingsRateEdit
  ///
  /// In en, this message translates to:
  /// **'Edit rate'**
  String get settingsRateEdit;

  /// transactionAmountInvalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get transactionAmountInvalid;

  /// transactionCategoryLabel
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionCategoryLabel;

  /// transactionConvertedLabel
  ///
  /// In en, this message translates to:
  /// **'≈ {amount} in base currency'**
  String transactionConvertedLabel(String amount);

  /// transactionDraft
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get transactionDraft;

  /// transactionDraftHint
  ///
  /// In en, this message translates to:
  /// **'Draft from a scanned receipt — check the details before saving'**
  String get transactionDraftHint;

  /// transactionHasReceipt
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get transactionHasReceipt;

  /// transactionListAppBar
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionListAppBar;

  /// transactionTypeExpense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// transactionTypeIncome
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// transactionTypeTransfer
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// budgetAppBar
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetAppBar;

  /// budgetSubtitle
  ///
  /// In en, this message translates to:
  /// **'Accounts, transactions and receipts'**
  String get budgetSubtitle;

  /// budgetTotalBalance
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get budgetTotalBalance;

  /// budgetNetWorth
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get budgetNetWorth;

  /// budgetIncomeLabel
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get budgetIncomeLabel;

  /// budgetExpenseLabel
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get budgetExpenseLabel;

  /// budgetEmptyAccounts
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Add one to start tracking.'**
  String get budgetEmptyAccounts;

  /// budgetAddAccount
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get budgetAddAccount;

  /// budgetAddTransaction
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get budgetAddTransaction;

  /// accountFormTitleNew
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountFormTitleNew;

  /// accountFormTitleEdit
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountFormTitleEdit;

  /// accountNameLabel
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountNameLabel;

  /// accountTypeLabel
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountTypeLabel;

  /// accountCurrencyLabel
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountCurrencyLabel;

  /// accountInitialBalanceLabel
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get accountInitialBalanceLabel;

  /// accountSave
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get accountSave;

  /// accountDetailTitle
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountDetailTitle;

  /// accountDelete
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// accountTransactionsTitle
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get accountTransactionsTitle;

  /// accountBalanceLabel
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get accountBalanceLabel;

  /// accountEdit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get accountEdit;

  /// transactionFormNewExpenseTitle
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get transactionFormNewExpenseTitle;

  /// transactionFormNewIncomeTitle
  ///
  /// In en, this message translates to:
  /// **'New income'**
  String get transactionFormNewIncomeTitle;

  /// transactionFormTransferTitle
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionFormTransferTitle;

  /// transactionFormEditTitle
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionFormEditTitle;

  /// transactionTypeLabel
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionTypeLabel;

  /// transactionAmountLabel
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmountLabel;

  /// transactionCurrencyLabel
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get transactionCurrencyLabel;

  /// transactionDateLabel
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDateLabel;

  /// transactionNoteLabel
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transactionNoteLabel;

  /// transactionAccountLabel
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionAccountLabel;

  /// transactionToAccountLabel
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get transactionToAccountLabel;

  /// transactionReceiptLabel
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get transactionReceiptLabel;

  /// transactionSave
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transactionSave;

  /// transactionDelete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionDelete;

  /// transactionDraftBadge
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get transactionDraftBadge;

  /// transactionConfirmDraft
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get transactionConfirmDraft;

  /// transactionTransferSameAccount
  ///
  /// In en, this message translates to:
  /// **'Transfer needs two different accounts.'**
  String get transactionTransferSameAccount;

  /// transactionAccountRequired
  ///
  /// In en, this message translates to:
  /// **'An account is required.'**
  String get transactionAccountRequired;

  /// transactionTransferAccountsRequired
  ///
  /// In en, this message translates to:
  /// **'Both accounts are required for a transfer.'**
  String get transactionTransferAccountsRequired;

  /// transactionAmountPositive
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get transactionAmountPositive;

  /// receiptListTitle
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptListTitle;

  /// receiptCapture
  ///
  /// In en, this message translates to:
  /// **'Capture receipt'**
  String get receiptCapture;

  /// receiptCaptureStandalone
  ///
  /// In en, this message translates to:
  /// **'Standalone receipt'**
  String get receiptCaptureStandalone;

  /// receiptUploadSuccess
  ///
  /// In en, this message translates to:
  /// **'Receipt uploaded'**
  String get receiptUploadSuccess;

  /// receiptUploadError
  ///
  /// In en, this message translates to:
  /// **'Failed to upload receipt'**
  String get receiptUploadError;

  /// receiptViewTitle
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptViewTitle;

  /// receiptStatusLocal
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get receiptStatusLocal;

  /// receiptStatusUploading
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get receiptStatusUploading;

  /// receiptStatusUploaded
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get receiptStatusUploaded;

  /// receiptStatusError
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get receiptStatusError;

  /// receiptAttach
  ///
  /// In en, this message translates to:
  /// **'Attach to transaction'**
  String get receiptAttach;

  /// receiptChooseSource
  ///
  /// In en, this message translates to:
  /// **'Choose source'**
  String get receiptChooseSource;

  /// receiptFromCamera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get receiptFromCamera;

  /// receiptFromGallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get receiptFromGallery;

  /// commonRetry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// settingsBaseCurrency
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get settingsBaseCurrency;

  /// settingsCategoryFx
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get settingsCategoryFx;

  /// settingsRefreshRates
  ///
  /// In en, this message translates to:
  /// **'Refresh rates'**
  String get settingsRefreshRates;

  /// settingsEditRate
  ///
  /// In en, this message translates to:
  /// **'Edit rate'**
  String get settingsEditRate;

  /// settingsRateBase
  ///
  /// In en, this message translates to:
  /// **'Per 1 {base}'**
  String settingsRateBase(Object base);

  /// settingsRateInvalid
  ///
  /// In en, this message translates to:
  /// **'Enter a positive rate.'**
  String get settingsRateInvalid;

  /// tabBudget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get tabBudget;

  /// tabExperiments
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get tabExperiments;

  /// No description provided for @experimentsAppBar.
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get experimentsAppBar;

  /// No description provided for @experimentsFab.
  ///
  /// In en, this message translates to:
  /// **'New experiment'**
  String get experimentsFab;

  /// No description provided for @experimentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No experiments yet'**
  String get experimentsEmptyTitle;

  /// No description provided for @experimentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create an experiment to track a habit, diet change, or training protocol with daily check-ins.'**
  String get experimentsEmptyBody;

  /// No description provided for @plannerSegmentCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get plannerSegmentCalendar;

  /// No description provided for @plannerSegmentExperiments.
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get plannerSegmentExperiments;

  /// No description provided for @experimentLinkedTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked tasks'**
  String get experimentLinkedTasksTitle;

  /// No description provided for @experimentLinkTask.
  ///
  /// In en, this message translates to:
  /// **'Link task'**
  String get experimentLinkTask;

  /// No description provided for @experimentUnlinkTask.
  ///
  /// In en, this message translates to:
  /// **'Unlink task'**
  String get experimentUnlinkTask;

  /// No description provided for @experimentNoLinkedTasks.
  ///
  /// In en, this message translates to:
  /// **'No linked tasks yet. Link tasks to follow the steps of this experiment.'**
  String get experimentNoLinkedTasks;

  /// No description provided for @experimentSearchTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks…'**
  String get experimentSearchTasksHint;

  /// experimentDaysElapsed
  ///
  /// In en, this message translates to:
  /// **'{days} days elapsed'**
  String experimentDaysElapsed(int days);

  /// No description provided for @experimentStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get experimentStatusPlanned;

  /// No description provided for @experimentStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get experimentStatusActive;

  /// No description provided for @experimentStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get experimentStatusDone;

  /// No description provided for @experimentStatusAborted.
  ///
  /// In en, this message translates to:
  /// **'Aborted'**
  String get experimentStatusAborted;

  /// No description provided for @experimentCategoryWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get experimentCategoryWorkout;

  /// No description provided for @experimentCategoryDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get experimentCategoryDiet;

  /// No description provided for @experimentCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get experimentCategoryBody;

  /// No description provided for @experimentCategorySteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get experimentCategorySteps;

  /// No description provided for @experimentFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New experiment'**
  String get experimentFormTitleNew;

  /// No description provided for @experimentFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit experiment'**
  String get experimentFormTitleEdit;

  /// No description provided for @experimentFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get experimentFormNameLabel;

  /// No description provided for @experimentFormNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8-week hypertrophy block'**
  String get experimentFormNameHint;

  /// No description provided for @experimentFormPurposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Hypothesis / purpose'**
  String get experimentFormPurposeLabel;

  /// No description provided for @experimentFormPurposeHint.
  ///
  /// In en, this message translates to:
  /// **'What are you testing?'**
  String get experimentFormPurposeHint;

  /// No description provided for @experimentFormStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get experimentFormStartLabel;

  /// No description provided for @experimentFormEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get experimentFormEndLabel;

  /// No description provided for @experimentFormStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get experimentFormStatusLabel;

  /// No description provided for @experimentFormCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracked data'**
  String get experimentFormCategoriesLabel;

  /// No description provided for @experimentFormReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in reminder'**
  String get experimentFormReminderLabel;

  /// No description provided for @experimentFormReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A notification opens this experiment for a quick rating.'**
  String get experimentFormReminderSubtitle;

  /// No description provided for @experimentFormReminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get experimentFormReminderTimeLabel;

  /// No description provided for @experimentFormDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get experimentFormDelete;

  /// No description provided for @experimentFormDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete experiment?'**
  String get experimentFormDeleteConfirmTitle;

  /// No description provided for @experimentFormDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This also removes the experiment\'s check-ins.'**
  String get experimentFormDeleteConfirmBody;

  /// No description provided for @experimentFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the experiment a name.'**
  String get experimentFormNameRequired;

  /// No description provided for @experimentFormInvalidDates.
  ///
  /// In en, this message translates to:
  /// **'The end date must be on or after the start date.'**
  String get experimentFormInvalidDates;

  /// No description provided for @experimentDetailCheckin.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get experimentDetailCheckin;

  /// No description provided for @experimentDetailCheckinToday.
  ///
  /// In en, this message translates to:
  /// **'You already checked in today. You can update it.'**
  String get experimentDetailCheckinToday;

  /// No description provided for @experimentDetailCheckinDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get experimentDetailCheckinDialogTitle;

  /// No description provided for @experimentDetailCheckinRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get experimentDetailCheckinRatingLabel;

  /// No description provided for @experimentDetailCheckinRatingHint.
  ///
  /// In en, this message translates to:
  /// **'1 = rough day, 5 = excellent day'**
  String get experimentDetailCheckinRatingHint;

  /// No description provided for @experimentDetailCheckinNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get experimentDetailCheckinNoteLabel;

  /// No description provided for @experimentDetailCheckinNoteHint.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get experimentDetailCheckinNoteHint;

  /// No description provided for @experimentDetailProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get experimentDetailProgressTitle;

  /// No description provided for @experimentDetailCheckinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get experimentDetailCheckinsTitle;

  /// No description provided for @experimentDetailTrackedTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracked data'**
  String get experimentDetailTrackedTitle;

  /// No description provided for @experimentDetailBaselineTitle.
  ///
  /// In en, this message translates to:
  /// **'14-day baseline'**
  String get experimentDetailBaselineTitle;

  /// No description provided for @experimentDetailNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period yet.'**
  String get experimentDetailNoData;

  /// No description provided for @experimentDetailMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get experimentDetailMarkDone;

  /// No description provided for @experimentDetailAbort.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get experimentDetailAbort;

  /// experimentDetailCheckinCount
  ///
  /// In en, this message translates to:
  /// **'{count} check-ins'**
  String experimentDetailCheckinCount(int count);

  /// experimentRatingOf5
  ///
  /// In en, this message translates to:
  /// **'{rating}/5'**
  String experimentRatingOf5(int rating);

  /// No description provided for @experimentChartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout volume (kg)'**
  String get experimentChartWorkout;

  /// No description provided for @experimentChartDiet.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get experimentChartDiet;

  /// No description provided for @experimentChartDietProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get experimentChartDietProtein;

  /// No description provided for @experimentChartWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get experimentChartWeight;

  /// No description provided for @experimentChartSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get experimentChartSteps;

  /// experimentReminderTitle
  ///
  /// In en, this message translates to:
  /// **'Check in on {experiment}'**
  String experimentReminderTitle(String experiment);

  /// No description provided for @experimentReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Rate your day for this experiment.'**
  String get experimentReminderBody;

  /// experimentReminderScheduled
  ///
  /// In en, this message translates to:
  /// **'Daily reminder set for {time}.'**
  String experimentReminderScheduled(String time);

  /// No description provided for @experimentReminderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder disabled.'**
  String get experimentReminderCancelled;
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
