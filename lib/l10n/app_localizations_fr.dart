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
  String get dashboardAppBar => 'Tableau de bord';

  @override
  String get dashboardTodayCalories => 'Calories du jour';

  @override
  String get dashboardLatestWorkout => 'Dernière séance';

  @override
  String get dashboardNoWorkouts => 'Aucune séance terminée.';

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
  String get exerciseListAppBar => 'Exercices';

  @override
  String get exerciseListManageBtn => 'Gérer les exercices';

  @override
  String get exerciseListEmpty =>
      'Aucun exercice. Appuyez sur + pour en ajouter un.';

  @override
  String get exerciseListDeleteTitle => 'Supprimer l\'exercice ?';

  @override
  String exerciseListDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

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
  String get workoutListEmpty =>
      'Aucune séance. Appuyez sur + pour en créer une.';

  @override
  String get workoutListDeleteTitle => 'Supprimer la séance ?';

  @override
  String workoutListDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get workoutFormTitle => 'Nouvelle séance';

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
  String get workoutDetailNoExercises => 'Aucun exercice dans cette séance.';

  @override
  String get workoutDetailSetHeaderHash => '#';

  @override
  String get workoutDetailSetHeaderPlanned => 'Prévu';

  @override
  String get workoutDetailSetHeaderActual => 'Réel';

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
  String get ingredientListEmpty =>
      'Aucun ingrédient. Appuyez sur + pour en ajouter un.';

  @override
  String get ingredientListDeleteTitle => 'Supprimer l\'ingrédient ?';

  @override
  String ingredientListDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
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
  String get mealListEmpty => 'Aucun repas. Appuyez sur + pour en ajouter un.';

  @override
  String get mealListDeleteTitle => 'Supprimer le repas ?';

  @override
  String mealListDeleteConfirm(String name) {
    return 'Supprimer « $name » ?';
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
  String get settingsAppBar => 'Paramètres';

  @override
  String get settingsBody => 'Paramètres';

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
  String get commonDelete => 'Supprimer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaving => 'Enregistrement…';

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
