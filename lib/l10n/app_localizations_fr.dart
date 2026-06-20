// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'fitfat';

  @override
  String get mealsTab => 'Repas';

  @override
  String get ingredientsTab => 'Ingrédients';

  @override
  String get addMeal => 'Ajouter un repas';

  @override
  String get addIngredient => 'Ajouter un ingrédient';

  @override
  String get editIngredient => 'Modifier un ingrédient';

  @override
  String get editMeal => 'Modifier le repas';

  @override
  String get archivedIngredients => 'Ingrédients archivés';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get archive => 'Archiver';

  @override
  String get restore => 'Restaurer';

  @override
  String get add => 'Ajouter';

  @override
  String get change => 'Modifier';

  @override
  String get clear => 'Effacer';

  @override
  String get ingredientName => 'Nom de l\'ingrédient';

  @override
  String get buildFromIngredients => 'Composer à partir d\'ingrédients';

  @override
  String get components => 'Composants';

  @override
  String get noComponentsAdded => 'Aucun composant ajouté';

  @override
  String get addComponents => 'Ajouter des ingrédients';

  @override
  String get searchIngredients => 'Rechercher des ingrédients';

  @override
  String get typeToSearchIngredient => 'Tapez pour rechercher';

  @override
  String get caloriesPer100g => 'Calories pour 100g';

  @override
  String get proteinPer100g => 'Protéines pour 100g (g)';

  @override
  String get carbsPer100g => 'Glucides pour 100g (g)';

  @override
  String get fatPer100g => 'Lipides pour 100g (g)';

  @override
  String get sodiumPer100g => 'Sodium pour 100g (mg)';

  @override
  String get fiberPer100g => 'Fibres pour 100g (g)';

  @override
  String get amountInGrams => 'Quantité en grammes';

  @override
  String get gramsHint => 'ex. 80';

  @override
  String get gramsHintMeal => 'ex. 120';

  @override
  String get createNewIngredient => 'Créer un ingrédient';

  @override
  String get mealNameOptional => 'Nom du repas (optionnel)';

  @override
  String get selectedIngredients => 'Ingrédients sélectionnés';

  @override
  String get noIngredientsSelected => 'Aucun ingrédient sélectionné';

  @override
  String get noIngredientsFound => 'Aucun ingrédient trouvé';

  @override
  String get archiveIngredientTitle => 'Archiver l\'ingrédient';

  @override
  String get archiveIngredientContent =>
      'Cet ingrédient sera masqué des vues normales. Utilisez l\'onglet Ingrédients archivés pour le restaurer ou le supprimer.';

  @override
  String get deleteMealTitle => 'Supprimer le repas ?';

  @override
  String get deleteMealContent => 'Cela supprimera le repas de votre journal.';

  @override
  String get deleteIngredientTitle => 'Supprimer l\'ingrédient ?';

  @override
  String get deleteIngredientContent =>
      'Cela supprimera l\'ingrédient et ses portions des repas.';

  @override
  String get permanentlyDeleteTitle => 'Supprimer définitivement l\'ingrédient';

  @override
  String get permanentlyDeleteContent =>
      'Cet ingrédient sera supprimé définitivement. Il ne peut pas être restauré.';

  @override
  String get restoreIngredientTitle => 'Restaurer l\'ingrédient';

  @override
  String get deleteMealTooltip => 'Supprimer le repas';

  @override
  String get deleteIngredientTooltip => 'Supprimer';

  @override
  String get ingredientArchived => 'Ingrédient archivé avec succès';

  @override
  String get ingredientDeleted => 'Ingrédient supprimé avec succès';

  @override
  String get ingredientRestored => 'Ingrédient restauré avec succès';

  @override
  String get meal => 'Repas';

  @override
  String get sortAZ => 'Trier A-Z';

  @override
  String get sortZA => 'Trier Z-A';

  @override
  String get noIngredientsFoundSubtext =>
      'Essayez une autre recherche ou ajoutez un nouvel ingrédient';

  @override
  String get kcalAbbrev => 'kcal';

  @override
  String get proteinAbbrev => 'P';

  @override
  String get carbsAbbrev => 'G';

  @override
  String get fatAbbrev => 'L';

  @override
  String eatenAtLabel(Object time) {
    return 'Pris à : $time';
  }

  @override
  String failedToSave(Object error) {
    return 'Échec de l\'enregistrement du repas : $error';
  }

  @override
  String failedToUpdate(Object error) {
    return 'Échec de la mise à jour du repas : $error';
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
      other: '$countString éléments',
      one: '$countString élément',
    );
    return '$_temp0';
  }

  @override
  String formatMacros(Object kcal, Object protein, Object carbs, Object fat) {
    return '$kcal kcal · P ${protein}g · G ${carbs}g · L ${fat}g';
  }

  @override
  String formatPer100g(Object kcal, Object protein, Object carbs, Object fat) {
    return 'Pour 100g : $kcal kcal · P ${protein}g · G ${carbs}g · L ${fat}g';
  }

  @override
  String formatTotal(Object total) {
    return 'Total : $total';
  }

  @override
  String get exercises => 'Exercices';

  @override
  String get exercise => 'Exercice';

  @override
  String get activeWorkout => 'Entraînement actif';

  @override
  String get noActiveSeance => 'Aucun entraînement actif';

  @override
  String get guidedMode => 'Guidé';

  @override
  String get freeformMode => 'Libre';

  @override
  String get cancelSeance => 'Annuler l\'entraînement';

  @override
  String get backToApp => 'Retour à l\'app';

  @override
  String get discardEmptySeance => 'Supprimer l\'entraînement vide ?';

  @override
  String get discardEmptySeanceContent =>
      'Cet entraînement n\'a pas d\'exercices et ne sera pas sauvegardé.';

  @override
  String get keepEditing => 'Continuer';

  @override
  String get discard => 'Supprimer';

  @override
  String get completeSeance => 'Terminer l\'entraînement';

  @override
  String get addExercise => 'Ajouter un exercice';

  @override
  String get followPlan => 'Suivre le plan';

  @override
  String get searchToAdd => 'Rechercher pour ajouter';

  @override
  String get searchExercises => 'Rechercher des exercices';

  @override
  String get exerciseTypeToSearch => 'Tapez pour rechercher...';

  @override
  String get typeToFindExercises => 'Tapez pour trouver...';

  @override
  String get sets => 'Séries';

  @override
  String get set => 'Série';

  @override
  String get setsLower => 'séries';

  @override
  String get done => 'fait';

  @override
  String get summary => 'Résumé';

  @override
  String get totalReps => 'Répétitions totales';

  @override
  String get totalWeight => 'Poids total';

  @override
  String get addSet => 'Ajouter une série';

  @override
  String get tapToComplete => 'Tapez pour valider';

  @override
  String get noExercisesFound => 'Aucun exercice trouvé pour';

  @override
  String get repsLower => 'rép';

  @override
  String get preFilledFrom => 'Pré-rempli depuis';

  @override
  String get allSetsComplete => 'Toutes les séries terminées !';

  @override
  String get restTimer => 'Minuteur de repos';

  @override
  String get skip => 'Passer';

  @override
  String get restOver => 'Repas terminé !';

  @override
  String get getReadyNextSet => 'Préparez-vous pour la prochaine série !';

  @override
  String get editSet => 'Modifier la série';

  @override
  String get weightKg => 'Poids (kg)';

  @override
  String get history => 'Historique';

  @override
  String get records => 'Records';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get sessions => 'Séances';

  @override
  String get volume => 'Volume';

  @override
  String get time => 'Temps';

  @override
  String get searchHistory => 'Rechercher dans l\'historique';

  @override
  String get searchByDateHint => 'Rechercher par date ou nom...';

  @override
  String get volumeProgression => 'Progression du volume';

  @override
  String get estimated1RM => 'Progression de la 1RM estimée';

  @override
  String get bestEstimated1RM => 'Meilleure 1RM estimée';

  @override
  String get maxWeight => 'Poids max';

  @override
  String get maxVolume => 'Volume max (Série)';

  @override
  String get totalVolume => 'Volume total';

  @override
  String get noHistoryContent =>
      'Complétez un entraînement avec cet exercice pour le voir ici';

  @override
  String get library => 'Bibliothèque';

  @override
  String get createExercise => 'Créer un exercice';

  @override
  String get exerciseName => 'Nom de l\'exercice';

  @override
  String get category => 'Catégorie';

  @override
  String get templates => 'Modèles';

  @override
  String get createTemplate => 'Créer un modèle';

  @override
  String exercisesCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString exercices',
      one: '$countString exercice',
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
      other: '$countString séries',
      one: '$countString série',
    );
    return '$_temp0';
  }

  @override
  String get workoutsTab => 'Entraînements';

  @override
  String get trainingTab => 'Entraînement';

  @override
  String get quickLog => 'Log rapide';

  @override
  String get followTodaysPlan => 'Suivre le plan du jour';

  @override
  String get startWorkout => 'Commencer';

  @override
  String get statsTab => 'Stats';

  @override
  String get searchExercisesHint => 'Rechercher des exercices...';

  @override
  String get noExercisesFoundSimple => 'Aucun exercice trouvé';

  @override
  String get noExercisesFoundAction =>
      'Essayez une autre recherche ou effacez les filtres';

  @override
  String get cardio => 'Cardio';

  @override
  String get weightlifting => 'Musculation';

  @override
  String get cardioDuration => 'Durée cardio';

  @override
  String get minutesLower => 'min';

  @override
  String get minutes => 'Minutes';

  @override
  String get setDuration => 'Définir la durée';

  @override
  String get quickLogTitle => 'Saisie rapide';

  @override
  String get quickLogSearchHint => 'Tapez pour rechercher un exercice...';

  @override
  String get quickLogSelectExercise => 'Veuillez sélectionner un exercice';

  @override
  String get quickLogEnterDuration => 'Veuillez entrer une durée valide';

  @override
  String get quickLogEnterReps =>
      'Veuillez entrer un nombre de répétitions valide';

  @override
  String get quickLogEnterWeight => 'Veuillez entrer un poids valide';

  @override
  String get quickLogSaved => 'Entraînement enregistré !';

  @override
  String get quickLogDurationHint => 'ex. 30';

  @override
  String get quickLogRepsHint => 'ex. 10';

  @override
  String get quickLogWeightHint => 'ex. 50';

  @override
  String get quickLogNotes => 'Notes';

  @override
  String get quickLogNotesHint => 'Notes optionnelles...';

  @override
  String get logWorkout => 'Enregistrer';

  @override
  String get noPlannedWorkoutsForDay =>
      'Aucun entraînement planifié pour ce jour';

  @override
  String get addPlannedWorkout => 'Ajouter un entraînement planifié';

  @override
  String get completed => 'Terminé';

  @override
  String get close => 'Fermer';

  @override
  String get startPlan => 'Commencer';

  @override
  String get deletePlannedWorkout => 'Supprimer l\'entraînement planifié';

  @override
  String get deletePlannedWorkoutContent =>
      'Êtes-vous sûr de vouloir supprimer cet entraînement planifié ?';

  @override
  String get noTemplatesAvailable => 'Aucun modèle disponible';

  @override
  String get selectTemplate => 'Sélectionner un modèle';

  @override
  String get error => 'Erreur';

  @override
  String get enterWorkoutName => 'Veuillez saisir un nom d\'entraînement';

  @override
  String get addAtLeastOneExercise => 'Veuillez ajouter au moins un exercice';

  @override
  String get plannedWorkoutSaved => 'Entraînement planifié enregistré !';

  @override
  String get editPlannedWorkout => 'Modifier l\'entraînement planifié';

  @override
  String get planWorkout => 'Planifier un entraînement';

  @override
  String get workoutName => 'Nom de l\'entraînement';

  @override
  String get copyFromTemplate => 'Copier depuis un modèle';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get savePlan => 'Enregistrer le plan';

  @override
  String get runningWorkout => 'Séance en cours';

  @override
  String get resumeWorkout => 'Reprendre';

  @override
  String get viewWorkout => 'Voir';

  @override
  String get stopWorkout => 'Arrêter';

  @override
  String get newSeance => 'Nouvelle séance';

  @override
  String get startBlankSeance => 'Démarrer une séance vide';

  @override
  String get create => 'Créer';

  @override
  String get noTemplatesYet =>
      'Pas encore de modèles. Créez-en un pour démarrer rapidement !';

  @override
  String get browseAllTemplates => 'Parcourir tous les modèles';

  @override
  String get noWorkoutsYet =>
      'Pas encore d\'entraînements. Commencez le premier ci-dessus !';

  @override
  String get allTime => 'Tout temps';

  @override
  String get workouts => 'Entraînements';

  @override
  String get duration => 'Durée';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get activity => 'Activité';

  @override
  String get trends => 'Tendances';

  @override
  String get edit => 'Modifier';

  @override
  String get clone => 'Dupliquer';

  @override
  String get start => 'Démarrer';

  @override
  String get createTemplateFrom => 'Créer un modèle à partir de ceci';

  @override
  String get workoutAlreadyRunning => 'Entraînement déjà en cours';

  @override
  String get workoutAlreadyRunningContent =>
      'Un entraînement est déjà en cours. L\'annuler et en démarrer un nouveau ?';

  @override
  String get startNewWorkout => 'Démarrer un nouvel entraînement';

  @override
  String get workout => 'Entraînement';

  @override
  String get noExercises => 'Aucun exercice';

  @override
  String get pr => 'RP !';

  @override
  String get oneRM => '1RM est.';

  @override
  String get workoutSummary => 'Résumé de l\'entraînement';

  @override
  String get exerciseBreakdown => 'Détail des exercices';

  @override
  String get best => 'Meilleur';

  @override
  String get finish => 'Terminer';

  @override
  String previousSessions(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return 'Sessions précédentes ($countString)';
  }

  @override
  String get tapToExpand => 'Appuyez pour développer';

  @override
  String get reps => 'Répétitions';

  @override
  String get templateLibrary => 'Bibliothèque de modèles';

  @override
  String get createFirstTemplate => 'Créez votre premier modèle';

  @override
  String get editTemplate => 'Modifier le modèle';

  @override
  String get templateNameLabel => 'Nom du modèle';

  @override
  String get addCustom => 'Ajouter comme exercice personnalisé';

  @override
  String get searchAboveHint =>
      'Cherchez un exercice ci-dessus pour l\'ajouter. Appuyez sur un exercice dans la liste pour configurer les séries et les répétitions.';

  @override
  String get noExercisesAdded => 'Aucun exercice ajouté';

  @override
  String get noSetsConfigured =>
      'Aucune série configurée — appuyez pour modifier';

  @override
  String get remove => 'Supprimer';

  @override
  String get restSeconds => 'Repos (s)';

  @override
  String get pastMonth => 'Le mois dernier';

  @override
  String get past3Months => 'Les 3 derniers mois';

  @override
  String get pastYear => 'L\'année dernière';

  @override
  String noHistoryFor(Object name) {
    return 'Pas encore d\'historique pour $name';
  }

  @override
  String get completeWorkoutToSee =>
      'Effectuez un entraînement avec cet exercice pour le voir ici';

  @override
  String get date => 'Date';

  @override
  String get searchByDateWorkout =>
      'Rechercher par date ou nom d\'entraînement...';

  @override
  String sessionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '$count séance',
    );
    return '$_temp0';
  }

  @override
  String get maxVolumeSet => 'Volume max (série)';

  @override
  String get notAvailable => 'N/D';

  @override
  String get across => 'Sur';

  @override
  String get overviewTab => 'Aperçu';

  @override
  String get goalsTab => 'Objectifs';

  @override
  String get settingsTab => 'Paramètres';

  @override
  String get weight => 'Poids';

  @override
  String get weightLogged => 'Poids enregistré !';

  @override
  String get enterWeightKg => 'Entrez le poids (kg)';

  @override
  String get log => 'Enregistrer';

  @override
  String get weightTracker => 'Suivi du poids';

  @override
  String get noWeightEntries => 'Aucune entrée de poids.';

  @override
  String get latest => 'Dernier';

  @override
  String get logWeight => 'Enregistrer le poids';

  @override
  String get historyLast7Entries => 'Historique (7 dernières entrées)';

  @override
  String get waterIntake => 'Hydratation';

  @override
  String get goal => 'Objectif';

  @override
  String get setDailyWaterGoal => 'Définir l\'objectif d\'eau quotidien';

  @override
  String get litersExample => 'Litres (ex. 2,5)';

  @override
  String get todaysActivity => 'Activité du jour';

  @override
  String get workoutInProgress => 'Entraînement en cours';

  @override
  String get exercisesCompleted => 'exercices effectués';

  @override
  String get noWorkoutsToday =>
      'Pas encore d\'entraînement. Commencez une séance pour voir le résumé ici.';

  @override
  String get elapsed => 'écoulé';

  @override
  String get last84Days => '84 derniers jours';

  @override
  String get noTrainingRecorded => 'Aucun entraînement enregistré ce jour.';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protéines';

  @override
  String get carbs => 'Glucides';

  @override
  String get fat => 'Lipides';

  @override
  String get setProfileForTargets =>
      'Définissez un objectif de poids et votre profil pour voir les objectifs quotidiens.';

  @override
  String get bodyWeightGoal => 'Objectif de poids';

  @override
  String get noBodyweightGoalSet => 'Aucun objectif de poids défini.';

  @override
  String get addBodyWeightGoal => 'Ajouter un objectif de poids';

  @override
  String get target => 'Cible';

  @override
  String get by => 'D\'ici le';

  @override
  String get strengthGoals => 'Objectifs de force';

  @override
  String get addStrengthGoalTooltip => 'Ajouter un objectif de force';

  @override
  String get noStrengthGoalsYet =>
      'Pas encore d\'objectifs de force. Appuyez sur + pour en ajouter (un par exercice).';

  @override
  String get setUpProfileFirst => 'Configurez d\'abord votre profil';

  @override
  String get createProfile => 'Créer le profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get yourProfile => 'Votre profil';

  @override
  String get birthdate => 'Date de naissance';

  @override
  String get sex => 'Sexe';

  @override
  String get heightCm => 'Taille (cm)';

  @override
  String get activityLevel => 'Niveau d\'activité';

  @override
  String get addBodyWeightGoalTitle => 'Ajouter un objectif de poids';

  @override
  String get editBodyWeightGoalTitle => 'Modifier l\'objectif de poids';

  @override
  String get direction => 'Direction';

  @override
  String get targetWeightKg => 'Poids cible (kg)';

  @override
  String get targetDate => 'Date cible';

  @override
  String get notSet => 'Non défini';

  @override
  String get addStrengthGoalTitle => 'Ajouter un objectif de force';

  @override
  String get editStrengthGoalTitle => 'Modifier l\'objectif de force';

  @override
  String get searchOrTypeCustom => 'Rechercher ou saisir un nom personnalisé';

  @override
  String get deleteBodyweightGoal => 'Supprimer l\'objectif de poids ?';

  @override
  String get deleteBodyweightGoalContent =>
      'Cela effacera votre objectif de poids et vos objectifs macro.';

  @override
  String deleteStrengthGoalTitle(Object exercise) {
    return 'Supprimer l\'objectif de force pour $exercise ?';
  }

  @override
  String get deleteStrengthGoalContent => 'Cela supprimera l\'objectif.';

  @override
  String get deleteEverything => 'Tout supprimer';

  @override
  String get goalReached => 'Objectif atteint !';

  @override
  String get toGo => 'restant';

  @override
  String get strengthTrend => 'Tendance de force';

  @override
  String get noStrengthData => 'Aucune donnée de force';

  @override
  String get weightTrend90Days => 'Tendance du poids (90 jours)';

  @override
  String get profile => 'Profil';

  @override
  String get setUpProfile => 'Configurer le profil';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get visibleMacros => 'Macros visibles';

  @override
  String get defaultRestTimer => 'Minuteur de repos par défaut';

  @override
  String get secondsBetweenSets => '60 secondes entre les séries';

  @override
  String get restTimerComingSoon => 'Paramètres du minuteur de repos à venir';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get systemDefault => 'Par défaut';

  @override
  String get themeComingSoon => 'Paramètres du thème à venir';

  @override
  String get data => 'Données';

  @override
  String get exportDatabase => 'Exporter la base de données';

  @override
  String get shareDbFile => 'Partager le fichier SQLite';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get removeEverything => 'Tout supprimer et recommencer à zéro';

  @override
  String get noDbFound => 'Aucun fichier de base de données trouvé';

  @override
  String get deleteAllDataTitle => 'Supprimer toutes les données ?';

  @override
  String get deleteAllDataContent =>
      'Cela supprimera toutes vos données, y compris les repas, exercices, entraînements, objectifs et profil. Une nouvelle base de données sera créée au prochain démarrage.';

  @override
  String get dbDeleted =>
      'Base de données supprimée. Redémarrez l\'application pour la recréer.';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get couldNotLoadWeightHistory =>
      'Impossible de charger l\'historique du poids.';

  @override
  String get trainingHeatmap => 'Carte thermique des entraînements';

  @override
  String get heatmapLegendLow => 'Faible';

  @override
  String get heatmapLegendMid => 'Moyen';

  @override
  String get heatmapLegendHigh => 'Élevé';

  @override
  String get benchPress => 'Développé couché';

  @override
  String get deadlift => 'Soulevé de terre';

  @override
  String get squat => 'Squat';

  @override
  String get enterDetailsForMacros =>
      'Entrez vos détails pour les calculs de macros';

  @override
  String exportFailed(Object error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String deleteFailed(Object error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get navDiet => 'Repas';

  @override
  String get navDashboard => 'Tableau';

  @override
  String get navExercise => 'Entraînement';
}
