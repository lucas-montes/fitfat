// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FitFat';

  @override
  String get tabDashboard => 'Tableau de bord';

  @override
  String get tabExercise => 'Exercice';

  @override
  String get tabDiet => 'Alimentation';

  @override
  String get tabSettings => 'Paramètres';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabNotes => 'Notes';

  @override
  String get dashboardAppBar => 'Tableau de bord';

  @override
  String get dashboardTodayCalories => 'Calories du jour';

  @override
  String get dashboardLatestWorkout => 'Dernière séance';

  @override
  String get dashboardNoWorkouts => 'Aucune séance terminée.';

  @override
  String get dashboardWelcomeTitle => 'Bienvenue sur FitFat';

  @override
  String get dashboardWelcomeBody =>
      'Commencez par ajouter un ingrédient, un repas ou une séance.';

  @override
  String get dashboardWelcomeActionIngredients => 'Ajouter un ingrédient';

  @override
  String get dashboardWelcomeActionMeals => 'Enregistrer un repas';

  @override
  String get dashboardWelcomeActionWorkouts => 'Ajouter une séance';

  @override
  String dashboardDurationMin(int minutes) {
    return 'Durée : $minutes min';
  }

  @override
  String dashboardCaloriesValue(String calories) {
    return '$calories kcal';
  }

  @override
  String dashboardError(String message) {
    return 'Erreur : $message';
  }

  @override
  String get dashboardGreetingMorning => 'Bonjour';

  @override
  String get dashboardGreetingAfternoon => 'Bon après-midi';

  @override
  String get dashboardGreetingEvening => 'Bonsoir';

  @override
  String get dashboardMacroCalories => 'Calories';

  @override
  String get dashboardMacroFiber => 'Fibres';

  @override
  String get dashboardMacroProtein => 'Protéines';

  @override
  String get dashboardMacroCarbs => 'Glucides';

  @override
  String get dashboardMacroFat => 'Lipides';

  @override
  String get dashboardContinueWorkout => 'Continuer la séance';

  @override
  String get dashboardOpenWorkout => 'Ouvrir la séance';

  @override
  String get dashboardCalorieTarget => 'Objectif calorique quotidien';

  @override
  String dashboardConsumedOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String dashboardMacroProgress(String consumed, String target) {
    return '$consumed / $target g';
  }

  @override
  String get dashboardWeightTrend => 'Évolution du poids';

  @override
  String get dashboardWeeklyWorkout => 'Séances de la semaine';

  @override
  String get dashboardVolume => 'Volume';

  @override
  String get dashboardDaysTrained => 'Jours';

  @override
  String dashboardDaysTrainedValue(int count) {
    return '$count/7';
  }

  @override
  String get dashboardHoursTrained => 'Temps';

  @override
  String dashboardHoursTrainedHours(Object hours) {
    return '$hours h';
  }

  @override
  String dashboardHoursTrainedMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String dashboardHoursTrainedHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes m';
  }

  @override
  String get dashboardGoalsTitle => 'Objectifs';

  @override
  String get dashboardGoalsEmpty => 'Aucun objectif actif';

  @override
  String get dashboardGoalsCta => 'Objectifs';

  @override
  String get dashboardAddTitle => 'Ajouter';

  @override
  String get dietAddMeal => 'Repas';

  @override
  String get dietAddRecipe => 'Recette';

  @override
  String get dietAddIngredient => 'Ingrédient';

  @override
  String get dashboardMinutes => 'Minutes';

  @override
  String get dashboardUpcomingTasks => 'Tâches à venir';

  @override
  String get dashboardNoUpcomingTasks => 'Aucune tâche à horaire à venir.';

  @override
  String dashboardSeeAllTasks(String count) {
    return 'Voir les $count tâches';
  }

  @override
  String get dashboardCalorieTargetEmptyTitle => 'Complete your profile';

  @override
  String get dashboardCalorieTargetEmptyBody =>
      'Add your age, gender, weight and height to see your daily calorie target.';

  @override
  String get dashboardMacroEmptyTitle => 'Complete your profile';

  @override
  String get dashboardMacroEmptyBody =>
      'Add your profile details to see macro targets.';

  @override
  String get dashboardMacroEmptyCta => 'Complete profile';

  @override
  String get dashboardWeeklyEmptyTitle => 'No workouts yet';

  @override
  String get dashboardWeeklyEmptyBody =>
      'Log your first workout or sync from server.';

  @override
  String get dashboardWeeklyEmptyCtaCreate => 'Add workout';

  @override
  String get dashboardWeeklyEmptyCtaSync => 'Sync exercises';

  @override
  String get dashboardUpcomingEmptyCta => 'Add task';

  @override
  String get dashboardLatestEmptyCta => 'Add workout';

  @override
  String get exerciseListAppBar => 'Exercices';

  @override
  String get exerciseListManageBtn => 'Gérer les exercices';

  @override
  String get exerciseListSearchHint => 'Rechercher des exercices';

  @override
  String get exerciseFilterType => 'Type';

  @override
  String get exerciseFilterBodyPart => 'Partie du corps';

  @override
  String get exerciseFilterEquipment => 'Équipement';

  @override
  String get exerciseFilterMuscle => 'Muscle';

  @override
  String exerciseFilterResults(int count) {
    return '$count exercices';
  }

  @override
  String get exerciseFilterClear => 'Effacer';

  @override
  String get exerciseFilterApply => 'Appliquer';

  @override
  String get exerciseFilterNoResults => 'Aucun exercice ne correspond';

  @override
  String get exerciseFilterSearchOptions => 'Rechercher des options';

  @override
  String get exerciseDetailTabHistory => 'Historique';

  @override
  String get exerciseDetailTabDetails => 'Détails';

  @override
  String get emptyExercisesTitle => 'Aucun exercice pour l\'instant';

  @override
  String get emptyExercisesBody =>
      'Créez des exercices pour planifier vos entraînements.';

  @override
  String get emptyExercisesCta => 'Ajouter un exercice';

  @override
  String get activeWorkoutAddExercise => 'Ajouter un exercice';

  @override
  String get activeWorkoutAddExerciseTooltip =>
      'Rechercher et ajouter des exercices à cet entraînement';

  @override
  String activeWorkoutPlannedSetsTitle(String exercise) {
    return 'Séries planifiées pour $exercise';
  }

  @override
  String get activeWorkoutPlannedRepsLabel => 'Répétitions';

  @override
  String get activeWorkoutPlannedWeightLabel => 'Poids';

  @override
  String get activeWorkoutReorderSets => 'Réordonner les séries';

  @override
  String get activeWorkoutEditPlannedTitle => 'Modifier la série prévue';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get activeWorkoutPrevExercise => 'Exercice précédent';

  @override
  String get activeWorkoutNextExercise => 'Exercice suivant';

  @override
  String get activeWorkoutInThisWorkout => 'Dans cet entraînement';

  @override
  String get activeWorkoutAllExercises => 'Tous les exercices';

  @override
  String get activeWorkoutSearchPrompt => 'Tapez pour rechercher des exercices';

  @override
  String get activeWorkoutExerciseNotes => 'Notes';

  @override
  String get activeWorkoutExerciseInfo => 'Infos exercice';

  @override
  String get activeWorkoutExerciseNotesDialogTitle => 'Notes sur l\'exercice';

  @override
  String get activeWorkoutExerciseNotesHint =>
      'Notez ce qu\'il faut refaire ou changer la prochaine fois (séries, charge, difficulté)…';

  @override
  String get exerciseUsedTitle => 'Exercice utilisé';

  @override
  String exerciseUsedBody(int count) {
    return 'Utilisé dans $count entraînement. Supprimez d\'abord l\'entraînement pour retirer cet exercice.';
  }

  @override
  String exerciseUsedBody_plural(Object count) {
    return 'Utilisé dans $count entraînements. Supprimez d\'abord les entraînements pour retirer cet exercice.';
  }

  @override
  String get exerciseDetailAppBar => 'Exercice';

  @override
  String get exerciseDetailNotFound => 'Exercice introuvable.';

  @override
  String get exerciseDetailType => 'Type';

  @override
  String get exerciseDetailBodyPart => 'Partie du corps';

  @override
  String get exerciseDetailEquipment => 'Équipement';

  @override
  String get exerciseDetailPrimaryMuscle => 'Muscles principaux';

  @override
  String get exerciseDetailSecondaryMuscle => 'Muscles secondaires';

  @override
  String get exerciseDetailInstructions => 'Instructions';

  @override
  String get exerciseDetailTips => 'Conseils';

  @override
  String get exerciseDetailFaqs => 'FAQ';

  @override
  String get exerciseDetailKeywords => 'Mots-clés';

  @override
  String get exerciseDetailHistory => 'Historique';

  @override
  String get exerciseDetailHistoryEmpty =>
      'Aucun historique. Ajoutez cet exercice à un entraînement pour voir vos statistiques.';

  @override
  String get exerciseDetailBestWeight => 'Poids maximal';

  @override
  String get exerciseDetailBestVolume => 'Meilleur volume';

  @override
  String get exerciseDetailBestDuration => 'Durée maximale';

  @override
  String get exerciseDetailTotalWorkouts => 'Entraînements';

  @override
  String get exerciseDetailTotalSets => 'Séries';

  @override
  String get exerciseDetailVolumeOverTime => 'Volume au fil du temps';

  @override
  String get exerciseDetailDurationOverTime => 'Durée au fil du temps';

  @override
  String get exerciseDetailPlannedVsActual => 'Planifié vs réel';

  @override
  String get exerciseDetailVolumeAdherence => 'Adhésion au volume';

  @override
  String get exerciseDetailSetsCompleted => 'Séries terminées';

  @override
  String exerciseDetailAdherenceValue(String percent) {
    return '$percent%';
  }

  @override
  String exerciseDetailSetNumber(int number) {
    return 'Série $number';
  }

  @override
  String get exerciseDetailSetCompleted => 'Terminée';

  @override
  String get exerciseDetailSetNotCompleted => 'Non terminée';

  @override
  String get exerciseDetailSetEmpty => '—';

  @override
  String exerciseDetailRepsDelta(String delta) {
    return '$delta rép.';
  }

  @override
  String exerciseDetailWeightDelta(String delta, String unit) {
    return '$delta $unit';
  }

  @override
  String exerciseDetailSetRest(String rest) {
    return 'repos $rest';
  }

  @override
  String exerciseDetailSetRestTook(String rest) {
    return '(pris $rest)';
  }

  @override
  String get exerciseDetailTrendSame => 'identique à la séance précédente';

  @override
  String exerciseDetailTrendDelta(String delta, String unit) {
    return '$delta $unit par rapport à la séance précédente';
  }

  @override
  String get exerciseDetailPrBadge => 'Record';

  @override
  String get exerciseDetailSetHeader => 'Série';

  @override
  String get exerciseDetailSetHeaderPlanned => 'Prévu';

  @override
  String get exerciseDetailSetHeaderActual => 'Réel';

  @override
  String get exerciseDetailSetHeaderDelta => 'Δ';

  @override
  String get exerciseDetailSetHeaderRest => 'Repos';

  @override
  String get exerciseDetailWeightTrend => 'Poids max au fil du temps';

  @override
  String get exerciseDetailRepsTrend => 'Répétitions au fil du temps';

  @override
  String get exerciseFormNewTitle => 'Nouvel exercice';

  @override
  String get exerciseFormEditTitle => 'Modifier l\'exercice';

  @override
  String get exerciseFormNameLabel => 'Nom de l\'exercice';

  @override
  String get exerciseFormNameHint => 'Ex. : Développé couché';

  @override
  String get exerciseFormNameRequired => 'Le nom est requis';

  @override
  String get exerciseFormTypeLabel => 'Type';

  @override
  String get exerciseFormMetLabel => 'Dépense énergétique (MET, facultatif)';

  @override
  String get exerciseFormMetHelper =>
      'Sert à estimer les calories. La marche vaut environ 3,5, la course environ 8. Choisissez une valeur prédéfinie ou laissez vide.';

  @override
  String get exerciseFormMetInvalid => 'Saisissez un nombre de 1 à 25';

  @override
  String get metPresetSkating => 'Patin';

  @override
  String get metPresetCycling => 'Vélo';

  @override
  String get metPresetSwimming => 'Natation';

  @override
  String get metPresetHiking => 'Randonnée';

  @override
  String get metPresetFootball => 'Football';

  @override
  String get exerciseFormSave => 'Enregistrer';

  @override
  String get exerciseFormSaving => 'Enregistrement…';

  @override
  String get workoutListAppBar => 'Séances';

  @override
  String get templatesTitle => 'Modèles';

  @override
  String get templatesEmptyTitle => 'Aucun modèle pour l\'instant';

  @override
  String get templatesEmptyBody =>
      'Créez une routine réutilisable ou enregistrez une séance passée comme modèle.';

  @override
  String get templatesNew => 'Nouveau modèle';

  @override
  String get templatesEdit => 'Modifier le modèle';

  @override
  String get templatesStartToday => 'Commencer aujourd\'hui';

  @override
  String templatesExercisesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercices',
      one: '1 exercice',
      zero: 'Aucun exercice',
    );
    return '$_temp0';
  }

  @override
  String get templatesScheduleOff => 'Non programmé';

  @override
  String get templatesScheduleDaily => 'Tous les jours';

  @override
  String templatesScheduleWeekly(Object days) {
    return 'Hebdomadaire : $days';
  }

  @override
  String templatesScheduleInterval(Object days) {
    return 'Tous les $days jours';
  }

  @override
  String get templatesDeleteConfirmTitle => 'Supprimer le modèle ?';

  @override
  String get templatesDeleteConfirmBody =>
      'Le plan sera supprimé. Les séances déjà commencées sont conservées.';

  @override
  String get templatesAddSet => 'Ajouter une série';

  @override
  String get workoutListManageBtn => 'Gérer les exercices';

  @override
  String get emptyWorkoutsTitle => 'Aucune séance';

  @override
  String get emptyWorkoutsBody =>
      'Planifiez votre première séance et lancez-vous.';

  @override
  String get emptyWorkoutsCta => 'Ajouter une séance';

  @override
  String workoutDeleted(String name) {
    return 'Séance « $name » supprimée';
  }

  @override
  String get workoutFormTitle => 'Nouvelle séance';

  @override
  String get workoutFormEditTitle => 'Modifier la séance';

  @override
  String get workoutFormNameLabel => 'Nom de la séance';

  @override
  String get workoutFormNameHint => 'Ex. : Séance du matin';

  @override
  String get workoutFormNameRequired => 'Le nom est requis';

  @override
  String get workoutFormDate => 'Date';

  @override
  String get workoutFormAddPlannerTask => 'Ajouter au planning';

  @override
  String get workoutFormAddPlannerTaskSubtitle =>
      'Crée une tâche « faire cette séance » au planning pour cette date.';

  @override
  String get workoutFormExercises => 'Exercices';

  @override
  String get workoutFormAddExercise => 'Ajouter un exercice';

  @override
  String get workoutFormRemoveSet => 'Supprimer la série';

  @override
  String get workoutFormReorderExercises => 'Réorganiser les exercices';

  @override
  String get workoutFormNoExercises =>
      'Aucun exercice disponible. Ajoutez-en d\'abord.';

  @override
  String get workoutFormSave => 'Enregistrer';

  @override
  String get workoutFormSaving => 'Enregistrement…';

  @override
  String get workoutFormAddSet => 'Ajouter une série';

  @override
  String get workoutFormRepsLabel => 'Répétitions';

  @override
  String get workoutFormWeightLabel => 'kg';

  @override
  String get workoutFormDurationLabel => 'min';

  @override
  String get workoutFormDistanceLabel => 'Distance (m)';

  @override
  String get workoutFormSelectExercise => 'Sélectionnez au moins un exercice';

  @override
  String get workoutFormSearchHint => 'Rechercher des exercices';

  @override
  String get workoutFormRestLabel => 'Repos (min)';

  @override
  String get workoutFormSetDoneAt => 'Faite à';

  @override
  String get workoutFormSetDoneAtTooltip =>
      'Quand cette série s\'est terminée : le repos se mesure à partir d\'ici';

  @override
  String get workoutFormSetTimeEmpty => 'Heure de la série';

  @override
  String get workoutFormSetIncomplete =>
      'Complétez les valeurs de chaque série ajoutée ou retirez-la';

  @override
  String get cardioAddDistance => 'Ajouter la distance';

  @override
  String get workoutFormRemoveExercise => 'Retirer l\'exercice';

  @override
  String workoutFormCreateExercise(Object query) {
    return 'Créer un exercice « $query »';
  }

  @override
  String get workoutDetailAppBar => 'Séance';

  @override
  String get workoutDetailNotFound => 'Séance introuvable';

  @override
  String get workoutDetailBtnStart => 'Commencer';

  @override
  String get workoutDetailBtnComplete => 'Terminer';

  @override
  String workoutDetailStartedAt(String time) {
    return 'Début : $time';
  }

  @override
  String get workoutDetailExercises => 'Exercices';

  @override
  String get emptyWorkoutDetailTitle => 'Aucun exercice dans cette séance';

  @override
  String get emptyWorkoutDetailBody =>
      'Ajoutez des exercices lors de la création d\'une séance.';

  @override
  String get workoutDetailSetHeaderActual => 'Réel';

  @override
  String workoutDetailSetChipRest(String planned, String rest) {
    return '$planned · $rest';
  }

  @override
  String workoutDetailSetActualsTitle(int number) {
    return 'Série $number — Réel';
  }

  @override
  String get workoutDetailActualRepsLabel => 'Répétitions réelles';

  @override
  String get workoutDetailActualWeightLabel => 'Charge réelle (kg)';

  @override
  String workoutDetailActualWeightLabelUnit(String unit) {
    return 'Charge réelle ($unit)';
  }

  @override
  String get workoutDetailActualDurationLabel => 'Durée (min)';

  @override
  String get workoutDetailActualDistanceLabel => 'Distance (m)';

  @override
  String workoutDetailSetCount(int count) {
    return '$count série';
  }

  @override
  String workoutDetailSetCount_plural(Object count) {
    return '$count séries';
  }

  @override
  String get ingredientListAppBar => 'Ingrédients';

  @override
  String get emptyIngredientsTitle => 'Aucun ingrédient';

  @override
  String get emptyIngredientsBody =>
      'Ajoutez votre premier ingrédient pour composer des repas.';

  @override
  String get emptyIngredientsCta => 'Ajouter un ingrédient';

  @override
  String ingredientArchived(String name) {
    return 'Ingrédient « $name » archivé';
  }

  @override
  String get ingredientFormNewTitle => 'Nouvel ingrédient';

  @override
  String get ingredientFormEditTitle => 'Modifier l\'ingrédient';

  @override
  String get ingredientFormNameLabel => 'Nom';

  @override
  String get ingredientFormNameHint => 'Ex. : Blanc de poulet';

  @override
  String get ingredientFormNameRequired => 'Le nom est requis';

  @override
  String get ingredientFormCaloriesLabel => 'Calories (pour 100 g)';

  @override
  String get ingredientFormCaloriesSuffix => 'kcal';

  @override
  String get ingredientFormProteinLabel => 'Protéines (pour 100 g)';

  @override
  String get ingredientFormProteinSuffix => 'g';

  @override
  String get ingredientFormCarbsLabel => 'Glucides (pour 100 g)';

  @override
  String get ingredientFormCarbsSuffix => 'g';

  @override
  String get ingredientFormFatLabel => 'Lipides (pour 100 g)';

  @override
  String get ingredientFormFatSuffix => 'g';

  @override
  String get ingredientFormSodiumLabel => 'Sodium (pour 100 g)';

  @override
  String get ingredientFormSodiumSuffix => 'g';

  @override
  String get ingredientFormFiberLabel => 'Fibres (pour 100 g)';

  @override
  String get ingredientFormFiberSuffix => 'g';

  @override
  String get ingredientFormSugarLabel => 'Sucre (pour 100 g)';

  @override
  String get ingredientFormSugarSuffix => 'g';

  @override
  String ingredientFormFieldRequired(String label) {
    return '$label est requis';
  }

  @override
  String ingredientFormFieldPositive(String label) {
    return '$label doit être positif';
  }

  @override
  String ingredientFormFieldNonNegative(String label) {
    return '$label ne peut pas être négatif';
  }

  @override
  String mealListUnnamedMeal(String date, String time) {
    return 'Repas · $date $time';
  }

  @override
  String get foodPickerTitle => 'Ajouter des aliments';

  @override
  String get foodPickerSearchHint => 'Rechercher recettes et ingrédients';

  @override
  String get foodPickerSectionRecipes => 'Recettes';

  @override
  String get foodPickerSectionIngredients => 'Ingrédients seuls';

  @override
  String get foodPickerEmpty => 'Aucun résultat.';

  @override
  String get foodPickerNoFoods =>
      'Aucun aliment pour l’instant. Ajoutez un ingrédient pour commencer — chacun s’enregistre seul.';

  @override
  String foodPickerNeedsAmount(String name) {
    return '$name a besoin d\'une quantité avant d\'enregistrer';
  }

  @override
  String foodPickerCaloriesCooked(String portion, String per100g) {
    return '$portion kcal pour cette portion · $per100g/100 g cuits';
  }

  @override
  String mealListTotals(
    String amount,
    String protein,
    String carbs,
    String fat,
    String fiber,
  ) {
    return '$amount g  ·  P $protein  ·  C $carbs  ·  F $fat  ·  Fibres $fiber';
  }

  @override
  String get foodPickerDone => 'Terminé';

  @override
  String mealFormSelectedSummary(int count, String calories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments sélectionnés',
      one: '1 aliment sélectionné',
      zero: 'Aucun aliment sélectionné',
    );
    return '$_temp0 · $calories kcal';
  }

  @override
  String get mealFormChooseFoods => 'Choisir des aliments';

  @override
  String get ingredientDetailOwnFoodTitle => 'Enregistrable seul';

  @override
  String get ingredientDetailOwnFoodBody =>
      'Cet ingrédient a son propre aliment : vous pouvez donc l’enregistrer directement sans créer de recette. Sa nutrition correspond aux valeurs pour 100g ci-dessus.';

  @override
  String get mealListAppBar => 'Repas';

  @override
  String get mealListManageBtn => 'Gérer les ingrédients';

  @override
  String get emptyMealsTitle => 'Aucun repas';

  @override
  String get emptyMealsBody =>
      'Enregistrez votre premier repas pour suivre calories et macronutriments.';

  @override
  String get emptyMealsCta => 'Enregistrer un repas';

  @override
  String get mealFormDeleteTitle => 'Supprimer ce repas ?';

  @override
  String get mealFormDeleteBody =>
      'Il sera retiré de votre journal et de vos totaux quotidiens.';

  @override
  String mealDeleted(String name) {
    return 'Repas « $name » supprimé';
  }

  @override
  String mealListFoodCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
      zero: 'aucun aliment',
    );
    return '$_temp0';
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
    return '${grams}g  ·  $calories kcal  ·  P ${protein}g  ·  G ${carbs}g  ·  L ${fat}g';
  }

  @override
  String get mealFormNewTitle => 'Nouveau repas';

  @override
  String get mealFormEditTitle => 'Modifier le repas';

  @override
  String get mealFormNameLabel => 'Nom du repas';

  @override
  String get mealFormNameHint => 'Facultatif';

  @override
  String get mealFormNameOptionalHint =>
      'Laissez vide et il sera identifié par sa date';

  @override
  String get mealFormNameRequired => 'Le nom est requis';

  @override
  String get mealFormDateTime => 'Date et heure';

  @override
  String get mealFormIngredients => 'Ingrédients';

  @override
  String get mealFormNoIngredients =>
      'Aucun ingrédient disponible. Ajoutez-en d\'abord.';

  @override
  String get mealFormAddIngredient =>
      'Ajoutez au moins un ingrédient avec des grammes';

  @override
  String get foodListAppBar => 'Recettes';

  @override
  String foodListPartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingrédients',
      one: '1 ingrédient',
    );
    return '$_temp0';
  }

  @override
  String get foodListUnresolved =>
      'Ingrédients manquants — valeurs nutritionnelles impossibles à calculer';

  @override
  String foodListCookedWeight(String grams) {
    return 'Poids cuit $grams g';
  }

  @override
  String foodListCreatedOn(String date) {
    return 'Créée le $date';
  }

  @override
  String foodArchived(String name) {
    return '$name archivée';
  }

  @override
  String get emptyFoodsTitle => 'Aucune recette pour l’instant';

  @override
  String get emptyFoodsBody =>
      'Combinez deux ingrédients ou plus en un aliment à enregistrer d’un seul geste. Les valeurs nutritionnelles sont calculées à partir des ingrédients ajoutés.';

  @override
  String get emptyFoodsCta => 'Créer une recette';

  @override
  String get foodFormNewTitle => 'Nouvelle recette';

  @override
  String get foodFormEditTitle => 'Modifier la recette';

  @override
  String get foodFormNameLabel => 'Nom';

  @override
  String get foodFormNameHint => 'ex. Granola';

  @override
  String get foodFormNameRequired => 'Le nom est obligatoire';

  @override
  String get foodFormComposition => 'Ingrédients';

  @override
  String get foodFormCompositionHint =>
      'Les quantités indiquent la part de chaque ingrédient. Leur somme forme le poids cru du lot.';

  @override
  String get foodFormSearchPrompt => 'Recherchez un ingrédient à ajouter.';

  @override
  String get foodFormNoMatches =>
      'Aucun ingrédient ne correspond à la recherche.';

  @override
  String get foodFormCookedWeightLabel => 'Poids final après cuisson';

  @override
  String foodFormCookedWeightHint(String raw) {
    return 'Poids cru $raw g. La cuisson change le poids, pas les calories : la nutrition pour 100 g est calculée à partir de ce poids.';
  }

  @override
  String get foodFormCookedWeightRequired =>
      'Indiquez le poids final (supérieur à zéro).';

  @override
  String foodFormCookedYield(String percent) {
    return '$percent % du poids cru';
  }

  @override
  String get foodFormAddPart => 'Ajouter un ingrédient';

  @override
  String get foodFormNoMoreParts => 'Aucun autre ingrédient à ajouter.';

  @override
  String get foodFormRemovePart => 'Retirer l’ingrédient';

  @override
  String get foodFormAmountLabel => 'Quantité';

  @override
  String get foodFormAmountPositive =>
      'Les quantités doivent être supérieures à zéro.';

  @override
  String get foodFormNeedsParts => 'Ajoutez au moins un ingrédient';

  @override
  String get foodFormPreview => 'Nutrition pour 100g';

  @override
  String get foodFormPreviewCooked => 'Nutrition pour 100 g cuits';

  @override
  String get foodFormPreviewEmpty =>
      'Ajoutez un ingrédient pour voir la nutrition.';

  @override
  String get foodFormPer100g => 'Calculé à partir des quantités ci-dessus.';

  @override
  String foodFormRawToCooked(String raw, String cooked) {
    return 'Cru $raw g → cuit $cooked g';
  }

  @override
  String foodFormBatchCalories(String calories) {
    return '$calories kcal pour tout le lot';
  }

  @override
  String foodFormBatchTotal(String total) {
    return 'Le lot pèse $total';
  }

  @override
  String get foodFormSave => 'Enregistrer la recette';

  @override
  String get foodFormDuplicate => 'Nouvelle fournée à partir de cette recette';

  @override
  String get foodFormSaving => 'Enregistrement…';

  @override
  String get mealFormFoods => 'Aliments';

  @override
  String get mealFormNoFoods =>
      'Aucun aliment pour l’instant. Ajoutez d’abord des ingrédients : chacun devient un aliment que vous pouvez enregistrer seul.';

  @override
  String get mealFormAddFood => 'Ajoutez au moins un aliment avec des grammes';

  @override
  String get mealFormFoodUnresolved =>
      'L’un des aliments sélectionnés contient des ingrédients manquants, ses valeurs nutritionnelles ne peuvent donc pas être calculées. Synchronisez ou ajoutez ces ingrédients d’abord.';

  @override
  String mealFormFoodCalories(String portion, String per100g) {
    return '$portion kcal pour cette portion · $per100g/100g';
  }

  @override
  String get mealFormTotals => 'Total du repas';

  @override
  String get mealItemEditorAmountLabel => 'Quantité';

  @override
  String get mealFormGramsLabel => 'g';

  @override
  String get mealFormSave => 'Enregistrer';

  @override
  String get mealFormSaving => 'Enregistrement…';

  @override
  String get plannerAppBar => 'Plan du jour';

  @override
  String get plannerToday => 'Aujourd\'hui';

  @override
  String get plannerPreviousDay => 'Jour précédent';

  @override
  String get plannerNextDay => 'Jour suivant';

  @override
  String get plannerAnytime => 'À tout moment';

  @override
  String get plannerTimelineScheduled => 'Planifié';

  @override
  String get emptyPlannerTitle => 'Aucune tâche pour ce jour';

  @override
  String get emptyPlannerBody =>
      'Ajoutez une tâche pour planifier votre routine.';

  @override
  String get emptyPlannerCta => 'Ajouter une tâche';

  @override
  String get plannerTaskLabel => 'Tâche';

  @override
  String get plannerTaskHint => 'Ex. : Course du matin';

  @override
  String get plannerTaskRequired => 'Le titre est requis';

  @override
  String get plannerTagsLabel => 'Étiquettes';

  @override
  String get plannerTagsHint =>
      'Ajoutez une étiquette puis + (ex. Travail, Course)';

  @override
  String get plannerTagsAdd => 'Ajouter une étiquette';

  @override
  String get plannerNotesLabel => 'Notes';

  @override
  String get plannerWorkoutLabel => 'Entraînement (optionnel)';

  @override
  String get plannerWorkoutHint => 'Lier un entraînement';

  @override
  String get plannerWorkoutNone => 'Aucun entraînement';

  @override
  String get plannerLinkedWorkout => 'Ouvrir l\'entraînement lié';

  @override
  String get plannerDueDateNone => 'Aucune date limite';

  @override
  String get plannerDueDateClear => 'Effacer la date limite';

  @override
  String get plannerDueTimeNone => 'Aucune heure';

  @override
  String get plannerDueTimeClear => 'Effacer l\'heure';

  @override
  String get plannerStartTimeLabel => 'Heure de début';

  @override
  String get plannerEndTimeLabel => 'Heure de fin';

  @override
  String get plannerStartTimeNone => 'Aucune heure de début';

  @override
  String get plannerEndTimeNone => 'Aucune heure de fin';

  @override
  String get plannerStartTimeClear => 'Effacer l\'heure de début';

  @override
  String get plannerEndTimeClear => 'Effacer l\'heure de fin';

  @override
  String get plannerRepeatInvalid => 'Vérifiez les paramètres de répétition';

  @override
  String get plannerAddTask => 'Nouvelle tâche';

  @override
  String get plannerEditTask => 'Modifier la tâche';

  @override
  String get plannerEditScopeTitle => 'Portée de la modification';

  @override
  String get plannerDeleteScopeTitle => 'Portée de la suppression';

  @override
  String get plannerScopeBody =>
      'Cette tâche se répète. Comment souhaitez-vous procéder ?';

  @override
  String get plannerScopeThis => 'Uniquement celle-ci';

  @override
  String get plannerScopeFollowing => 'Celle-ci et toutes les suivantes';

  @override
  String plannerDeleted(String title) {
    return 'Tâche « $title » supprimée';
  }

  @override
  String plannerCancelled(String title) {
    return 'Tâche « $title » annulée';
  }

  @override
  String get plannerCopyPrevious => 'Copier depuis hier';

  @override
  String get plannerMoreActions => 'Plus d\'actions';

  @override
  String get plannerTaskCancelled => 'Annulée';

  @override
  String get plannerActionMarkDone => 'Marquer faite';

  @override
  String get plannerActionCancelTask => 'Marquer annulée';

  @override
  String get plannerActionReopen => 'Rouvrir';

  @override
  String get plannerCarryOverLabel => 'Reporter si non faite';

  @override
  String get plannerCarryOverHelp =>
      'Si la journée se termine et que cette tâche n\'est pas faite, elle passe à aujourd\'hui. Désactivez pour la marquer annulée.';

  @override
  String get plannerTaskDetailAppBar => 'Détails de la tâche';

  @override
  String plannerDetailUpdatedAt(String date) {
    return 'Créée le $date';
  }

  @override
  String plannerDetailDueDate(String date) {
    return 'Échéance : $date';
  }

  @override
  String plannerDetailTimeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get plannerDetailNotes => 'Notes';

  @override
  String get plannerDetailTags => 'Étiquettes';

  @override
  String get plannerDetailRepeats => 'Répétition';

  @override
  String get plannerDetailLinkedWorkout => 'Séance liée';

  @override
  String get plannerDetailEdit => 'Modifier la tâche';

  @override
  String get plannerDetailDelete => 'Supprimer la tâche';

  @override
  String get plannerDetailDeleteTitle => 'Supprimer la tâche ?';

  @override
  String plannerDetailDeleteBody(String title) {
    return 'Cela supprime la tâche \"$title\".';
  }

  @override
  String get plannerRepeatSummaryDaily => 'Tous les jours';

  @override
  String plannerRepeatSummaryWeekly(String days) {
    return 'Chaque semaine le $days';
  }

  @override
  String plannerRepeatSummaryInterval(int count) {
    return 'Tous les $count jours';
  }

  @override
  String plannerRepeatSummaryMonthly(int day) {
    return 'Mensuelle le jour $day';
  }

  @override
  String plannerRepeatSummaryEndsDate(String date) {
    return ' · jusqu\'au $date';
  }

  @override
  String plannerRepeatSummaryEndsCount(int count) {
    return ' · $count occurrences';
  }

  @override
  String get plannerCopyConfirmTitle => 'Copier les tâches en attente ?';

  @override
  String plannerCopyConfirmBody(int count) {
    return '$count tâche en attente d\'hier sera copiée aujourd\'hui.';
  }

  @override
  String plannerCopyConfirmBody_plural(Object count) {
    return '$count tâches en attente d\'hier seront copiées aujourd\'hui.';
  }

  @override
  String get plannerRepeatLabel => 'Répéter';

  @override
  String get plannerRepeatNone => 'Ne se répète pas';

  @override
  String get plannerRepeatDaily => 'Quotidien';

  @override
  String get plannerRepeatWeekly => 'Hebdomadaire';

  @override
  String get plannerRepeatInterval => 'Tous les N jours';

  @override
  String get plannerRepeatMonthly => 'Mensuel';

  @override
  String get plannerRepeatWeekdays => 'Répéter le';

  @override
  String get plannerRepeatEvery => 'Tous les';

  @override
  String get plannerRepeatDays => 'jours';

  @override
  String get plannerRepeatMonthDay => 'Jour du mois';

  @override
  String get plannerRepeatEnds => 'Se termine';

  @override
  String get plannerRepeatEndsNever => 'Jamais';

  @override
  String get plannerRepeatEndsOnDate => 'À la date';

  @override
  String get plannerRepeatEndsAfter => 'Après';

  @override
  String get plannerRepeatOccurrences => 'occurrences';

  @override
  String get notesAppBar => 'Notes';

  @override
  String get notesEmptyTitle => 'Aucune note pour l\'instant';

  @override
  String get notesEmptyBody =>
      'Capturez tout ce qui vous passe par la tête — routines, recettes, enseignements d\'une séance. Les notes restent privées sur cet appareil.';

  @override
  String get notesFab => 'Nouvelle note';

  @override
  String get notesEditorNewTitle => 'Nouvelle note';

  @override
  String get notesEditorEditTitle => 'Modifier la note';

  @override
  String get notesTitleLabel => 'Titre';

  @override
  String get notesBodyLabel => 'Note';

  @override
  String get notesBodyPreviewTooltip => 'Aperçu';

  @override
  String get notesBodyEditTooltip => 'Modifier';

  @override
  String get notesToolbarBold => 'Gras';

  @override
  String get notesToolbarItalic => 'Italique';

  @override
  String get notesToolbarHeading => 'Titre';

  @override
  String get notesToolbarList => 'Liste';

  @override
  String get notesTitleRequired => 'Le titre est requis';

  @override
  String get notesSave => 'Enregistrer';

  @override
  String get notesEditing => 'Enregistrement…';

  @override
  String get notesDelete => 'Supprimer la note';

  @override
  String get notesDeleteConfirmTitle => 'Supprimer la note ?';

  @override
  String notesDeleteConfirmBody(Object title) {
    return '« $title » sera définitivement supprimée. Cette action est irréversible.';
  }

  @override
  String get notesVoiceRecord => 'Ajouter une note vocale';

  @override
  String notesVoiceRecording(String elapsed) {
    return 'Enregistrement $elapsed';
  }

  @override
  String get notesVoiceStopPlayback => 'Arrêter la lecture';

  @override
  String get notesVoicePlay => 'Lire';

  @override
  String get notesVoiceRemove => 'Supprimer la note vocale';

  @override
  String get notesVoicePermissionDenied =>
      'L’autorisation du microphone est requise pour enregistrer des notes vocales.';

  @override
  String get notesVoiceNone => 'Aucune note vocale pour l’instant';

  @override
  String notesVoiceClipLabel(int index) {
    return 'Clip $index';
  }

  @override
  String notesVoiceCount(int count) {
    return '$count note vocale';
  }

  @override
  String notesVoiceCount_plural(Object count) {
    return '$count notes vocales';
  }

  @override
  String get settingsAppBar => 'Paramètres';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsAgeLabel => 'Âge (ans)';

  @override
  String get settingsAgeInvalid => 'Saisissez un âge entre 0 et 120';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsDarkPalette => 'Palette sombre';

  @override
  String get settingsLightPalette => 'Palette claire';

  @override
  String get settingsPaletteDefault => 'Par défaut';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangFr => 'Français';

  @override
  String get settingsLangEs => 'Español';

  @override
  String get settingsLangSystem => 'Système';

  @override
  String get settingsProfileSubtitle => 'Âge, sexe, activité et objectifs';

  @override
  String get settingsNotificationsSubtitle =>
      'Rappels de tâches et alarme de repos';

  @override
  String get settingsAppearanceLanguage => 'Apparence et langue';

  @override
  String get settingsAppearanceLanguageSubtitle =>
      'Thème et langue de l\'application';

  @override
  String get settingsBodyWeightGoal => 'Objectif de poids';

  @override
  String get settingsGoalLose => 'Perdre du poids';

  @override
  String get settingsGoalMaintain => 'Maintenir le poids';

  @override
  String get settingsGoalGain => 'Prendre du poids';

  @override
  String get settingsGender => 'Sexe';

  @override
  String get settingsGenderMale => 'Homme';

  @override
  String get settingsGenderFemale => 'Femme';

  @override
  String get settingsActivityLevel => 'Niveau d\'activité';

  @override
  String get settingsActivitySedentary => 'Sédentaire';

  @override
  String get settingsActivityLight => 'Léger';

  @override
  String get settingsActivityModerate => 'Modéré';

  @override
  String get settingsActivityActive => 'Actif';

  @override
  String get settingsActivityVeryActive => 'Très actif';

  @override
  String get settingsTrackBodyFat => 'Suivre le taux de masse grasse';

  @override
  String get settingsBodyFatLabel => 'Masse grasse (%)';

  @override
  String get settingsBodyFatInvalid =>
      'Saisissez un taux de masse grasse entre 0 et 70';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPlannerNotifications => 'Rappels de tâches';

  @override
  String get settingsPlannerNotificationsSubtitle =>
      'Me notifier pour les tâches du plan avec une heure prévue.';

  @override
  String get settingsRestAlarmSound => 'Son de l\'alarme de repos';

  @override
  String get settingsRestAlarmVibration => 'Vibration de l\'alarme de repos';

  @override
  String get settingsData => 'Données';

  @override
  String get settingsResetData => 'Réinitialiser toutes les données';

  @override
  String get settingsAdvanced => 'Avancé';

  @override
  String get settingsAdvancedSubtitle =>
      'Horizon du plan, ajustement des calories, minuteurs';

  @override
  String get settingsPlannerHorizonLabel => 'Anticipation du plan (jours)';

  @override
  String get settingsPhasesLabel => 'Phase';

  @override
  String get settingsPhasesHelp =>
      'Vos objectifs de calories et de macros suivent la phase choisie. Chaque phase conserve ses propres réglages.';

  @override
  String get settingsPhaseProteinLabel => 'Protéines (g par kg de poids)';

  @override
  String get settingsPhaseProteinHelp =>
      'Le poids corporel multiplié par ce nombre donne ton objectif quotidien de protéines.';

  @override
  String get settingsPhaseFatLabel => 'Lipides (% des calories)';

  @override
  String get settingsPhaseFatHelp =>
      'Part de ton objectif caloric consacrée aux lipides. Les glucides reçoivent le reste.';

  @override
  String get settingsPhaseFiberLabel => 'Fibres (g)';

  @override
  String get settingsPhaseFiberHelp =>
      'Objectif quotidien de fibres pour cette phase.';

  @override
  String get settingsSetActiveGoal => 'Définir comme objectif actif';

  @override
  String get settingsActiveGoalLabel => 'Objectif actif';

  @override
  String get settingsMacrosExceedWarning =>
      'Les protéines et les lipides dépassent ton objectif, donc les glucides sont à 0.';

  @override
  String get settingsBmrLabel => 'MB';

  @override
  String get settingsTdeeLabel => 'TDEE';

  @override
  String get settingsEstimatedSuffix => 'estimé';

  @override
  String get settingsCalorieAdjustmentLabel =>
      'Ajustement de l\'objectif calorique (kcal)';

  @override
  String get settingsDefaultRestLabel => 'Repos par défaut entre séries (min)';

  @override
  String get settingsReminderLeadLabel => 'Délai du rappel anticipé (min)';

  @override
  String get settingsUntimedReminderLabel => 'Défaut sans heure (min)';

  @override
  String get settingsApiTimeoutLabel =>
      'Délai d\'attente de synchronisation (s)';

  @override
  String get settingsPlannerHorizonHelp =>
      'Combien de jours à l\'avance les tâches récurrentes sont pré-créées dans le planning.';

  @override
  String get settingsCalorieAdjustmentHelp =>
      'Kcal ajoutées à ton objectif quotidien pour cette phase. Négatif = déficit, positif = surplus.';

  @override
  String get settingsDefaultRestHelp =>
      'Préremplit le champ de repos lors de l\'ajout d\'une nouvelle série. Laisser vide pour aucun.';

  @override
  String get settingsReminderLeadHelp =>
      'Minutes avant l\'heure de début d\'une tâche où la notification anticipée se déclenche.';

  @override
  String get settingsUntimedReminderHelp =>
      'Heure des rappels des tâches sans heure, en minutes après minuit (540 = 09h00).';

  @override
  String get settingsApiTimeoutHelp =>
      'Durée pendant laquelle les requêtes de synchronisation attendent le serveur.';

  @override
  String get settingsValueInvalid =>
      'Saisissez un nombre valide positif ou nul.';

  @override
  String get settingsResetDataSubtitle =>
      'Effacer tous les entraînements, repas, mesures, tâches du plan et notes, et rétablir les réglages par défaut.';

  @override
  String get settingsResetDataConfirmTitle =>
      'Réinitialiser toutes les données ?';

  @override
  String get settingsResetDataConfirmBody =>
      'Cela supprime définitivement toutes vos données et réinitialise vos réglages. Cette action est irréversible.';

  @override
  String get settingsResetDataConfirmAction => 'Tout supprimer';

  @override
  String get taskReminderDueSoon => 'À faire dans 30 minutes';

  @override
  String get taskReminderDueNow => 'À faire maintenant';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusActive => 'En cours';

  @override
  String get statusPending => 'En attente';

  @override
  String get exerciseTypeWeightlifting => 'Musculation';

  @override
  String get exerciseTypeCardio => 'Cardio';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonAlsoDeleted => 'Également supprimé';

  @override
  String commonDeleteTitle(String item) {
    return 'Supprimer $item ?';
  }

  @override
  String commonDeleted(String item) {
    return '$item supprimé';
  }

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonUndo => 'Rétablir';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Enregistrement…';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String errorLoadingResource(String resource, String message) {
    return 'Erreur de chargement de $resource : $message';
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
    return '${grams}g  ·  $calories kcal  ·  P ${protein}g  ·  G ${carbs}g  ·  L ${fat}g';
  }

  @override
  String ingredientNutrientSodium(String value) {
    return 'Na ${value}g';
  }

  @override
  String ingredientNutrientFiber(String value) {
    return 'Fibres ${value}g';
  }

  @override
  String ingredientNutrientSugar(String value) {
    return 'Sucre ${value}g';
  }

  @override
  String get ingredientFormBrandLabel => 'Marque';

  @override
  String get ingredientFormBarcodeLabel => 'Code-barres';

  @override
  String get ingredientFormScanTile => 'Scanner le code-barres';

  @override
  String get ingredientFormScanning => 'Scan en cours…';

  @override
  String get ingredientFormPicturesSection => 'Photos';

  @override
  String get ingredientFormAddPicture => 'Ajouter une photo';

  @override
  String get ingredientDetailPricesTitle => 'Prix';

  @override
  String get ingredientDetailNoPrices =>
      'Aucun prix enregistré pour le moment.';

  @override
  String ingredientDetailCostPerKg(String value) {
    return '$value /kg';
  }

  @override
  String get ingredientPriceAdd => 'Ajouter un prix';

  @override
  String get ingredientPriceEdit => 'Modifier le prix';

  @override
  String get ingredientPriceStoreLabel => 'Magasin';

  @override
  String get ingredientPriceAmountLabel => 'Prix';

  @override
  String get ingredientPriceGramsLabel => 'Taille du paquet';

  @override
  String get ingredientPriceSourceUrlLabel => 'URL source (facultatif)';

  @override
  String get ingredientPriceHistoryTitle => 'Historique des prix';

  @override
  String get ingredientDetailManageStores => 'Gérer les magasins';

  @override
  String get storeManagerTitle => 'Magasins';

  @override
  String get storeManagerEmpty =>
      'Aucun magasin. Ajoutez-en un pour suivre vos prix.';

  @override
  String get storeManagerAddTile => 'Ajouter un magasin';

  @override
  String get storeNameLabel => 'Nom du magasin';

  @override
  String get storeNameRequired => 'Le nom est requis';

  @override
  String get settingsFxAutoRefresh => 'Actualisation automatique des taux';

  @override
  String get settingsFxAutoRefreshSubtitle =>
      'Récupère les taux de change en arrière-plan';

  @override
  String get settingsFxRefreshInterval => 'Intervalle d\'actualisation';

  @override
  String get settingsSyncServer => 'Serveur de synchronisation';

  @override
  String get settingsSyncServerHint =>
      'Indiquez votre serveur de sync pour récupérer exercices, ingrédients et devises. Laissez vide pour désactiver la sync.';

  @override
  String get syncExercisesTooltip => 'Synchroniser les exercices';

  @override
  String get syncIngredientsTooltip => 'Synchroniser les ingrédients';

  @override
  String get syncPushIngredientTooltip => 'Publier dans le catalogue partagé';

  @override
  String get syncServerNotConfigured =>
      'L\'URL du serveur de synchronisation n\'est pas configurée';

  @override
  String get syncAll => 'Tout synchroniser';

  @override
  String get syncSelect => 'Sélectionner…';

  @override
  String get selectServerExercises => 'Sélectionner des exercices du serveur';

  @override
  String get exerciseImportFromServer => 'Importer depuis le serveur…';

  @override
  String get exerciseRemoveFromPhone => 'Retirer du téléphone…';

  @override
  String get exerciseRemoveTitle => 'Retirer du téléphone';

  @override
  String get exerciseRemoveNothing =>
      'Rien à retirer : chaque exercice est utilisé par un entraînement ou un modèle.';

  @override
  String get exerciseRemoveUnused => 'Retirer les exercices inutilisés';

  @override
  String exerciseRemoveUnusedConfirm(int count) {
    return 'Retirer $count exercices que vous n’avez utilisés dans aucun entraînement ni modèle ? Ils restent sur le serveur et peuvent être réimportés.';
  }

  @override
  String get exerciseUsedInTemplate =>
      'Utilisé dans un modèle d’entraînement. Retirez-le d’abord du modèle.';

  @override
  String exerciseRemovedCount(int count) {
    return 'Retirés du téléphone : $count. Ils restent sur le serveur.';
  }

  @override
  String get selectServerIngredients =>
      'Sélectionner des ingrédients du serveur';

  @override
  String get syncNothingNew =>
      'Rien de nouveau sur le serveur — tout est déjà importé';

  @override
  String get ingredientListSearchHint => 'Rechercher des ingrédients';

  @override
  String get refreshList => 'Actualiser la liste';

  @override
  String get syncServerUnreachable =>
      'Serveur injoignable — vérifiez l\'URL/clé ou augmentez le délai dans Réglages';

  @override
  String get pushAllDataTooltip =>
      'Téléverse toutes les données locales vers le serveur (sens unique)';

  @override
  String get exportServerTooltip =>
      'Téléverse une sauvegarde complète de vos données locales vers le serveur';

  @override
  String get importServerTooltip =>
      'Remplace vos données locales par la copie du serveur';

  @override
  String get importFailed => 'Échec de l\'import';

  @override
  String get exportFailed => 'Échec de l\'export';

  @override
  String get settingsPlanner => 'Planificateur';

  @override
  String get settingsPlannerSubtitle => 'Séances, tâches et objectifs';

  @override
  String get settingsNutrition => 'Nutrition';

  @override
  String get settingsNutritionSubtitle => 'Unités et objectifs caloriques';

  @override
  String get settingsBudgetCurrencySubtitle =>
      'Devise de base et taux de change';

  @override
  String get settingsUnits => 'Unités';

  @override
  String get settingsWeightUnitLabel => 'Poids';

  @override
  String get settingsLengthUnitLabel => 'Taille';

  @override
  String get settingsExportDb => 'Exporter la sauvegarde';

  @override
  String get settingsExportDbSubtitle =>
      'Partager une sauvegarde JSON compressée de toutes vos données';

  @override
  String get settingsReplayPrefillLabel =>
      'Au rejeu d\'une séance, préremplir les séries depuis';

  @override
  String get settingsReplayPrefillActuals => 'Les valeurs réelles précédentes';

  @override
  String get settingsReplayPrefillPlanned => 'Les valeurs planifiées';

  @override
  String get workoutSummaryDoAgain => 'Refaire';

  @override
  String get workoutActionReplay => 'Rejouer';

  @override
  String get workoutActionDuplicate => 'Dupliquer';

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
    return '$planned · repos $rest';
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
  String get bodyMetricsTitle => 'Mensurations';

  @override
  String get bodyMetricsAddWeight => 'Ajouter le poids';

  @override
  String get bodyMetricsAddHeight => 'Ajouter la taille';

  @override
  String get bodyMetricsWeightLabel => 'Poids (kg)';

  @override
  String get bodyMetricsHeightLabel => 'Taille (cm)';

  @override
  String get bodyMetricsDialogWeightTitle => 'Nouvelle entrée de poids';

  @override
  String get bodyMetricsDialogHeightTitle => 'Nouvelle entrée de taille';

  @override
  String get bodyMetricsValueRequired => 'Saisissez une valeur';

  @override
  String get bodyMetricsValuePositive => 'La valeur doit être supérieure à 0';

  @override
  String get bodyMetricsEmptyWeight =>
      'Aucune entrée de poids pour l\'instant.';

  @override
  String get bodyMetricsEmptyHeight =>
      'Aucune entrée de taille pour l\'instant.';

  @override
  String bodyMetricsLatestWeight(String value, String unit) {
    return 'Dernier : $value $unit';
  }

  @override
  String bodyMetricsLatestHeight(String value, String unit) {
    return 'Dernière : $value $unit';
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
    return 'Objectif : $goal';
  }

  @override
  String get restTimerTitle => 'Minuteur de repos';

  @override
  String get restTimerCancel => 'Annuler le repos';

  @override
  String restTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get activeWorkoutElapsedLabel => 'Écoulé';

  @override
  String get activeWorkoutRestLabel => 'Repos';

  @override
  String get activeWorkoutResume => 'Reprendre';

  @override
  String get restAlarmTitle => 'Le repos est terminé';

  @override
  String get restAlarmBody => 'Votre temps de repos prévu est écoulé.';

  @override
  String restAlarmBodyWithDuration(String duration) {
    return 'Votre repos planifié de $duration est terminé.';
  }

  @override
  String get workoutSummaryAppBar => 'Résumé';

  @override
  String get workoutSummaryEdit => 'Modifier la séance';

  @override
  String workoutSummarySetLabel(int number) {
    return 'Série $number';
  }

  @override
  String workoutSummarySetRest(String rest) {
    return 'repos $rest';
  }

  @override
  String get workoutSummaryDone => 'Terminé';

  @override
  String get workoutSummaryDurationLabel => 'Durée';

  @override
  String get workoutSummaryEnergyLabel => 'Énergie estimée';

  @override
  String workoutSummaryEnergyValue(int kcal) {
    return '~$kcal kcal';
  }

  @override
  String workoutSummaryEnergyNotCounted(String names) {
    return 'Non comptabilisé : $names';
  }

  @override
  String get workoutSummaryAvgRest => 'Repos moyen';

  @override
  String get workoutSummaryVolume => 'Volume';

  @override
  String get workoutSummaryMaxWeight => 'Poids max';

  @override
  String get workoutSummaryTotalReps => 'Répétitions';

  @override
  String get workoutSummaryTotalDuration => 'Durée totale';

  @override
  String get workoutSummaryTotalDistance => 'Distance totale';

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
    return '$base → $target : $rate';
  }

  @override
  String settingsRateInverse(String base, String rate, String code) {
    return '1 $base = $rate $code';
  }

  @override
  String settingsRateUpdated(String date) {
    return 'Mis à jour le $date';
  }

  @override
  String transactionRateUsed(String rate, String base, String code) {
    return 'converti à $rate $base pour $code';
  }

  @override
  String accountDeleteBlockedBody(int count) {
    return 'Ce compte est utilisé par $count transaction(s) et ne peut pas être supprimé.';
  }

  @override
  String get accountDeleteBlockedTitle => 'Compte utilisé';

  @override
  String accountDeleteConfirmBody(String name) {
    return 'Supprimer le compte \'$name\' supprimera aussi ses transactions et reçus.';
  }

  @override
  String get accountDeleteConfirmTitle => 'Supprimer le compte ?';

  @override
  String get accountFormEditTitle => 'Modifier le compte';

  @override
  String get accountFormNameLabel => 'Nom';

  @override
  String get accountFormNameRequired => 'Saisissez un nom';

  @override
  String get accountFormNewTitle => 'Nouveau compte';

  @override
  String get accountFormOpeningHelper =>
      'Montant déjà présent sur ce compte au début du suivi. Laissez 0 si vous n\'êtes pas sûr.';

  @override
  String get accountFormIntro =>
      'Suivez un portefeuille, un compte bancaire ou une carte.';

  @override
  String get accountFormNoteLabel => 'Account Form Note Label';

  @override
  String get accountFormOpeningLabel => 'Solde initial';

  @override
  String get accountFormTypeLabel => 'Type';

  @override
  String accountOpeningLabel(String value) {
    return 'Solde initial : $value';
  }

  @override
  String get accountReceipts => 'Reçus';

  @override
  String get accountTransactions => 'Transactions';

  @override
  String get accountTypeBank => 'Compte bancaire';

  @override
  String get accountTypeCash => 'Espèces';

  @override
  String get accountTypeCredit => 'Carte de crédit';

  @override
  String get accountTypeInvestment => 'Placement';

  @override
  String get accountTypeOther => 'Autre';

  @override
  String get accountTypeSavings => 'Épargne';

  @override
  String get accountTypeSecurities => 'Titres';

  @override
  String get budgetAccounts => 'Comptes';

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
  String get budgetMonthExpense => 'Dépenses du mois';

  @override
  String get budgetMonthIncome => 'Revenus du mois';

  @override
  String get budgetNoReceipts => 'Aucun reçu pour l\'instant';

  @override
  String get budgetNoTransactions => 'Aucune transaction pour l\'instant';

  @override
  String budgetPendingReceipts(int count) {
    return '$count reçu(s) en attente';
  }

  @override
  String get budgetRecentTransactions => 'Transactions récentes';

  @override
  String get budgetThisMonth => 'Budget This Month';

  @override
  String get budgetViewAll => 'Tout voir';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get receiptAppBar => 'Reçu';

  @override
  String get receiptCreateDraft => 'Créer un brouillon';

  @override
  String get receiptDeleteConfirmBody => 'Supprimer ce reçu ?';

  @override
  String get receiptDeleteConfirmTitle => 'Supprimer le reçu ?';

  @override
  String get receiptEmptyBody =>
      'Aucun reçu pour l\'instant. Photographiez un reçu pour commencer à suivre vos dépenses.';

  @override
  String get receiptListAppBar => 'Reçus';

  @override
  String get receiptNotFound => 'Reçu introuvable';

  @override
  String get receiptNotParsed => 'Pas encore analysé';

  @override
  String get receiptParsed => 'Analysé';

  @override
  String get receiptParsing => 'Analyse du reçu en cours…';

  @override
  String get receiptParsedData => 'Données analysées';

  @override
  String get receiptPickGallery => 'Depuis la galerie';

  @override
  String get receiptReviewDraft => 'Vérifier le brouillon';

  @override
  String receiptStatusLabel(String status) {
    return '$status';
  }

  @override
  String receiptStatusShort(String status) {
    return '$status';
  }

  @override
  String get receiptTakePhoto => 'Prendre une photo';

  @override
  String get receiptUpload => 'Téléverser';

  @override
  String get settingsCurrencyBudget => 'Devise du budget';

  @override
  String get settingsFxRates => 'Taux de change';

  @override
  String get settingsFxRatesEmpty => 'Aucun taux de change configuré';

  @override
  String get settingsFxRefresh => 'Actualiser les taux';

  @override
  String get transactionAmountInvalid => 'Saisissez un montant valide';

  @override
  String get transactionCategoryLabel => 'Catégorie';

  @override
  String transactionConvertedLabel(String amount) {
    return '≈ $amount en devise de base';
  }

  @override
  String get transactionDraft => 'Brouillon';

  @override
  String get transactionDraftHint =>
      'Brouillon issu d\'un reçu scanné — vérifiez les détails avant d\'enregistrer';

  @override
  String get transactionHasReceipt => 'Reçu joint';

  @override
  String get transactionListAppBar => 'Transactions';

  @override
  String get transactionTypeExpense => 'Dépense';

  @override
  String get transactionTypeIncome => 'Revenu';

  @override
  String get transactionTypeTransfer => 'Virement';

  @override
  String get budgetAppBar => 'Budget';

  @override
  String get budgetSubtitle => 'Comptes, transactions et reçus';

  @override
  String get budgetTotalBalance => 'Solde total';

  @override
  String get budgetNetWorth => 'Valeur nette';

  @override
  String get budgetIncomeLabel => 'Revenus';

  @override
  String get budgetExpenseLabel => 'Dépenses';

  @override
  String get budgetEmptyAccounts =>
      'Aucun compte pour le moment. Ils viennent du serveur : récupérez Budget dans Sync.';

  @override
  String get budgetAddAccount => 'Ajouter un compte';

  @override
  String get budgetAddTransaction => 'Ajouter une transaction';

  @override
  String get accountFormTitleNew => 'Nouveau compte';

  @override
  String get accountFormTitleEdit => 'Modifier le compte';

  @override
  String get accountNameLabel => 'Nom';

  @override
  String get accountTypeLabel => 'Type';

  @override
  String get accountCurrencyLabel => 'Devise';

  @override
  String get accountInitialBalanceLabel => 'Solde initial';

  @override
  String get accountSave => 'Enregistrer';

  @override
  String get accountDetailTitle => 'Compte';

  @override
  String get accountDelete => 'Supprimer le compte';

  @override
  String get accountTransactionsTitle => 'Transactions';

  @override
  String get accountBalanceLabel => 'Solde';

  @override
  String get accountEdit => 'Modifier';

  @override
  String get transactionFormNewExpenseTitle => 'Nouvelle dépense';

  @override
  String get transactionFormNewIncomeTitle => 'Nouveau revenu';

  @override
  String get transactionFormTransferTitle => 'Transfert';

  @override
  String get transactionFormEditTitle => 'Modifier la transaction';

  @override
  String get transactionTypeLabel => 'Type';

  @override
  String get transactionAmountLabel => 'Montant';

  @override
  String get transactionCurrencyLabel => 'Devise';

  @override
  String get transactionDateLabel => 'Date';

  @override
  String get transactionNoteLabel => 'Note';

  @override
  String get transactionAccountLabel => 'Compte';

  @override
  String get transactionToAccountLabel => 'Vers le compte';

  @override
  String get transactionReceiptLabel => 'Reçu';

  @override
  String get transactionSave => 'Enregistrer';

  @override
  String get transactionDelete => 'Supprimer';

  @override
  String get transactionDraftBadge => 'Brouillon';

  @override
  String get transactionConfirmDraft => 'Confirmer';

  @override
  String get transactionTransferSameAccount =>
      'Le transfert nécessite deux comptes différents.';

  @override
  String get transactionAccountRequired => 'Un compte est requis.';

  @override
  String get transactionTransferAccountsRequired =>
      'Les deux comptes sont requis pour un transfert.';

  @override
  String get transactionAmountPositive =>
      'Le montant doit être supérieur à zéro.';

  @override
  String get receiptListTitle => 'Reçus';

  @override
  String get receiptCapture => 'Capturer un reçu';

  @override
  String get receiptCaptureStandalone => 'Reçu indépendant';

  @override
  String get receiptUploadError => 'Échec de l\'envoi du reçu';

  @override
  String get receiptViewTitle => 'Reçu';

  @override
  String get receiptStatusLocal => 'Local';

  @override
  String get receiptStatusUploading => 'Envoi';

  @override
  String get receiptStatusUploaded => 'Envoyé';

  @override
  String get receiptStatusError => 'Erreur';

  @override
  String get receiptAttach => 'Joindre à la transaction';

  @override
  String get receiptChooseSource => 'Choisir la source';

  @override
  String get receiptFromCamera => 'Appareil photo';

  @override
  String get receiptFromGallery => 'Galerie';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get settingsBaseCurrency => 'Devise de base';

  @override
  String get settingsCategoryFx => 'Taux de change';

  @override
  String get settingsRefreshRates => 'Actualiser les taux';

  @override
  String get settingsEditRate => 'Modifier le taux';

  @override
  String settingsRateBase(Object base) {
    return 'Par 1 $base';
  }

  @override
  String get settingsRateInvalid => 'Saisissez un taux positif.';

  @override
  String get tabBudget => 'Budget';

  @override
  String get plannerViewDay => 'Vue jour';

  @override
  String get plannerViewWeek => 'Vue semaine';

  @override
  String get plannerViewMonth => 'Vue mois';

  @override
  String get plannerGoToday => 'Aller à aujourd\'hui';

  @override
  String get goalLinkTask => 'Lier une tâche';

  @override
  String get goalUnlinkTask => 'Délier la tâche';

  @override
  String get goalSearchTasksHint => 'Rechercher des tâches…';

  @override
  String get linkGoal => 'Lier un objectif';

  @override
  String get unlinkGoal => 'Délier l\'objectif';

  @override
  String get linkNote => 'Lier une note';

  @override
  String get unlinkNote => 'Délier la note';

  @override
  String get plannerViewGoals => 'Vue des objectifs';

  @override
  String get plannerModeTimeline => 'Chronologie';

  @override
  String get plannerModeInitiatives => 'Initiatives';

  @override
  String get prioritiesTitle => 'Tags';

  @override
  String get prioritiesManage => 'Gérer les tags';

  @override
  String get prioritiesAdd => 'Ajouter un tag';

  @override
  String get prioritiesRename => 'Renommer le tag';

  @override
  String get prioritiesNameLabel => 'Nom';

  @override
  String get prioritiesNameRequired => 'Saisissez un nom';

  @override
  String get prioritiesAlreadyExists => 'Un tag portant ce nom existe déjà.';

  @override
  String get prioritiesColor => 'Couleur';

  @override
  String get prioritiesDeleteConfirmTitle => 'Supprimer le tag ?';

  @override
  String prioritiesDeleteConfirmBody(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      zero: 'aucun élément',
    );
    return '« $name » sera retirée de $_temp0.';
  }

  @override
  String get prioritiesEmpty =>
      'Aucun tag pour l\'instant. Créez-en un pour organiser vos objectifs, tâches et notes.';

  @override
  String prioritiesUsageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: 'inutilisée',
    );
    return '$_temp0';
  }

  @override
  String get tagsFilterAll => 'Tous';

  @override
  String get initiativesEmptyAllTitle => 'Aucun objectif pour l\'instant';

  @override
  String get initiativesEmptyAll => 'Créez un objectif à atteindre.';

  @override
  String get initiativesEmptyFilterTitle => 'Aucune initiative correspondante';

  @override
  String get initiativesEmptyFilter =>
      'Aucun objectif ne porte les tags sélectionnés.';

  @override
  String get goalsNew => 'Nouvel objectif';

  @override
  String get goalsEdit => 'Modifier l\'objectif';

  @override
  String get goalsMissing => 'Objectif introuvable.';

  @override
  String get goalsFormTitleLabel => 'Objectif';

  @override
  String get goalsFormTitleHint => 'ex. Courir un 10 km';

  @override
  String get goalsFormTitleRequired => 'Saisissez un objectif';

  @override
  String get goalsFormDescriptionLabel => 'Description';

  @override
  String get goalsFormStartLabel => 'Date de début';

  @override
  String get goalsFormEndLabel => 'Date cible (facultatif)';

  @override
  String get goalsNoEndDate => 'Sans échéance';

  @override
  String get goalsFormStatusLabel => 'Statut';

  @override
  String get goalsStatusPlanned => 'Planifié';

  @override
  String get goalsStatusActive => 'Actif';

  @override
  String get goalsStatusDone => 'Terminé';

  @override
  String get goalsStatusAborted => 'Abandonné';

  @override
  String get goalsTargetTypeLabel => 'Cible';

  @override
  String get goalsTargetTypeNone => 'Aucune';

  @override
  String get goalsTargetTypeNumeric => 'Numérique';

  @override
  String get goalsTargetTypeBoolean => 'À atteindre';

  @override
  String get goalsTargetValueLabel => 'Valeur cible';

  @override
  String get goalsTargetValueInvalid => 'Saisissez un nombre';

  @override
  String get goalsUnitLabel => 'Unité';

  @override
  String get goalsBaselineLabel => 'Valeur de départ';

  @override
  String get goalsReminderLabel => 'Rappel quotidien de l\'objectif';

  @override
  String get goalsReminderSubtitle =>
      'Une notification garde cet objectif en vue.';

  @override
  String get goalsReminderTimeLabel => 'Heure du rappel';

  @override
  String get goalsRelatedTasks => 'Tâches liées';

  @override
  String get goalsNoLinkedTasks => 'Aucune tâche liée pour l\'instant.';

  @override
  String get goalsDeleteConfirmTitle => 'Supprimer l\'objectif ?';

  @override
  String get goalsDeleteConfirmBody =>
      'L\'objectif et son journal de progression seront définitivement supprimés.';

  @override
  String get goalsMarkActive => 'Activer';

  @override
  String get goalsMarkDone => 'Marquer terminé';

  @override
  String get goalsAbort => 'Abandonner';

  @override
  String get goalsReopen => 'Rouvrir';

  @override
  String get goalsProgressSection => 'Progression';

  @override
  String get goalsRecordProgress => 'Enregistrer la progression';

  @override
  String get goalsCurrentValueLabel => 'Actuel';

  @override
  String get goalsTargetLabel => 'Cible';

  @override
  String get goalsAchievedQuestion => 'Atteint ? (1 = oui)';

  @override
  String get goalsAchieved => 'Atteint';

  @override
  String get goalsNotAchieved => 'Pas encore';

  @override
  String get goalsProgressNoteHint => 'Note (facultatif)';

  @override
  String get goalsProgressDateLabel => 'Enregistré le';

  @override
  String get goalsLogTitle => 'Journal';

  @override
  String get goalsNoProgressYet => 'Rien d\'enregistré pour l\'instant.';

  @override
  String get goalsEmptyAllTitle => 'Aucun objectif';

  @override
  String get goalsEmptyAll =>
      'Définissez un résultat à long terme et liez-le à vos priorités.';

  @override
  String get goalsEmptyFilterTitle => 'Aucun objectif ici';

  @override
  String get goalsEmptyFilter =>
      'Aucun objectif ne porte les priorités sélectionnées.';

  @override
  String get cascadeDeleteBody => 'This will be permanently deleted.';

  @override
  String cascadeDeleteBodyWithTasks(int count) {
    return 'Also delete $count linked task(s)? You can keep them or delete them together.';
  }

  @override
  String get cascadeDeleteOnly => 'Delete only';

  @override
  String get cascadeDeleteWithTasks => 'Delete with tasks';

  @override
  String get settingsCascadeDeleteLabel => 'Delete behavior';

  @override
  String get settingsCascadeDeleteHelp =>
      'Lors de la suppression d\'un objectif, choisissez si ses tâches liées doivent aussi être supprimées.';

  @override
  String get settingsCascadeAsk => 'Ask each time';

  @override
  String get settingsCascadeAlways => 'Always delete tasks';

  @override
  String get settingsCascadeNever => 'Never delete tasks';

  @override
  String get templatesDuplicate => 'Duplicate';

  @override
  String get cascadeDeleteTitleWithTasks => 'Delete linked tasks?';

  @override
  String get cascadeDeleteKeepTasks => 'Keep tasks';

  @override
  String goalDeleted(String name) {
    return 'Goal \"$name\" deleted';
  }

  @override
  String get receiptsNonePending => 'Rien à envoyer';

  @override
  String get receiptListSentNote =>
      'Les reçus envoyés sont supprimés du téléphone et restent sur le serveur.';

  @override
  String get receiptSendAll => 'Tout envoyer';

  @override
  String get receiptSendSelected => 'Envoyer la sélection';

  @override
  String receiptSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String receiptSendingProgress(int done, int total) {
    return 'Envoi de $done sur $total';
  }

  @override
  String receiptSentCount(int count) {
    return '$count envoyé(s)';
  }

  @override
  String receiptFailedCount(int count) {
    return '$count échoué(s)';
  }

  @override
  String receiptNoPictureCount(int count) {
    return '$count sans image';
  }

  @override
  String receiptSaveFailedCount(int count) {
    return '$count n\'a pas pu être ajouté';
  }

  @override
  String get receiptsNoServer =>
      'Aucun serveur de synchronisation configuré — les reçus restent sur ce téléphone.';

  @override
  String get receiptOpenSync => 'Ouvrir les réglages de synchronisation';

  @override
  String get receiptStatusParsing => 'Lecture…';

  @override
  String get syncHubTitle => 'Synchronisation et sauvegarde';

  @override
  String get syncGlobalPool => 'Pool global';

  @override
  String get syncGlobalPoolHint =>
      'Récupérer les exercices, ingrédients et devises partagés';

  @override
  String get syncPersonalPool => 'Pool personnel';

  @override
  String get syncPersonalPoolHint =>
      'Envoyer/récupérer vos tâches, notes, objectifs, séances, modèles, repas, corps, budget';

  @override
  String get syncLocalBackup => 'Sauvegarde locale';

  @override
  String get syncLocalBackupHint =>
      'Exporter vers un fichier ou restaurer depuis un fichier';

  @override
  String syncErrorUnreachable(String url) {
    return 'Impossible de joindre le serveur à $url. Vérifiez que le serveur de synchronisation tourne sur l\'ordinateur et que le téléphone est sur le même réseau Wi-Fi (ou configuré via adb reverse). Utilisez « Tester /health » ci-dessus pour réessayer.';
  }

  @override
  String get syncErrorServerTooOld =>
      'Ce serveur est une ancienne version qui ne peut pas encore recevoir ces données. Mettez à jour le serveur de synchronisation sur l\'ordinateur, puis renvoyez.';

  @override
  String get syncErrorUnknownOperation =>
      'Le serveur ne reconnaît pas cette opération de synchronisation — sa version est peut-être trop ancienne. Mettez à jour le serveur sur l\'ordinateur, puis réessayez.';

  @override
  String get syncErrorKeyRejected =>
      'Le serveur a refusé la clé API. Vérifiez la clé de ce serveur (supprimez-le, puis rajoutez-le ou rescannez le QR code).';

  @override
  String get syncErrorTooLarge =>
      'Ces données sont trop volumineuses pour être acceptées en une fois. Envoyez moins de catégories à la fois (décochez des cases ci-dessus).';

  @override
  String get syncErrorServerInternal =>
      'Le serveur a rencontré un problème interne en recevant ces données. Son activité récente est journalisée sur l\'ordinateur — consultez la console du serveur.';

  @override
  String syncConnected(String url) {
    return '✓ Connecté ($url)';
  }

  @override
  String syncConnectionFailed(String reason) {
    return 'Échec de la connexion — $reason';
  }

  @override
  String get syncAddServer => 'Ajouter un serveur';

  @override
  String get syncServerUrl => 'URL du serveur';

  @override
  String get syncApiKey => 'Clé API';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get syncInvalidUrl => 'URL invalide';

  @override
  String get syncApiKeyRequired => 'Clé API requise';

  @override
  String get syncServerExists => 'Ce serveur existe déjà';

  @override
  String get syncServers => 'Serveurs';

  @override
  String get syncServersHint =>
      'Ajoutez plusieurs paires URL + clé API. Sélectionnez le serveur actif pour synchroniser. Gardez adb reverse + http://127.0.0.1:3030 pour le partage de connexion.';

  @override
  String get syncNoServers =>
      'Aucun serveur — ajoutez-en un via Scanner le QR ou Ajouter';

  @override
  String get syncRemoveServerTitle => 'Supprimer le serveur ?';

  @override
  String syncRemoveServerBody(String label) {
    return 'Supprimer $label ?';
  }

  @override
  String get syncScanQr => 'Scanner le QR';

  @override
  String get syncNoActiveServer => 'Aucun serveur actif';

  @override
  String get syncTestHealth => 'Tester /health';

  @override
  String get syncNever => 'jamais';

  @override
  String syncMinutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String syncHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String syncDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String syncLastSync(String when) {
    return 'Dernière synchro : $when';
  }

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get syncSelectExercises => 'Choisir des exercices…';

  @override
  String get syncSelectIngredients => 'Choisir des ingrédients…';

  @override
  String get syncNoExercisesOnServer => 'Aucun exercice sur le serveur';

  @override
  String get syncNoIngredientsOnServer => 'Aucun ingrédient sur le serveur';

  @override
  String get syncSelectServerExercises => 'Choisir des exercices du serveur';

  @override
  String get syncSearchServerExercises => 'Rechercher les exercices du serveur';

  @override
  String get syncSelectServerIngredients =>
      'Choisir des ingrédients du serveur';

  @override
  String get syncSearchServerIngredients =>
      'Rechercher les ingrédients du serveur';

  @override
  String get syncRefreshList => 'Actualiser la liste';

  @override
  String syncCouldNotPush(String entity, String reason) {
    return 'Impossible d\'envoyer $entity — $reason';
  }

  @override
  String syncCouldNotPull(String entity, String reason) {
    return 'Impossible de récupérer $entity — $reason';
  }

  @override
  String get syncUnknownError => 'erreur inconnue';

  @override
  String syncPulledWithErrors(String entities) {
    return 'Récupéré avec des erreurs : $entities';
  }

  @override
  String get syncRelatedExercises => 'Exercices (liés)';

  @override
  String syncPushEntity(String entity) {
    return 'Envoyer $entity';
  }

  @override
  String syncPullEntity(String entity) {
    return 'Récupérer $entity';
  }

  @override
  String get syncExerciseUpdates =>
      'Mettre à jour les exercices de ce téléphone';

  @override
  String get syncPushAll => 'Tout envoyer';

  @override
  String get syncPullAll => 'Tout récupérer';

  @override
  String get syncEntityTags => 'Étiquettes';

  @override
  String get syncEntityExercises => 'Exercices';

  @override
  String get syncEntityTasks => 'Tâches';

  @override
  String get syncEntityNotes => 'Notes';

  @override
  String get syncEntityGoals => 'Objectifs';

  @override
  String get syncEntityWorkouts => 'Séances';

  @override
  String get syncEntityTemplates => 'Modèles';

  @override
  String get syncEntityStores => 'Magasins';

  @override
  String get syncEntityIngredients => 'Ingrédients';

  @override
  String get syncEntityFoods => 'Aliments';

  @override
  String get syncEntityMeals => 'Repas';

  @override
  String get syncEntityBody => 'Corps';

  @override
  String get syncEntityBudget => 'Budget';

  @override
  String get syncEntityTransactions => 'Transactions';

  @override
  String get syncEntityReceipts => 'Tickets';

  @override
  String get syncBackupFormatHint =>
      'JSON → .json.gz (compressé, filtré par la sélection)';

  @override
  String syncBackupGroupsSelected(int selected, int total) {
    return '$selected/$total groupes — s\'applique à l\'export et à l\'import';
  }

  @override
  String get syncExport => 'Exporter';

  @override
  String get syncImport => 'Importer';

  @override
  String get syncSelectOneGroup => 'Sélectionnez au moins un groupe';

  @override
  String syncExportJson(int count) {
    return 'Exporter en JSON ($count)';
  }

  @override
  String get syncImportJson => 'Importer un JSON';

  @override
  String get syncServerCopy => 'Copie sur le serveur';

  @override
  String get syncServerCopyHint =>
      'Envoyer une sauvegarde JSON compressée, ou restaurer celle stockée sur l\'ordinateur';

  @override
  String get syncBackUpToServer => 'Sauvegarder sur le serveur';

  @override
  String get syncRestoreFromServer => 'Restaurer depuis le serveur';

  @override
  String get syncReplaceLocalTitle => 'Remplacer les données locales ?';

  @override
  String get syncReplaceFromServerBody =>
      'L\'import supprimera les lignes existantes de chaque groupe sauvegardé et restaurera la copie stockée sur le serveur.';

  @override
  String syncReplaceFromFileBody(String groups) {
    return 'L\'import supprimera les lignes existantes de ces groupes et restaurera la sauvegarde : $groups.';
  }

  @override
  String get syncEntityCurrencies => 'Devises';

  @override
  String get syncNotConfiguredOpenHub =>
      'Serveur de synchronisation non configuré — ouvrez Synchronisation et sauvegarde pour définir l\'URL';

  @override
  String syncTimeoutWithSeconds(int seconds) {
    return 'Serveur injoignable — vérifiez l\'URL/la clé ou augmentez le délai dans Réglages → Avancé ($seconds s)';
  }

  @override
  String get commonOpen => 'Ouvrir';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get syncNowHint =>
      'Envoie vos modifications, puis récupère celles du serveur';

  @override
  String syncStep(String entity) {
    return 'Synchronisation : $entity…';
  }

  @override
  String get syncYourData => 'Vos données';

  @override
  String syncShowAll(int count) {
    return 'Tout afficher ($count)';
  }

  @override
  String get syncShowLess => 'Afficher moins';

  @override
  String get syncLibraryTitle => 'Bibliothèque du serveur';

  @override
  String get syncLibraryHint =>
      'Rien ne se télécharge tout seul. Choisissez ce que vous voulez sur ce téléphone.';

  @override
  String syncOnPhoneCount(int count) {
    return '$count sur ce téléphone';
  }

  @override
  String get syncBrowse => 'Parcourir';

  @override
  String get syncBackups => 'Sauvegardes';

  @override
  String get syncBackupsSubtitle =>
      'Export de fichier · copie serveur · restauration';

  @override
  String get syncServerSheetTitle => 'Serveur';

  @override
  String syncStatusConnected(String server) {
    return '$server · connecté';
  }

  @override
  String syncStatusOffline(String server) {
    return '$server · injoignable';
  }

  @override
  String syncStatusChecking(String server) {
    return '$server · vérification…';
  }

  @override
  String get syncNoServerYet => 'Aucun serveur';

  @override
  String get syncRescanQr => 'Rescanner le QR code';

  @override
  String get syncRescanQrHint =>
      'À utiliser si l’adresse ou la clé de l’ordinateur a changé. Remplace l’URL et la clé de ce serveur.';

  @override
  String get syncRescanQrTooltip => 'Rescanner le QR code du serveur';

  @override
  String get syncTestConnection => 'Tester la connexion';

  @override
  String get syncAddServerByHand => 'Ajouter un serveur manuellement';

  @override
  String get syncServerUpdated => 'Serveur mis à jour';

  @override
  String get syncSendToServer => 'Envoyer au serveur';

  @override
  String get syncGetFromServer => 'Récupérer du serveur';

  @override
  String get syncRescan => 'Rescanner';

  @override
  String syncCantReach(String server) {
    return 'Impossible de joindre $server';
  }

  @override
  String get syncCantReachHint =>
      'Vos données restent sur ce téléphone. Rescannez si l’adresse de l’ordinateur a changé.';

  @override
  String get syncBackup => 'Sauvegarder';

  @override
  String get commonError => 'Erreur';

  @override
  String get dashboardStableTrend => 'Tendance stable';

  @override
  String get dashboardTrendingDown => '→ tendance à la baisse';

  @override
  String get dashboardTrendingUp => '→ tendance à la hausse';

  @override
  String dashboardDelta7d(String delta) {
    return '$delta (7 j)';
  }

  @override
  String dashboardDelta30d(String delta) {
    return '$delta (30 j)';
  }

  @override
  String get dashboardToday => 'Aujourd\'hui';

  @override
  String get budgetRecent => 'Récentes';

  @override
  String get settingsSync => 'Synchronisation';

  @override
  String get settingsSyncSubtitle =>
      'Serveurs et sauvegarde — ouvrir Synchronisation et sauvegarde';

  @override
  String get selectSheetTitle => 'Sélectionner';

  @override
  String selectSheetCount(int count) {
    return '$count éléments';
  }

  @override
  String get selectSheetSelectAll => 'Tout sélectionner';

  @override
  String selectSheetSyncSelected(int count) {
    return 'Synchroniser la sélection ($count)';
  }

  @override
  String get wizardSkip => 'Passer';

  @override
  String get wizardDone => 'Terminé';

  @override
  String get ingredientOffApply => 'Appliquer au formulaire';

  @override
  String get ingredientOffImport => 'Enregistrer sur le serveur et appliquer';

  @override
  String get ingredientOffShare => 'Partager le lien OpenFoodFacts';

  @override
  String get workoutStartedNoNotification =>
      'Séance démarrée, mais la notification n\'a pas pu s\'afficher. Autorisez les notifications et réglez la batterie sur Non restreinte.';

  @override
  String syncQrInvalid(String payload) {
    return 'QR invalide — attendu $payload';
  }

  @override
  String syncQrHint(String payload) {
    return 'Pointez l\'appareil photo vers un QR $payload';
  }

  @override
  String get dashboardNutrition => 'Nutrition';

  @override
  String get dashboardTasks => 'Tâches';

  @override
  String get dashboardTraining => 'Entraînement';

  @override
  String get dashboardWeight => 'Poids';

  @override
  String get dashboardMoney => 'Argent';

  @override
  String dashboardKcalLeft(int count) {
    return '$count restantes';
  }

  @override
  String dashboardKcalOver(int count) {
    return '$count en trop';
  }

  @override
  String get dashboardNoMealsToday => 'Rien d’enregistré aujourd’hui.';

  @override
  String get dashboardLogMeal => 'Ajouter un repas';

  @override
  String dashboardTasksDone(int done, int total) {
    return '$done sur $total faites';
  }

  @override
  String dashboardTasksMore(int count) {
    return '+$count de plus';
  }

  @override
  String get dashboardNoTasksToday => 'Rien de prévu aujourd’hui.';

  @override
  String get dashboardThisWeek => 'Cette semaine';

  @override
  String dashboardStartedAt(String time) {
    return 'Commencé à $time';
  }

  @override
  String get dashboardContinue => 'Continuer';

  @override
  String dashboardGoalsActive(int count) {
    return '$count actifs';
  }

  @override
  String get dashboardGoalsEmptyHint =>
      'Aucun objectif. Suivez une charge, une épargne ou une distance.';

  @override
  String get dashboardSetGoal => 'Créer un objectif';

  @override
  String get dashboardNoAccounts =>
      'Aucun compte. Ils arrivent du serveur à la synchronisation.';

  @override
  String get dashboardSpent => 'dépensé';

  @override
  String dashboardIncome(String amount) {
    return 'Revenus $amount';
  }

  @override
  String syncSending(String entity) {
    return 'Envoi : $entity…';
  }

  @override
  String syncFetching(String entity) {
    return 'Réception : $entity…';
  }

  @override
  String get syncOpen => 'Ouvrir la synchro';

  @override
  String get settingsDashboard => 'Tableau de bord';

  @override
  String get settingsDashboardSubtitle => 'Cartes et leur ordre';

  @override
  String get settingsDashboardHint =>
      'Glissez pour réordonner. Les cartes désactivées sont masquées.';

  @override
  String get settingsResetOrder => 'Réinitialiser';

  @override
  String get settingsSearch => 'Rechercher un réglage';

  @override
  String settingsNoResults(String query) {
    return 'Aucun réglage ne correspond à « $query »';
  }

  @override
  String get settingsMore => 'Plus';

  @override
  String get settingsPalettes => 'Palettes';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get trainingTitle => 'Entraînement';

  @override
  String get trainingRecent => 'Récents';

  @override
  String get trainingAll => 'Tout';

  @override
  String get trainingStart => 'Démarrer';

  @override
  String get trainingStartAgain => 'Recommencer';

  @override
  String get trainingNew => 'Nouveau';

  @override
  String get trainingNewWorkout => 'Nouvel entraînement';

  @override
  String get trainingNoWorkouts =>
      'Vos entraînements apparaîtront ici. Commencez-en un avec +.';

  @override
  String get trainingNoTemplates =>
      'Enregistrez un entraînement comme modèle depuis son menu ⋮.';

  @override
  String trainingLastDone(String day, int count) {
    return 'dernier $day · ×$count';
  }

  @override
  String trainingLast(String day) {
    return 'dernier $day';
  }

  @override
  String get trainingNeverDone => 'pas encore fait';

  @override
  String trainingTemplateSize(int exercises, int sets) {
    return '$exercises ex · $sets séries';
  }

  @override
  String trainingRunningFor(int minutes) {
    return '$minutes min jusqu’ici';
  }

  @override
  String get trainingWorkouts => 'Entraînements';

  @override
  String get trainingSearchWorkouts => 'Rechercher';

  @override
  String get trainingAllTime => 'Tout';

  @override
  String get trainingRange => 'Période';

  @override
  String trainingLastDays(int count) {
    return '$count derniers jours';
  }

  @override
  String trainingLastMonths(int count) {
    return '$count derniers mois';
  }

  @override
  String get trainingThisYear => 'Cette année';

  @override
  String get trainingPickDates => 'Choisir les dates';

  @override
  String get trainingNoMatchTitle => 'Aucun entraînement';

  @override
  String get trainingNoMatchBody =>
      'Essayez un autre mois ou une autre période.';

  @override
  String get trainingCascadeExercises => 'Exercices';

  @override
  String get trainingCascadeSets => 'Séries prévues';

  @override
  String get trainingSearchTemplates => 'Rechercher un modèle';

  @override
  String workoutDetailPrLine(int count, String detail) {
    return '$count record · $detail';
  }

  @override
  String workoutDetailVsLast(String change) {
    return '$change vs la dernière fois';
  }

  @override
  String get workoutDetailTime => 'Durée';

  @override
  String get workoutDetailSets => 'Séries';

  @override
  String get workoutDetailAvgRest => 'Repos moyen';

  @override
  String get workoutDetailBurned => 'Brûlées';

  @override
  String get workoutDetailSaveTemplate => 'Enregistrer comme modèle';

  @override
  String get workoutDetailOther => 'Autres';

  @override
  String get workoutDetailDelete => 'Supprimer l’entraînement';

  @override
  String workoutDetailDeleteConsequence(int count) {
    return 'Supprime aussi $count séries enregistrées';
  }

  @override
  String workoutDetailFromTemplate(String name) {
    return 'Du modèle $name';
  }

  @override
  String workoutDetailSetsDone(int count) {
    return '$count séries';
  }

  @override
  String workoutDetailAvgRestShort(String rest) {
    return 'repos moyen $rest';
  }

  @override
  String get workoutDetailNotDone => 'Non faite';

  @override
  String get trainingCascadeSetsDone => 'Séries enregistrées';

  @override
  String exerciseFilterShow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voir $count exercices',
      one: 'Voir 1 exercice',
    );
    return '$_temp0';
  }

  @override
  String get exerciseDetailChartWeight => 'Poids';

  @override
  String get exerciseDetailChartReps => 'Reps';

  @override
  String get exerciseDetailChartVolume => 'Volume';

  @override
  String get exerciseDetailChartDuration => 'Durée';

  @override
  String get exerciseDetailSessions => 'Séances';

  @override
  String get exerciseDetailBest => 'Record';

  @override
  String get exerciseDetailLast => 'Dernière';

  @override
  String get exerciseDetailSessionCount => 'Séances';

  @override
  String exerciseDetailSince(String date) {
    return 'depuis $date';
  }

  @override
  String get exerciseDetailMuscles => 'Muscles';

  @override
  String get exerciseDetailDelete => 'Supprimer l’exercice';

  @override
  String get macroProtein => 'Protéines';

  @override
  String get macroCarbs => 'Glucides';

  @override
  String get macroFat => 'Lipides';

  @override
  String get macroFiber => 'Fibres';

  @override
  String get macroSodium => 'Sodium';

  @override
  String get macroSugar => 'Sucres';

  @override
  String foodHistoryFoods(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aliments',
      one: '1 aliment',
    );
    return '$_temp0';
  }

  @override
  String get foodHistoryEditMeal => 'Modifier le repas';

  @override
  String get foodHistoryLogAgain => 'Enregistrer à nouveau';

  @override
  String foodHistoryLoggedAgain(int kcal) {
    return 'Enregistré à nouveau · $kcal kcal';
  }

  @override
  String get foodHistorySearch => 'Rechercher un aliment';

  @override
  String get foodHistoryNoMatchTitle => 'Aucun repas';

  @override
  String get foodHistoryNoMatchBody =>
      'Essayez un autre mois, une autre période ou recherche.';

  @override
  String mealEditBarcodeUnknown(String code) {
    return 'Aucun ingrédient n’a le code $code';
  }

  @override
  String get mealEditItemName => 'Repas';

  @override
  String get mealEditDelete => 'Supprimer le repas';

  @override
  String mealEditDay(String eaten) {
    return 'jour $eaten kcal';
  }

  @override
  String mealEditDayOf(String eaten, String target) {
    return 'jour $eaten / $target';
  }

  @override
  String get mealEditSearch => 'Ajouter un aliment';

  @override
  String get mealEditScan => 'Scanner le code-barres';

  @override
  String get mealEditNoMatch => 'Aucun aliment ne correspond';

  @override
  String get mealEditRecent => 'Récents';

  @override
  String get mealEditRecipe => 'Recette';

  @override
  String mealEditLast(String grams) {
    return 'dernier $grams g';
  }

  @override
  String mealEditPer100(int kcal) {
    return '$kcal kcal/100 g';
  }

  @override
  String get recipeSearch => 'Rechercher une recette';

  @override
  String get recipeSortNewest => 'Récentes';

  @override
  String get recipeSortName => 'Nom';

  @override
  String get recipeSortKcal => 'kcal';

  @override
  String recipeCooked(String grams) {
    return '$grams g cuit';
  }

  @override
  String recipeEaten(String grams) {
    return '$grams g mangés';
  }

  @override
  String recipeLeft(String grams) {
    return 'reste $grams g';
  }

  @override
  String recipeNoneEaten(String grams) {
    return '$grams g · rien de mangé';
  }

  @override
  String get recipeAllEaten => 'Tout mangé';

  @override
  String get recipeEdit => 'Modifier la recette';

  @override
  String get recipeMissingIngredient => 'Ingrédient manquant';

  @override
  String get recipeColIngredient => 'Ingrédient';

  @override
  String get recipeTypeIngredient => 'Tapez un ingrédient…';

  @override
  String get recipeRaw => 'Cru';

  @override
  String get recipePer100 => '/100 g';

  @override
  String recipeYield(int percent) {
    return 'rendement $percent%';
  }

  @override
  String get recipeDelete => 'Supprimer la recette';

  @override
  String get recipeDeleteConsequence =>
      'Les repas déjà enregistrés la conservent';

  @override
  String get recipeCookedWeight => 'Poids cuit';

  @override
  String ingredientSearchCount(int count) {
    return 'Rechercher $count ingrédients';
  }

  @override
  String get ingredientTabNutrition => 'Nutrition';

  @override
  String get ingredientPer100 => 'pour 100 g';

  @override
  String get ingredientCalories => 'Calories';

  @override
  String get ingredientOfWhichSugar => 'dont sucres';

  @override
  String get ingredientDelete => 'Supprimer l’ingrédient';

  @override
  String get ingredientDeleteConsequence =>
      'Les recettes et repas passés le conservent';

  @override
  String moneyTransferTo(String account) {
    return 'Virement vers $account';
  }

  @override
  String moneyTransferFrom(String account) {
    return 'Virement de $account';
  }

  @override
  String moneyOriginalAt(
    String amount,
    String rate,
    String base,
    String currency,
  ) {
    return '$amount à 1 $currency = $rate $base';
  }

  @override
  String get moneyFieldAccounts => 'Comptes';

  @override
  String get moneyFieldAccount => 'Compte';

  @override
  String get moneyFieldCategory => 'Catégorie';

  @override
  String get moneyFieldDate => 'Date';

  @override
  String get moneyFieldNote => 'Note';

  @override
  String moneyOpenStatement(String account) {
    return 'Ouvrir $account';
  }

  @override
  String moneyThisMonth(String amount) {
    return '$amount ce mois-ci';
  }

  @override
  String get moneyGroupEveryday => 'Courant';

  @override
  String get moneyGroupSavings => 'Épargne et placements';

  @override
  String get moneyGroupOther => 'Autres';

  @override
  String get moneyRecent => 'Récentes';

  @override
  String get moneySearch => 'Rechercher notes et catégories';

  @override
  String get moneyNoMatchTitle => 'Aucune transaction';

  @override
  String get moneyNoMatchBody => 'Essayez d’autres filtres.';

  @override
  String get moneyKindIn => 'Entrées';

  @override
  String get moneyKindOut => 'Sorties';

  @override
  String get moneyKindTransfers => 'Virements';

  @override
  String get moneyFilters => 'Filtres';

  @override
  String moneyFiltersCount(int count) {
    return 'Filtres · $count';
  }

  @override
  String get moneyClearFilters => 'Effacer';

  @override
  String get moneyWhen => 'Quand';

  @override
  String get moneyType => 'Type';

  @override
  String moneyShowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count transactions',
      one: 'Afficher 1 transaction',
      zero: 'Aucune transaction',
    );
    return '$_temp0';
  }

  @override
  String moneyIn(String amount) {
    return 'Entrées $amount';
  }

  @override
  String moneyOut(String amount) {
    return 'Sorties $amount';
  }

  @override
  String get plannerViewsTooltip => 'Jour, semaine ou mois';

  @override
  String get plannerTabTasks => 'Tâches';

  @override
  String get plannerTabGoals => 'Objectifs';

  @override
  String plannerDoneOf(int done, int total) {
    return '$done sur $total faites';
  }

  @override
  String get quickAddEndTime => 'Heure de fin (facultatif)';

  @override
  String get quickAddRepeatNone => 'Ne se répète pas';

  @override
  String get quickAddRepeatDaily => 'Tous les jours';

  @override
  String get quickAddRepeatWeekly => 'Chaque semaine';

  @override
  String get quickAddRepeatMonthly => 'Chaque mois';

  @override
  String get quickAddRepeat => 'Répéter';

  @override
  String get quickAddNoGoal => 'Aucun objectif';

  @override
  String get quickAddGoal => 'Objectif';

  @override
  String get quickAddTime => 'Heure';

  @override
  String get quickAddHint => 'Nouvelle tâche';

  @override
  String quickAddAnother(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajoutées · tâche suivante',
      one: 'Ajoutée · tâche suivante',
    );
    return '$_temp0';
  }

  @override
  String get quickAddMore => 'Plus d’options';

  @override
  String get quickAddAdd => 'Ajouter';

  @override
  String get goalSourceManual => 'Manuel';

  @override
  String goalLast(String when) {
    return 'dernier $when';
  }

  @override
  String goalUpdated(String when) {
    return 'mis à jour $when';
  }

  @override
  String get goalToday => 'aujourd’hui';

  @override
  String get goalYesterday => 'hier';

  @override
  String goalSourceExerciseBest(String exercise) {
    return 'Auto · meilleure série de $exercise';
  }

  @override
  String goalSourceExerciseDistance(String exercise) {
    return 'Auto · plus long $exercise';
  }

  @override
  String get goalSourceWorkouts => 'Auto · entraînements faits';

  @override
  String get goalSourceBodyWeight => 'Auto · poids';

  @override
  String goalSourceAccount(String account) {
    return 'Auto · solde de $account';
  }

  @override
  String get goalSourceProtein => 'Auto · protéines, moyenne sur 7 jours';

  @override
  String get goalSourceTasks => 'Auto · tâches liées faites';

  @override
  String goalBy(String date) {
    return 'd’ici $date';
  }

  @override
  String goalTasksDone(int done, int total) {
    return '$done sur $total tâches faites';
  }

  @override
  String goalNext(String task) {
    return 'suivante : $task';
  }

  @override
  String goalOf(String target) {
    return 'sur $target';
  }

  @override
  String get goalRecord => 'Noter';

  @override
  String goalTabTasks(int count) {
    return 'Tâches · $count';
  }

  @override
  String get goalTrackTitle => 'Suivre la progression avec';

  @override
  String get goalTrackLabel => 'Suivre la progression';

  @override
  String get goalTrackManualHint => 'Vous notez chaque valeur';

  @override
  String get goalTrackPickExercise => 'Quel exercice ?';

  @override
  String get goalTrackExerciseBest => 'Meilleure série';

  @override
  String get goalTrackExerciseBestHint =>
      'Le poids le plus lourd sur un exercice';

  @override
  String get goalTrackExerciseDistance => 'Plus longue distance';

  @override
  String get goalTrackExerciseDistanceHint =>
      'La plus longue course, sortie ou nage';

  @override
  String get goalTrackWorkouts => 'Entraînements faits';

  @override
  String get goalTrackWorkoutsHint => 'Entraînements terminés depuis le début';

  @override
  String get goalTrackBodyWeight => 'Poids';

  @override
  String get goalTrackBodyWeightHint => 'Votre dernière pesée';

  @override
  String get goalTrackAccount => 'Solde d’un compte';

  @override
  String get goalTrackAccountHint => 'Le solde d’un de vos comptes';

  @override
  String get goalTrackProtein => 'Protéines';

  @override
  String get goalTrackProteinHint => 'Protéines par jour, moyenne sur 7 jours';

  @override
  String get goalTrackTasks => 'Tâches liées';

  @override
  String get goalTrackTasksHint => 'Combien de tâches liées sont faites';

  @override
  String get goalReminderReplyBody =>
      'Où en êtes-vous ? Répondez avec la nouvelle valeur.';

  @override
  String get goalReminderReplyAction => 'Noter';

  @override
  String get goalReminderReplyHint => 'Nouvelle valeur';

  @override
  String get dashboardKcalLeftShort => 'kcal restantes';

  @override
  String get dashboardKcalOverShort => 'kcal en trop';

  @override
  String dashboardPlannedOn(String date) {
    return 'Prévu · $date';
  }

  @override
  String dashboardNowUntil(String time) {
    return 'En cours · jusqu\'à $time';
  }

  @override
  String dashboardNextAt(String time) {
    return 'Ensuite · $time';
  }

  @override
  String get dashboardNextUp => 'Ensuite';

  @override
  String get dashboardAllDoneToday => 'Tout est fait pour aujourd\'hui';

  @override
  String dashboardGoalBehind(String amount) {
    return 'En retard : il faut $amount par semaine';
  }

  @override
  String get dashboardGoalOnPace => 'Dans les temps';

  @override
  String dashboardGoalBy(String date) {
    return 'd\'ici $date';
  }

  @override
  String dashboardOfIncome(String amount) {
    return 'sur $amount reçus';
  }

  @override
  String dashboardAmountLeft(String amount) {
    return 'reste $amount';
  }

  @override
  String dashboardAmountOver(String amount) {
    return '$amount de trop';
  }

  @override
  String dashboardDaysLeftInMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours restants',
      one: '1 jour restant',
    );
    return '$_temp0';
  }
}
