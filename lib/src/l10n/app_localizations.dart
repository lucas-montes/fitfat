import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Centralized localization class for the diet module.
/// Supports en, fr, es.
class AppLocalizations {
  final String localeName;

  const AppLocalizations(this.localeName);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── Tab / screen titles ──

  String get mealsTab => _t('Meals', 'Repas', 'Comidas');
  String get ingredientsTab => _t('Ingredients', 'Ingrédients', 'Ingredientes');
  String get addMeal => _t('Add Meal', 'Ajouter un repas', 'Añadir comida');
  String get addIngredient =>
      _t('Add Ingredient', 'Ajouter un ingrédient', 'Añadir ingrediente');
  String get editIngredient =>
      _t('Edit Ingredient', 'Modifier un ingrédient', 'Editar ingrediente');
  String get editMeal => _t('Edit Meal', 'Modifier le repas', 'Editar comida');
  String get archivedIngredients => _t(
    'Archived Ingredients',
    'Ingrédients archivés',
    'Ingredientes archivados',
  );

  // ── Actions ──

  String get save => _t('Save', 'Enregistrer', 'Guardar');
  String get cancel => _t('Cancel', 'Annuler', 'Cancelar');
  String get delete => _t('Delete', 'Supprimer', 'Eliminar');
  String get archive => _t('Archive', 'Archiver', 'Archivar');
  String get restore => _t('Restore', 'Restaurer', 'Restaurar');
  String get add => _t('Add', 'Ajouter', 'Añadir');
  String get change => _t('Change', 'Modifier', 'Cambiar');
  String get clear => _t('Clear', 'Effacer', 'Limpiar');

  // ── Ingredient editor ──

  String get ingredientName =>
      _t('Ingredient name', 'Nom de l\'ingrédient', 'Nombre del ingrediente');
  String get buildFromIngredients => _t(
    'Build from ingredients',
    'Composer à partir d\'ingrédients',
    'Componer a partir de ingredientes',
  );
  String get components => _t('Components', 'Composants', 'Componentes');
  String get noComponentsAdded => _t(
    'No components added yet',
    'Aucun composant ajouté',
    'No hay componentes añadidos',
  );
  String get addComponents =>
      _t('Add ingredients', 'Ajouter des ingrédients', 'Añadir ingredientes');
  String get searchIngredients => _t(
    'Search ingredients',
    'Rechercher des ingrédients',
    'Buscar ingredientes',
  );
  String get typeToSearchIngredient => _t(
    'Type to search ingredients',
    'Tapez pour rechercher',
    'Escriba para buscar',
  );
  String get caloriesPer100g =>
      _t('Calories per 100g', 'Calories pour 100g', 'Calorías por 100g');
  String get proteinPer100g => _t(
    'Protein per 100g (g)',
    'Protéines pour 100g (g)',
    'Proteínas por 100g (g)',
  );
  String get carbsPer100g => _t(
    'Carbs per 100g (g)',
    'Glucides pour 100g (g)',
    'Carbohidratos por 100g (g)',
  );
  String get fatPer100g =>
      _t('Fat per 100g (g)', 'Lipides pour 100g (g)', 'Grasas por 100g (g)');
  String get amountInGrams =>
      _t('Amount in grams', 'Quantité en grammes', 'Cantidad en gramos');
  String get gramsHint => _t('e.g. 80', 'ex. 80', 'ej. 80');
  String get gramsHintMeal => _t('e.g. 120', 'ex. 120', 'ej. 120');
  String get createNewIngredient => _t(
    'Create new ingredient',
    'Créer un ingrédient',
    'Crear nuevo ingrediente',
  );

  // ── Meal editor ──

  String get mealNameOptional => _t(
    'Meal name (optional)',
    'Nom du repas (optionnel)',
    'Nombre de la comida (opcional)',
  );
  String get selectedIngredients => _t(
    'Selected ingredients',
    'Ingrédients sélectionnés',
    'Ingredientes seleccionados',
  );
  String get noIngredientsSelected => _t(
    'No ingredients selected yet',
    'Aucun ingrédient sélectionné',
    'No hay ingredientes seleccionados',
  );
  String get noIngredientsFound => _t(
    'No ingredients found',
    'Aucun ingrédient trouvé',
    'No se encontraron ingredientes',
  );

