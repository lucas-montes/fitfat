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
  String get dashboardRemaining => 'restant';

  @override
  String dashboardConsumedOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String dashboardOverTarget(String kcal) {
    return '$kcal kcal au-dessus de l\'objectif';
  }

  @override
  String get dashboardMacroTargets => 'Objectifs macro';

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
  String dashboardVolumeKg(String volume, String unit) {
    return '$volume $unit';
  }

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
  String get exerciseFormSave => 'Enregistrer';

  @override
  String get exerciseFormSaving => 'Enregistrement…';

  @override
  String get workoutListAppBar => 'Séances';

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
  String get workoutFormSelectExercise => 'Sélectionnez au moins un exercice';

  @override
  String get workoutFormSearchHint => 'Rechercher des exercices';

  @override
  String get workoutFormRestLabel => 'Repos (min)';

  @override
  String get workoutFormSetIncomplete =>
      'Complétez chaque série ajoutée (valeurs et temps de repos) ou retirez-la';

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
  String get ingredientFormSodiumSuffix => 'mg';

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
  String mealDeleted(String name) {
    return 'Repas « $name » supprimé';
  }

  @override
  String mealListIngredientCount(int count) {
    return '$count ingrédient';
  }

  @override
  String mealListIngredientCount_plural(Object count) {
    return '$count ingrédients';
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
  String get mealFormNameHint => 'Ex. : Petit-déjeuner';

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
  String get plannerViewMonth => 'Vue mois';

  @override
  String get plannerViewDay => 'Vue jour';

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
  String get plannerCopyPrevious => 'Copier depuis hier';

  @override
  String get plannerMoreActions => 'Plus d\'actions';

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
  String get settingsCurrencyBudgetSubtitle =>
      'Devise de base et taux de change';

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
  String get settingsComputeActivity =>
      'Calculer l\'activité à partir des séances et des pas';

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
    return 'Na ${value}mg';
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
  String ingredientDetailCostPer100g(String value) {
    return '$value / 100 g';
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
  String get ingredientPriceGramsLabel => 'Poids du paquet (g)';

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
  String get settingsExperimentReminders => 'Rappels d\'expériences';

  @override
  String get settingsExperimentRemindersSubtitle =>
      'Rappels quotidiens tant qu\'une expérience est en cours';

  @override
  String get settingsSyncServer => 'Serveur de synchronisation';

  @override
  String get settingsSyncServerHint =>
      'Indiquez votre serveur de sync pour récupérer exercices, ingrédients et devises. Laissez vide pour désactiver la sync.';

  @override
  String get settingsSyncBaseUrl => 'URL du serveur';

  @override
  String get settingsSyncApiKey => 'Clé API';

  @override
  String get syncExercisesTooltip => 'Synchroniser les exercices';

  @override
  String get syncIngredientsTooltip => 'Synchroniser les ingrédients';

  @override
  String get syncCurrenciesTooltip => 'Synchroniser les devises';

  @override
  String get syncPushIngredientTooltip => 'Publier dans le catalogue partagé';

  @override
  String get syncServerNotConfigured =>
      'L\'URL du serveur de synchronisation n\'est pas configurée';

  @override
  String get settingsUnits => 'Unités';

  @override
  String get settingsWeightUnitLabel => 'Poids';

  @override
  String get settingsLengthUnitLabel => 'Taille';

  @override
  String get settingsExportDb => 'Exporter la base de données';

  @override
  String get settingsExportDbSubtitle =>
      'Partager une copie de vos données (SQLite)';

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
  String get workoutSummaryDone => 'Terminé';

  @override
  String get workoutSummaryDurationLabel => 'Durée';

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
  String get settingsRateManual => 'Manuel';

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
  String get commonDelete => 'Common Delete';

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
  String get settingsRateEdit => 'Modifier le taux';

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
      'Aucun compte pour le moment. Ajoutez-en un.';

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
  String get receiptUploadSuccess => 'Reçu envoyé';

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
  String get tabExperiments => 'Expériences';

  @override
  String get experimentsAppBar => 'Expériences';

  @override
  String get experimentsFab => 'Nouvelle expérience';

  @override
  String get experimentsEmptyTitle => 'Aucune expérience';

  @override
  String get experimentsEmptyBody =>
      'Créez une expérience pour suivre une habitude, un changement alimentaire ou un protocole d\'entraînement avec des bilans quotidiens.';

  @override
  String get experimentsNoEndDate => 'Sans date de fin';

  @override
  String experimentDaysElapsed(int days) {
    return '$days jours écoulés';
  }

  @override
  String get experimentStatusPlanned => 'Planifiée';

  @override
  String get experimentStatusActive => 'En cours';

  @override
  String get experimentStatusDone => 'Terminée';

  @override
  String get experimentStatusAborted => 'Abandonnée';

  @override
  String get experimentCategoryWorkout => 'Entraînement';

  @override
  String get experimentCategoryDiet => 'Alimentation';

  @override
  String get experimentCategoryBody => 'Corps';

  @override
  String get experimentCategorySteps => 'Pas';

  @override
  String get experimentFormTitleNew => 'Nouvelle expérience';

  @override
  String get experimentFormTitleEdit => 'Modifier l\'expérience';

  @override
  String get experimentFormNameLabel => 'Nom';

  @override
  String get experimentFormNameHint => 'ex. bloc d\'hypertrophie de 8 semaines';

  @override
  String get experimentFormPurposeLabel => 'Hypothèse / objectif';

  @override
  String get experimentFormPurposeHint => 'Que testez-vous ?';

  @override
  String get experimentFormStartLabel => 'Date de début';

  @override
  String get experimentFormEndLabel => 'Date de fin';

  @override
  String get experimentFormStatusLabel => 'Statut';

  @override
  String get experimentFormCategoriesLabel => 'Données suivies';

  @override
  String get experimentFormReminderLabel => 'Rappel de bilan quotidien';

  @override
  String get experimentFormReminderSubtitle =>
      'Une notification ouvre cette expérience pour une évaluation rapide.';

  @override
  String get experimentFormReminderTimeLabel => 'Heure du rappel';

  @override
  String get experimentFormDelete => 'Supprimer';

  @override
  String get experimentFormDeleteConfirmTitle => 'Supprimer l\'expérience ?';

  @override
  String get experimentFormDeleteConfirmBody =>
      'Cela supprime aussi les bilans de l\'expérience.';

  @override
  String get experimentFormNameRequired => 'Donnez un nom à l\'expérience.';

  @override
  String get experimentFormInvalidDates =>
      'La date de fin doit être postérieure ou égale à la date de début.';

  @override
  String get experimentDetailCheckin => 'Bilan';

  @override
  String get experimentDetailCheckinToday =>
      'Vous avez déjà fait votre bilan aujourd\'hui. Vous pouvez le mettre à jour.';

  @override
  String get experimentDetailCheckinDialogTitle => 'Bilan quotidien';

  @override
  String get experimentDetailCheckinRatingLabel => 'Note';

  @override
  String get experimentDetailCheckinRatingHint =>
      '1 = journée difficile, 5 = excellente journée';

  @override
  String get experimentDetailCheckinNoteLabel => 'Note (facultatif)';

  @override
  String get experimentDetailCheckinNoteHint =>
      'Comment s\'est passée la journée ?';

  @override
  String get experimentDetailProgressTitle => 'Progression';

  @override
  String get experimentDetailCheckinsTitle => 'Bilans';

  @override
  String get experimentDetailTrackedTitle => 'Données suivies';

  @override
  String get experimentDetailBaselineTitle => 'Base de 14 jours';

  @override
  String get experimentDetailNoData =>
      'Aucune donnée pour cette période pour le moment.';

  @override
  String get experimentDetailMarkDone => 'Marquer terminée';

  @override
  String get experimentDetailAbort => 'Abandonner';

  @override
  String experimentDetailCheckinCount(int count) {
    return '$count bilans';
  }

  @override
  String experimentRatingOf5(int rating) {
    return '$rating/5';
  }

  @override
  String get experimentChartWorkout => 'Volume d\'entraînement (kg)';

  @override
  String get experimentChartDiet => 'Calories (kcal)';

  @override
  String get experimentChartDietProtein => 'Protéines (g)';

  @override
  String get experimentChartWeight => 'Poids (kg)';

  @override
  String get experimentChartSteps => 'Pas';

  @override
  String experimentReminderTitle(String experiment) {
    return 'Bilan pour $experiment';
  }

  @override
  String get experimentReminderBody =>
      'Évaluez votre journée pour cette expérience.';

  @override
  String experimentReminderScheduled(String time) {
    return 'Rappel quotidien réglé à $time.';
  }

  @override
  String get experimentReminderCancelled => 'Rappel quotidien désactivé.';
}