  // ── Dialogs ──

  String get archiveIngredientTitle => _t(
    'Archive Ingredient',
    'Archiver l\'ingrédient',
    'Archivar ingrediente',
  );
  String get archiveIngredientContent => _t(
    'This ingredient will be hidden from regular views. Use the Archived Ingredients tab to restore or delete it.',
    'Cet ingrédient sera masqué des vues normales. Utilisez l\'onglet Ingrédients archivés pour le restaurer ou le supprimer.',
    'Este ingrediente se ocultará de las vistas normales. Use la pestaña Ingredientes archivados para restaurarlo o eliminarlo.',
  );
  String get deleteMealTitle =>
      _t('Delete meal?', 'Supprimer le repas ?', '¿Eliminar comida?');
  String get deleteMealContent => _t(
    'This will remove the meal from your log.',
    'Cela supprimera le repas de votre journal.',
    'Esto eliminará la comida de su registro.',
  );
  String get deleteIngredientTitle => _t(
    'Delete ingredient?',
    'Supprimer l\'ingrédient ?',
    '¿Eliminar ingrediente?',
  );
  String get deleteIngredientContent => _t(
    'This will remove the ingredient and any portions from meals.',
    'Cela supprimera l\'ingrédient et ses portions des repas.',
    'Esto eliminará el ingrediente y sus porciones de las comidas.',
  );
  String get permanentlyDeleteTitle => _t(
    'Permanently Delete Ingredient',
    'Supprimer définitivement l\'ingrédient',
    'Eliminar ingrediente permanentemente',
  );
  String get permanentlyDeleteContent => _t(
    'This ingredient will be deleted permanently. It cannot be restored.',
    'Cet ingrédient sera supprimé définitivement. Il ne peut pas être restauré.',
    'Este ingrediente se eliminará permanentemente. No se puede restaurar.',
  );
  String get restoreIngredientTitle => _t(
    'Restore Ingredient',
    'Restaurer l\'ingrédient',
    'Restaurar ingrediente',
  );

  // ── Format helpers ──

  String formatMacros(double kcal, double protein, double carbs, double fat) {
    return _t(
      '${kcal.toStringAsFixed(0)} kcal · P ${protein.toStringAsFixed(1)}g · C ${carbs.toStringAsFixed(1)}g · F ${fat.toStringAsFixed(1)}g',
      '${kcal.toStringAsFixed(0)} kcal · P ${protein.toStringAsFixed(1)}g · G ${carbs.toStringAsFixed(1)}g · L ${fat.toStringAsFixed(1)}g',
      '${kcal.toStringAsFixed(0)} kcal · P ${protein.toStringAsFixed(1)}g · C ${carbs.toStringAsFixed(1)}g · G ${fat.toStringAsFixed(1)}g',
    );
  }

  String formatPer100g(double kcal, double protein, double carbs, double fat) {
    return _t(
      'Per 100g: ${kcal.toStringAsFixed(0)} kcal · P ${protein.toStringAsFixed(1)}g · C ${carbs.toStringAsFixed(1)}g · F ${fat.toStringAsFixed(1)}g',
      'Pour 100g : ${kcal.toStringAsFixed(0)} kcal · P ${protein.toStringAsFixed(1)}g · G ${carbs.toStringAsFixed(1)}g · L ${fat.toStringAsFixed(1)}g',
      'Por 100g: ${kcal.toStringAsFixed(0)} kcal · P ${protein.toStringAsFixed(1)}g · C ${carbs.toStringAsFixed(1)}g · G ${fat.toStringAsFixed(1)}g',
    );
  }

  String formatTotal(String total) =>
      _t('Total: $total', 'Total : $total', 'Total: $total');

  String get deleteMealTooltip =>
      _t('Delete meal', 'Supprimer le repas', 'Eliminar comida');
  String get deleteIngredientTooltip => _t('Delete', 'Supprimer', 'Eliminar');

  // ── Snackbar ──

  String get ingredientArchived => _t(
    'Ingredient archived successfully',
    'Ingrédient archivé avec succès',
    'Ingrediente archivado correctamente',
  );
  String get ingredientDeleted => _t(
    'Ingredient deleted successfully',
    'Ingrédient supprimé avec succès',
    'Ingrediente eliminado correctamente',
  );
  String get ingredientRestored => _t(
    'Ingredient restored successfully',
    'Ingrédient restauré avec succès',
    'Ingrediente restaurado correctamente',
  );
  String failedToSave(String e) => _t(
    'Failed to save meal: $e',
    'Échec de l\'enregistrement du repas : $e',
    'Error al guardar la comida: $e',
  );
  String failedToUpdate(String e) => _t(
    'Failed to update meal: $e',
    'Échec de la mise à jour du repas : $e',
    'Error al actualizar la comida: $e',
  );

  String items(int count) => _t(
    count == 1 ? '$count item' : '$count items',
    count == 1 ? '$count élément' : '$count éléments',
    count == 1 ? '$count elemento' : '$count elementos',
  );

  // ── Exercise module ──

  String get exercises => _t('Exercises', 'Exercices', 'Ejercicios');
  String get exercise => _t('Exercise', 'Exercice', 'Ejercicio');
  String get activeSeance =>
      _t('Active Seance', 'Séance active', 'Sesión activa');
  String get noActiveSeance =>
      _t('No active seance', 'Aucune séance active', 'No hay sesión activa');
  String get guidedMode => _t('Guided', 'Guidé', 'Guiado');
  String get freeformMode => _t('Free-form', 'Libre', 'Libre');
  String get cancelSeance =>
      _t('Cancel seance', 'Annuler la séance', 'Cancelar sesión');
  String get backToApp =>
      _t('Back to app', 'Retour à l\'app', 'Volver a la app');
  String get discardEmptySeance => _t(
    'Discard empty seance?',
    'Supprimer la séance vide ?',
    '¿Descartar sesión vacía?',
  );
  String get discardEmptySeanceContent => _t(
    'This seance has no exercises and will not be saved to history.',
    'Cette séance n\'a pas d\'exercices et ne sera pas sauvegardée.',
    'Esta sesión no tiene ejercicios y no se guardará en el historial.',
  );
  String get keepEditing => _t('Keep editing', 'Continuer', 'Seguir editando');
  String get discard => _t('Discard', 'Supprimer', 'Descartar');
  String get completeSeance =>
      _t('Complete Seance', 'Terminer la séance', 'Completar sesión');
  String get addExercise =>
      _t('Add Exercise', 'Ajouter un exercice', 'Añadir ejercicio');
  String get followPlan =>
      _t('Follow the plan', 'Suivre le plan', 'Seguir el plan');
  String get searchToAdd =>
      _t('Search to add', 'Rechercher pour ajouter', 'Buscar para añadir');
  String get searchExercises =>
      _t('Search exercises', 'Rechercher des exercices', 'Buscar ejercicios');
  String get exerciseTypeToSearch => _t(
    'Type to search exercises...',
    'Tapez pour rechercher...',
    'Escriba para buscar...',
  );
  String get typeToFindExercises => _t(
    'Type to find exercises...',
    'Tapez pour trouver...',
    'Escriba para encontrar...',
  );
  String get sets => _t('Sets', 'Séries', 'Series');
  String get set => _t('Set', 'Série', 'Serie');
  String get setsLower => _t('sets', 'séries', 'series');
  String get done => _t('done', 'fait', 'hecho');
  String get summary => _t('Summary', 'Résumé', 'Resumen');
  String get totalReps =>
      _t('Total Reps', 'Répétitions totales', 'Reps totales');
  String get totalWeight => _t('Total Weight', 'Poids total', 'Peso total');
  String get addSet => _t('Add Set', 'Ajouter une série', 'Añadir serie');
  String get tapToComplete =>
      _t('Tap to complete', 'Tapez pour valider', 'Tocar para completar');
  String get noExercisesFound => _t(
    'No exercises found matching',
    'Aucun exercice trouvé pour',
    'No se encontraron ejercicios para',
  );
  String get repsLower => _t('reps', 'rép', 'reps');
  String get preFilledFrom =>
      _t('Pre-filled from', 'Pré-rempli depuis', 'Prellenado desde');
  String get allSetsComplete => _t(
    'All sets complete!',
    'Toutes les séries terminées !',
    '¡Todas las series completas!',
  );
  String get restTimer =>
      _t('Rest Timer', 'Minuteur de repos', 'Temporizador de descanso');
  String get skip => _t('Skip', 'Passer', 'Saltar');
  String get restOver =>
      _t('Rest over!', 'Repas terminé !', '¡Descanso terminado!');
  String get getReadyNextSet => _t(
    'Get ready for your next set!',
    'Préparez-vous pour la prochaine série !',
    '¡Prepárate para la próxima serie!',
  );
  String get editSet => _t('Edit Set', 'Modifier la série', 'Editar serie');
  String get weightKg => _t('Weight (kg)', 'Poids (kg)', 'Peso (kg)');

  // ── History & Charts ──

  String get history => _t('History', 'Historique', 'Historial');
  String get records => _t('Records', 'Records', 'Récords');
  String get noHistory =>
      _t('No history yet', 'Aucun historique', 'Sin historial');
  String get sessions => _t('Sessions', 'Séances', 'Sesiones');
  String get volume => _t('Volume', 'Volume', 'Volumen');
  String get time => _t('Time', 'Temps', 'Tiempo');
  String get searchHistory =>
      _t('Search history', 'Rechercher', 'Buscar en historial');
  String get searchByDateHint => _t(
    'Search by date or seance name...',
    'Rechercher par date ou nom...',
    'Buscar por fecha o nombre...',
  );
  String get volumeProgression => _t(
    'Volume Progression',
    'Progression du volume',
    'Progresión del volumen',
  );
  String get estimated1RM => _t(
    'Estimated 1RM Progression',
    'Progression de la 1RM estimée',
    'Progresión de 1RM estimada',
  );
  String get bestEstimated1RM =>
      _t('Best Estimated 1RM', 'Meilleure 1RM estimée', 'Mejor 1RM estimada');
  String get maxWeight => _t('Max Weight', 'Poids max', 'Peso máximo');
  String get maxVolume =>
      _t('Max Volume (Set)', 'Volume max (Série)', 'Volumen máximo (Serie)');
  String get totalVolume => _t('Total Volume', 'Volume total', 'Volumen total');
  String get noHistoryContent => _t(
    'Complete a seance with this exercise to see it here',
    'Complétez une séance avec cet exercice pour le voir ici',
    'Completa una sesión con este ejercicio para verlo aquí',
  );

  // ── Library ──

  String get library => _t('Library', 'Bibliothèque', 'Biblioteca');
  String get createExercise =>
      _t('Create Exercise', 'Créer un exercice', 'Crear ejercicio');
  String get exerciseName =>
      _t('Exercise name', 'Nom de l\'exercice', 'Nombre del ejercicio');
  String get category => _t('Category', 'Catégorie', 'Categoría');
  String get templates => _t('Templates', 'Modèles', 'Plantillas');
  String get createTemplate =>
      _t('Create Template', 'Créer un modèle', 'Crear plantilla');

  // ── Timer widget ──

  String exercisesCount(int n) => _t(
    n == 1 ? '$n exercise' : '$n exercises',
    n == 1 ? '$n exercice' : '$n exercices',
    n == 1 ? '$n ejercicio' : '$n ejercicios',
  );

  String setsCount(int n) => _t(
    n == 1 ? '$n set' : '$n sets',
    n == 1 ? '$n série' : '$n séries',
    n == 1 ? '$n serie' : '$n series',
  );

  // ── Helper ──

  String _t(String en, String fr, String es) {
    switch (localeName) {
      case 'fr':
        return fr;
      case 'es':
        return es;
      default:
        return en;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
