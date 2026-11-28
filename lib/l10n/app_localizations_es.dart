// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FitFat';

  @override
  String get tabDashboard => 'Panel';

  @override
  String get tabExercise => 'Ejercicio';

  @override
  String get tabDiet => 'Dieta';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabNotes => 'Notas';

  @override
  String get dashboardAppBar => 'Panel';

  @override
  String get dashboardTodayCalories => 'Calorías de hoy';

  @override
  String get dashboardLatestWorkout => 'Último entrenamiento';

  @override
  String get dashboardNoWorkouts => 'Aún no hay entrenamientos completados.';

  @override
  String get dashboardWelcomeTitle => 'Bienvenido a FitFat';

  @override
  String get dashboardWelcomeBody =>
      'Empieza añadiendo un ingrediente, una comida o un entrenamiento.';

  @override
  String get dashboardWelcomeActionIngredients => 'Añadir un ingrediente';

  @override
  String get dashboardWelcomeActionMeals => 'Registrar una comida';

  @override
  String get dashboardWelcomeActionWorkouts => 'Añadir un entrenamiento';

  @override
  String dashboardDurationMin(int minutes) {
    return 'Duración: $minutes min';
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
  String get dashboardGreetingMorning => 'Buenos días';

  @override
  String get dashboardGreetingAfternoon => 'Buenas tardes';

  @override
  String get dashboardGreetingEvening => 'Buenas noches';

  @override
  String get dashboardMacroCalories => 'Calorías';

  @override
  String get dashboardMacroFiber => 'Fibra';

  @override
  String get dashboardMacroProtein => 'Proteínas';

  @override
  String get dashboardMacroCarbs => 'Carbohidratos';

  @override
  String get dashboardMacroFat => 'Grasas';

  @override
  String get dashboardContinueWorkout => 'Continuar entrenamiento';

  @override
  String get dashboardOpenWorkout => 'Abrir entrenamiento';

  @override
  String get dashboardCalorieTarget => 'Objetivo calórico diario';

  @override
  String dashboardConsumedOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String dashboardMacroProgress(String consumed, String target) {
    return '$consumed / $target g';
  }

  @override
  String get dashboardWeightTrend => 'Evolución del peso';

  @override
  String get dashboardWeeklyWorkout => 'Entrenamiento semanal';

  @override
  String get dashboardVolume => 'Volumen';

  @override
  String get dashboardDaysTrained => 'Días';

  @override
  String dashboardDaysTrainedValue(int count) {
    return '$count/7';
  }

  @override
  String get dashboardHoursTrained => 'Tiempo';

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
  String get dashboardGoalsTitle => 'Objetivos';

  @override
  String get dashboardGoalsEmpty => 'No hay objetivos activos';

  @override
  String get dashboardGoalsCta => 'Objetivos';

  @override
  String get dashboardAddTitle => 'Añadir';

  @override
  String get dietAddMeal => 'Comida';

  @override
  String get dietAddRecipe => 'Receta';

  @override
  String get dietAddIngredient => 'Ingrediente';

  @override
  String get dashboardMinutes => 'Minutos';

  @override
  String get dashboardUpcomingTasks => 'Tareas próximas';

  @override
  String get dashboardNoUpcomingTasks => 'No hay tareas con hora próximas.';

  @override
  String dashboardSeeAllTasks(String count) {
    return 'Ver las $count tareas';
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
  String get exerciseListAppBar => 'Ejercicios';

  @override
  String get exerciseListManageBtn => 'Gestionar ejercicios';

  @override
  String get exerciseListSearchHint => 'Buscar ejercicios';

  @override
  String get exerciseFilterType => 'Tipo';

  @override
  String get exerciseFilterBodyPart => 'Parte del cuerpo';

  @override
  String get exerciseFilterEquipment => 'Equipamiento';

  @override
  String get exerciseFilterMuscle => 'Músculo';

  @override
  String exerciseFilterResults(int count) {
    return '$count ejercicios';
  }

  @override
  String get exerciseFilterClear => 'Borrar';

  @override
  String get exerciseFilterApply => 'Aplicar';

  @override
  String get exerciseFilterNoResults => 'Ningún ejercicio coincide';

  @override
  String get exerciseFilterSearchOptions => 'Buscar opciones';

  @override
  String get exerciseDetailTabHistory => 'Historial';

  @override
  String get exerciseDetailTabDetails => 'Detalles';

  @override
  String get emptyExercisesTitle => 'Aún no hay ejercicios';

  @override
  String get emptyExercisesBody =>
      'Crea ejercicios para planificar tus entrenamientos.';

  @override
  String get emptyExercisesCta => 'Añadir ejercicio';

  @override
  String get activeWorkoutAddExercise => 'Añadir ejercicio';

  @override
  String get activeWorkoutAddExerciseTooltip =>
      'Buscar y añadir ejercicios a este entrenamiento';

  @override
  String activeWorkoutPlannedSetsTitle(String exercise) {
    return 'Series planificadas para $exercise';
  }

  @override
  String get activeWorkoutPlannedRepsLabel => 'Repeticiones';

  @override
  String get activeWorkoutPlannedWeightLabel => 'Peso';

  @override
  String get activeWorkoutReorderSets => 'Reordenar series';

  @override
  String get activeWorkoutEditPlannedTitle => 'Editar serie planificada';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get activeWorkoutPrevExercise => 'Ejercicio anterior';

  @override
  String get activeWorkoutNextExercise => 'Ejercicio siguiente';

  @override
  String get activeWorkoutInThisWorkout => 'En este entrenamiento';

  @override
  String get activeWorkoutAllExercises => 'Todos los ejercicios';

  @override
  String get activeWorkoutSearchPrompt => 'Escribe para buscar ejercicios';

  @override
  String get activeWorkoutExerciseNotes => 'Notas';

  @override
  String get activeWorkoutExerciseInfo => 'Info del ejercicio';

  @override
  String get activeWorkoutExerciseNotesDialogTitle =>
      'Notas sobre el ejercicio';

  @override
  String get activeWorkoutExerciseNotesHint =>
      'Anota qué repetir o cambiar la próxima vez (series, peso, dificultad)…';

  @override
  String get exerciseUsedTitle => 'Ejercicio en uso';

  @override
  String exerciseUsedBody(int count) {
    return 'Utilizado en $count entrenamiento. Elimina primero el entrenamiento para quitar este ejercicio.';
  }

  @override
  String exerciseUsedBody_plural(Object count) {
    return 'Utilizado en $count entrenamientos. Elimina primero los entrenamientos para quitar este ejercicio.';
  }

  @override
  String get exerciseDetailAppBar => 'Ejercicio';

  @override
  String get exerciseDetailNotFound => 'Ejercicio no encontrado.';

  @override
  String get exerciseDetailType => 'Tipo';

  @override
  String get exerciseDetailBodyPart => 'Parte del cuerpo';

  @override
  String get exerciseDetailEquipment => 'Equipamiento';

  @override
  String get exerciseDetailPrimaryMuscle => 'Músculos principales';

  @override
  String get exerciseDetailSecondaryMuscle => 'Músculos secundarios';

  @override
  String get exerciseDetailInstructions => 'Instrucciones';

  @override
  String get exerciseDetailTips => 'Consejos';

  @override
  String get exerciseDetailFaqs => 'Preguntas frecuentes';

  @override
  String get exerciseDetailKeywords => 'Palabras clave';

  @override
  String get exerciseDetailHistory => 'Historial';

  @override
  String get exerciseDetailHistoryEmpty =>
      'Sin historial. Añade este ejercicio a un entrenamiento para ver tus estadísticas.';

  @override
  String get exerciseDetailBestWeight => 'Peso máximo';

  @override
  String get exerciseDetailBestVolume => 'Mejor volumen';

  @override
  String get exerciseDetailBestDuration => 'Duración máxima';

  @override
  String get exerciseDetailTotalWorkouts => 'Entrenamientos';

  @override
  String get exerciseDetailTotalSets => 'Series';

  @override
  String get exerciseDetailVolumeOverTime => 'Volumen a lo largo del tiempo';

  @override
  String get exerciseDetailDurationOverTime => 'Duración a lo largo del tiempo';

  @override
  String get exerciseDetailPlannedVsActual => 'Planificado vs real';

  @override
  String get exerciseDetailVolumeAdherence => 'Adherencia al volumen';

  @override
  String get exerciseDetailSetsCompleted => 'Series completadas';

  @override
  String exerciseDetailAdherenceValue(String percent) {
    return '$percent%';
  }

  @override
  String exerciseDetailSetNumber(int number) {
    return 'Serie $number';
  }

  @override
  String get exerciseDetailSetCompleted => 'Completada';

  @override
  String get exerciseDetailSetNotCompleted => 'No completada';

  @override
  String get exerciseDetailSetEmpty => '—';

  @override
  String exerciseDetailRepsDelta(String delta) {
    return '$delta rep.';
  }

  @override
  String exerciseDetailWeightDelta(String delta, String unit) {
    return '$delta $unit';
  }

  @override
  String exerciseDetailSetRest(String rest) {
    return 'descanso $rest';
  }

  @override
  String exerciseDetailSetRestTook(String rest) {
    return '(tomó $rest)';
  }

  @override
  String get exerciseDetailTrendSame => 'igual que el entrenamiento anterior';

  @override
  String exerciseDetailTrendDelta(String delta, String unit) {
    return '$delta $unit vs el entrenamiento anterior';
  }

  @override
  String get exerciseDetailPrBadge => 'Récord';

  @override
  String get exerciseDetailSetHeader => 'Serie';

  @override
  String get exerciseDetailSetHeaderPlanned => 'Planificado';

  @override
  String get exerciseDetailSetHeaderActual => 'Real';

  @override
  String get exerciseDetailSetHeaderDelta => 'Δ';

  @override
  String get exerciseDetailSetHeaderRest => 'Descanso';

  @override
  String get exerciseDetailWeightTrend => 'Peso máximo con el tiempo';

  @override
  String get exerciseDetailRepsTrend => 'Repeticiones con el tiempo';

  @override
  String get exerciseFormNewTitle => 'Nuevo ejercicio';

  @override
  String get exerciseFormEditTitle => 'Editar ejercicio';

  @override
  String get exerciseFormNameLabel => 'Nombre del ejercicio';

  @override
  String get exerciseFormNameHint => 'Ej.: Press de banca';

  @override
  String get exerciseFormNameRequired => 'El nombre es obligatorio';

  @override
  String get exerciseFormTypeLabel => 'Tipo';

  @override
  String get exerciseFormMetLabel => 'Gasto energético (MET, opcional)';

  @override
  String get exerciseFormMetHelper =>
      'Se usa para estimar las calorías. Caminar es unos 3,5; correr, unos 8. Elige un valor predefinido o déjalo vacío.';

  @override
  String get exerciseFormMetInvalid => 'Introduce un número del 1 al 25';

  @override
  String get metPresetSkating => 'Patinar';

  @override
  String get metPresetCycling => 'Ciclismo';

  @override
  String get metPresetSwimming => 'Natación';

  @override
  String get metPresetHiking => 'Senderismo';

  @override
  String get metPresetFootball => 'Fútbol';

  @override
  String get exerciseFormSave => 'Guardar';

  @override
  String get exerciseFormSaving => 'Guardando…';

  @override
  String get workoutListAppBar => 'Entrenamientos';

  @override
  String get templatesTitle => 'Plantillas';

  @override
  String get templatesEmptyTitle => 'Aún no hay plantillas';

  @override
  String get templatesEmptyBody =>
      'Crea una rutina reutilizable o guarda un entrenamiento pasado como plantilla.';

  @override
  String get templatesNew => 'Nueva plantilla';

  @override
  String get templatesEdit => 'Editar plantilla';

  @override
  String get templatesStartToday => 'Empezar hoy';

  @override
  String templatesExercisesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
      zero: 'Sin ejercicios',
    );
    return '$_temp0';
  }

  @override
  String get templatesScheduleOff => 'Sin programar';

  @override
  String get templatesScheduleDaily => 'Todos los días';

  @override
  String templatesScheduleWeekly(Object days) {
    return 'Semanal: $days';
  }

  @override
  String templatesScheduleInterval(Object days) {
    return 'Cada $days días';
  }

  @override
  String get templatesDeleteConfirmTitle => '¿Eliminar plantilla?';

  @override
  String get templatesDeleteConfirmBody =>
      'Se eliminará el esquema. Las sesiones ya iniciadas se conservan.';

  @override
  String get templatesAddSet => 'Añadir serie';

  @override
  String get workoutListManageBtn => 'Gestionar ejercicios';

  @override
  String get emptyWorkoutsTitle => 'Aún no hay entrenamientos';

  @override
  String get emptyWorkoutsBody =>
      'Planifica tu primer entrenamiento y empieza a entrenar.';

  @override
  String get emptyWorkoutsCta => 'Añadir entrenamiento';

  @override
  String workoutDeleted(String name) {
    return 'Entrenamiento «$name» eliminado';
  }

  @override
  String get workoutFormTitle => 'Nuevo entrenamiento';

  @override
  String get workoutFormEditTitle => 'Editar entrenamiento';

  @override
  String get workoutFormNameLabel => 'Nombre del entrenamiento';

  @override
  String get workoutFormNameHint => 'Ej.: Entreno matutino';

  @override
  String get workoutFormNameRequired => 'El nombre es obligatorio';

  @override
  String get workoutFormDate => 'Fecha';

  @override
  String get workoutFormAddPlannerTask => 'Añadir al planificador';

  @override
  String get workoutFormAddPlannerTaskSubtitle =>
      'Crea una tarea \"hacer este entrenamiento\" en el planificador para esta fecha.';

  @override
  String get workoutFormExercises => 'Ejercicios';

  @override
  String get workoutFormAddExercise => 'Añadir ejercicio';

  @override
  String get workoutFormRemoveSet => 'Eliminar serie';

  @override
  String get workoutFormReorderExercises => 'Reordenar ejercicios';

  @override
  String get workoutFormNoExercises =>
      'No hay ejercicios disponibles. Añada algunos primero.';

  @override
  String get workoutFormSave => 'Guardar';

  @override
  String get workoutFormSaving => 'Guardando…';

  @override
  String get workoutFormAddSet => 'Añadir serie';

  @override
  String get workoutFormRepsLabel => 'Repeticiones';

  @override
  String get workoutFormWeightLabel => 'kg';

  @override
  String get workoutFormDurationLabel => 'min';

  @override
  String get workoutFormDistanceLabel => 'Distancia (m)';

  @override
  String get workoutFormSelectExercise => 'Seleccione al menos un ejercicio';

  @override
  String get workoutFormSearchHint => 'Buscar ejercicios';

  @override
  String get workoutFormRestLabel => 'Descanso (min)';

  @override
  String get workoutFormSetDoneAt => 'Hecha a las';

  @override
  String get workoutFormSetDoneAtTooltip =>
      'Cuándo terminó esta serie: el descanso se mide desde aquí';

  @override
  String get workoutFormSetTimeEmpty => 'Hora de la serie';

  @override
  String get workoutFormSetIncomplete =>
      'Completa los valores de cada serie añadida o elimínala';

  @override
  String get cardioAddDistance => 'Añadir distancia';

  @override
  String get workoutFormRemoveExercise => 'Quitar ejercicio';

  @override
  String workoutFormCreateExercise(Object query) {
    return 'Crear ejercicio «$query»';
  }

  @override
  String get workoutDetailAppBar => 'Entrenamiento';

  @override
  String get workoutDetailNotFound => 'Entrenamiento no encontrado';

  @override
  String get workoutDetailBtnStart => 'Iniciar';

  @override
  String get workoutDetailBtnComplete => 'Completar';

  @override
  String workoutDetailStartedAt(String time) {
    return 'Inicio: $time';
  }

  @override
  String get workoutDetailExercises => 'Ejercicios';

  @override
  String get emptyWorkoutDetailTitle =>
      'Este entrenamiento no tiene ejercicios';

  @override
  String get emptyWorkoutDetailBody =>
      'Añade ejercicios al crear un entrenamiento.';

  @override
  String get workoutDetailSetHeaderActual => 'Real';

  @override
  String workoutDetailSetChipRest(String planned, String rest) {
    return '$planned · $rest';
  }

  @override
  String workoutDetailSetActualsTitle(int number) {
    return 'Serie $number — Real';
  }

  @override
  String get workoutDetailActualRepsLabel => 'Repeticiones reales';

  @override
  String get workoutDetailActualWeightLabel => 'Peso real (kg)';

  @override
  String workoutDetailActualWeightLabelUnit(String unit) {
    return 'Peso real ($unit)';
  }

  @override
  String get workoutDetailActualDurationLabel => 'Duración (min)';

  @override
  String get workoutDetailActualDistanceLabel => 'Distancia (m)';

  @override
  String workoutDetailSetCount(int count) {
    return '$count serie';
  }

  @override
  String workoutDetailSetCount_plural(Object count) {
    return '$count series';
  }

  @override
  String get ingredientListAppBar => 'Ingredientes';

  @override
  String get emptyIngredientsTitle => 'Aún no hay ingredientes';

  @override
  String get emptyIngredientsBody =>
      'Añade tu primer ingrediente para empezar a crear comidas.';

  @override
  String get emptyIngredientsCta => 'Añadir ingrediente';

  @override
  String ingredientArchived(String name) {
    return 'Ingrediente «$name» archivado';
  }

  @override
  String get ingredientFormNewTitle => 'Nuevo ingrediente';

  @override
  String get ingredientFormEditTitle => 'Editar ingrediente';

  @override
  String get ingredientFormNameLabel => 'Nombre';

  @override
  String get ingredientFormNameHint => 'Ej.: Pechuga de pollo';

  @override
  String get ingredientFormNameRequired => 'El nombre es obligatorio';

  @override
  String get ingredientFormCaloriesLabel => 'Calorías (por 100 g)';

  @override
  String get ingredientFormCaloriesSuffix => 'kcal';

  @override
  String get ingredientFormProteinLabel => 'Proteínas (por 100 g)';

  @override
  String get ingredientFormProteinSuffix => 'g';

  @override
  String get ingredientFormCarbsLabel => 'Carbohidratos (por 100 g)';

  @override
  String get ingredientFormCarbsSuffix => 'g';

  @override
  String get ingredientFormFatLabel => 'Grasas (por 100 g)';

  @override
  String get ingredientFormFatSuffix => 'g';

  @override
  String get ingredientFormSodiumLabel => 'Sodio (por 100 g)';

  @override
  String get ingredientFormSodiumSuffix => 'g';

  @override
  String get ingredientFormFiberLabel => 'Fibra (por 100 g)';

  @override
  String get ingredientFormFiberSuffix => 'g';

  @override
  String get ingredientFormSugarLabel => 'Azúcar (por 100 g)';

  @override
  String get ingredientFormSugarSuffix => 'g';

  @override
  String ingredientFormFieldRequired(String label) {
    return '$label es obligatorio';
  }

  @override
  String ingredientFormFieldPositive(String label) {
    return '$label debe ser positivo';
  }

  @override
  String ingredientFormFieldNonNegative(String label) {
    return '$label no puede ser negativo';
  }

  @override
  String mealListUnnamedMeal(String date, String time) {
    return 'Comida · $date $time';
  }

  @override
  String get foodPickerTitle => 'Añadir alimentos';

  @override
  String get foodPickerSearchHint => 'Buscar recetas e ingredientes';

  @override
  String get foodPickerSectionRecipes => 'Recetas';

  @override
  String get foodPickerSectionIngredients => 'Ingredientes sueltos';

  @override
  String get foodPickerEmpty => 'Nada coincide con su búsqueda.';

  @override
  String get foodPickerNoFoods =>
      'Aún no hay alimentos. Añada un ingrediente para empezar: cada ingrediente se puede registrar por separado.';

  @override
  String foodPickerNeedsAmount(String name) {
    return '$name necesita una cantidad antes de guardar';
  }

  @override
  String foodPickerCaloriesCooked(String portion, String per100g) {
    return '$portion kcal para esta porción · $per100g/100g cocinados';
  }

  @override
  String mealListTotals(
    String amount,
    String protein,
    String carbs,
    String fat,
    String fiber,
  ) {
    return '$amount g  ·  P $protein  ·  C $carbs  ·  F $fat  ·  Fibra $fiber';
  }

  @override
  String get foodPickerDone => 'Listo';

  @override
  String mealFormSelectedSummary(int count, String calories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos seleccionados',
      one: '1 alimento seleccionado',
      zero: 'Sin alimentos seleccionados',
    );
    return '$_temp0 · $calories kcal';
  }

  @override
  String get mealFormChooseFoods => 'Elegir alimentos';

  @override
  String get ingredientDetailOwnFoodTitle => 'Registrable por separado';

  @override
  String get ingredientDetailOwnFoodBody =>
      'Este ingrediente tiene un alimento propio, así que puede registrarlo directamente sin crear una receta. Su nutrición son los valores por 100g de arriba.';

  @override
  String get mealListAppBar => 'Comidas';

  @override
  String get mealListManageBtn => 'Gestionar ingredientes';

  @override
  String get emptyMealsTitle => 'Aún no hay comidas';

  @override
  String get emptyMealsBody =>
      'Registra tu primera comida para controlar calorías y macronutrientes.';

  @override
  String get emptyMealsCta => 'Registrar una comida';

  @override
  String get mealFormDeleteTitle => '¿Eliminar esta comida?';

  @override
  String get mealFormDeleteBody =>
      'Se quitará de tu registro y de tus totales diarios.';

  @override
  String mealDeleted(String name) {
    return 'Comida «$name» eliminada';
  }

  @override
  String mealListFoodCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos',
      one: '1 alimento',
      zero: 'sin alimentos',
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
    return '${grams}g  ·  $calories kcal  ·  P ${protein}g  ·  C ${carbs}g  ·  G ${fat}g';
  }

  @override
  String get mealFormNewTitle => 'Nueva comida';

  @override
  String get mealFormEditTitle => 'Editar comida';

  @override
  String get mealFormNameLabel => 'Nombre de la comida';

  @override
  String get mealFormNameHint => 'Opcional';

  @override
  String get mealFormNameOptionalHint =>
      'Déjelo vacío y se etiquetará por su fecha';

  @override
  String get mealFormNameRequired => 'El nombre es obligatorio';

  @override
  String get mealFormDateTime => 'Fecha y hora';

  @override
  String get mealFormIngredients => 'Ingredientes';

  @override
  String get mealFormNoIngredients =>
      'No hay ingredientes disponibles. Añada algunos primero.';

  @override
  String get mealFormAddIngredient =>
      'Añada al menos un ingrediente con gramos';

  @override
  String get foodListAppBar => 'Recetas';

  @override
  String foodListPartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredientes',
      one: '1 ingrediente',
    );
    return '$_temp0';
  }

  @override
  String get foodListUnresolved =>
      'Faltan ingredientes: no se puede calcular la nutrición';

  @override
  String foodListCookedWeight(String grams) {
    return 'Peso cocinado $grams g';
  }

  @override
  String foodListCreatedOn(String date) {
    return 'Creada el $date';
  }

  @override
  String foodArchived(String name) {
    return '$name archivada';
  }

  @override
  String get emptyFoodsTitle => 'Aún no hay recetas';

  @override
  String get emptyFoodsBody =>
      'Combine dos o más ingredientes en un alimento que pueda registrar de una vez. La nutrición se calcula a partir de los ingredientes que añada.';

  @override
  String get emptyFoodsCta => 'Crear una receta';

  @override
  String get foodFormNewTitle => 'Nueva receta';

  @override
  String get foodFormEditTitle => 'Editar receta';

  @override
  String get foodFormNameLabel => 'Nombre';

  @override
  String get foodFormNameHint => 'p. ej. Granola';

  @override
  String get foodFormNameRequired => 'El nombre es obligatorio';

  @override
  String get foodFormComposition => 'Ingredientes';

  @override
  String get foodFormCompositionHint =>
      'Las cantidades indican cuánto de cada ingrediente se incluye. Su suma es el peso del lote en crudo.';

  @override
  String get foodFormSearchPrompt => 'Busque un ingrediente para añadirlo.';

  @override
  String get foodFormNoMatches =>
      'Ningún ingrediente coincide con la búsqueda.';

  @override
  String get foodFormCookedWeightLabel => 'Peso final tras cocinar';

  @override
  String foodFormCookedWeightHint(String raw) {
    return 'Peso en crudo $raw g. Cocinar cambia el peso, no las calorías: la nutrición por 100 g se calcula con este peso.';
  }

  @override
  String get foodFormCookedWeightRequired =>
      'Introduzca el peso final (mayor que cero).';

  @override
  String foodFormCookedYield(String percent) {
    return '$percent% del peso en crudo';
  }

  @override
  String get foodFormAddPart => 'Añadir un ingrediente';

  @override
  String get foodFormNoMoreParts => 'No hay más ingredientes que añadir.';

  @override
  String get foodFormRemovePart => 'Quitar ingrediente';

  @override
  String get foodFormAmountLabel => 'Cantidad';

  @override
  String get foodFormAmountPositive =>
      'Las cantidades deben ser mayores que cero.';

  @override
  String get foodFormNeedsParts => 'Añada al menos un ingrediente';

  @override
  String get foodFormPreview => 'Nutrición por 100g';

  @override
  String get foodFormPreviewCooked => 'Nutrición por 100 g cocinados';

  @override
  String get foodFormPreviewEmpty =>
      'Añada un ingrediente para ver la nutrición.';

  @override
  String get foodFormPer100g =>
      'Calculado a partir de las cantidades anteriores.';

  @override
  String foodFormRawToCooked(String raw, String cooked) {
    return 'En crudo $raw g → cocinado $cooked g';
  }

  @override
  String foodFormBatchCalories(String calories) {
    return '$calories kcal en todo el lote';
  }

  @override
  String foodFormBatchTotal(String total) {
    return 'El lote pesa $total';
  }

  @override
  String get foodFormSave => 'Guardar receta';

  @override
  String get foodFormDuplicate => 'Nueva tanda a partir de esta receta';

  @override
  String get foodFormSaving => 'Guardando…';

  @override
  String get mealFormFoods => 'Alimentos';

  @override
  String get mealFormNoFoods =>
      'Aún no hay alimentos. Añada ingredientes primero: cada uno se convierte en un alimento que puede registrar por separado.';

  @override
  String get mealFormAddFood => 'Añada al menos un alimento con gramos';

  @override
  String get mealFormFoodUnresolved =>
      'Uno de los alimentos seleccionados tiene ingredientes que faltan, así que no se puede calcular su nutrición. Sincronice o añada esos ingredientes primero.';

  @override
  String mealFormFoodCalories(String portion, String per100g) {
    return '$portion kcal por esta porción · $per100g/100g';
  }

  @override
  String get mealFormTotals => 'Total de la comida';

  @override
  String get mealItemEditorAmountLabel => 'Cantidad';

  @override
  String get mealFormGramsLabel => 'g';

  @override
  String get mealFormSave => 'Guardar';

  @override
  String get mealFormSaving => 'Guardando…';

  @override
  String get plannerAppBar => 'Plan diario';

  @override
  String get plannerToday => 'Hoy';

  @override
  String get plannerPreviousDay => 'Día anterior';

  @override
  String get plannerNextDay => 'Día siguiente';

  @override
  String get plannerAnytime => 'En cualquier momento';

  @override
  String get plannerTimelineScheduled => 'Programado';

  @override
  String get emptyPlannerTitle => 'No hay tareas para este día';

  @override
  String get emptyPlannerBody => 'Añade una tarea para planificar tu rutina.';

  @override
  String get emptyPlannerCta => 'Añadir tarea';

  @override
  String get plannerTaskLabel => 'Tarea';

  @override
  String get plannerTaskHint => 'Ej.: Correr por la mañana';

  @override
  String get plannerTaskRequired => 'El título es obligatorio';

  @override
  String get plannerTagsLabel => 'Etiquetas';

  @override
  String get plannerTagsHint =>
      'Añade una etiqueta y pulsa + (p. ej. Trabajo, Recado)';

  @override
  String get plannerTagsAdd => 'Añadir etiqueta';

  @override
  String get plannerNotesLabel => 'Notas';

  @override
  String get plannerWorkoutLabel => 'Entrenamiento (opcional)';

  @override
  String get plannerWorkoutHint => 'Vincular un entrenamiento';

  @override
  String get plannerWorkoutNone => 'Ningún entrenamiento';

  @override
  String get plannerLinkedWorkout => 'Abrir entrenamiento vinculado';

  @override
  String get plannerDueDateNone => 'Sin fecha límite';

  @override
  String get plannerDueDateClear => 'Borrar fecha límite';

  @override
  String get plannerDueTimeNone => 'Sin hora';

  @override
  String get plannerDueTimeClear => 'Borrar hora';

  @override
  String get plannerStartTimeLabel => 'Hora de inicio';

  @override
  String get plannerEndTimeLabel => 'Hora de fin';

  @override
  String get plannerStartTimeNone => 'Sin hora de inicio';

  @override
  String get plannerEndTimeNone => 'Sin hora de fin';

  @override
  String get plannerStartTimeClear => 'Borrar hora de inicio';

  @override
  String get plannerEndTimeClear => 'Borrar hora de fin';

  @override
  String get plannerRepeatInvalid => 'Revisa la configuración de repetición';

  @override
  String get plannerAddTask => 'Nueva tarea';

  @override
  String get plannerEditTask => 'Editar tarea';

  @override
  String get plannerEditScopeTitle => 'Alcance de edición';

  @override
  String get plannerDeleteScopeTitle => 'Alcance de eliminación';

  @override
  String get plannerScopeBody => 'Esta tarea se repite. ¿Cómo desea proceder?';

  @override
  String get plannerScopeThis => 'Solo esta';

  @override
  String get plannerScopeFollowing => 'Esta y todas las siguientes';

  @override
  String plannerDeleted(String title) {
    return 'Tarea «$title» eliminada';
  }

  @override
  String plannerCancelled(String title) {
    return 'Tarea «$title» cancelada';
  }

  @override
  String get plannerCopyPrevious => 'Copiar desde ayer';

  @override
  String get plannerMoreActions => 'Más acciones';

  @override
  String get plannerTaskCancelled => 'Cancelada';

  @override
  String get plannerActionMarkDone => 'Marcar hecha';

  @override
  String get plannerActionCancelTask => 'Marcar cancelada';

  @override
  String get plannerActionReopen => 'Reabrir';

  @override
  String get plannerCarryOverLabel => 'Arrastrar si no se completa';

  @override
  String get plannerCarryOverHelp =>
      'Si el día termina y esta tarea no está hecha, pasa a hoy. Desactívalo para marcarla como cancelada.';

  @override
  String get plannerTaskDetailAppBar => 'Detalles de la tarea';

  @override
  String plannerDetailUpdatedAt(String date) {
    return 'Creada el $date';
  }

  @override
  String plannerDetailDueDate(String date) {
    return 'Vence el $date';
  }

  @override
  String plannerDetailTimeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get plannerDetailNotes => 'Notas';

  @override
  String get plannerDetailTags => 'Etiquetas';

  @override
  String get plannerDetailRepeats => 'Repetición';

  @override
  String get plannerDetailLinkedWorkout => 'Entrenamiento vinculado';

  @override
  String get plannerDetailEdit => 'Editar tarea';

  @override
  String get plannerDetailDelete => 'Eliminar tarea';

  @override
  String get plannerDetailDeleteTitle => '¿Eliminar tarea?';

  @override
  String plannerDetailDeleteBody(String title) {
    return 'Esto elimina la tarea \"$title\".';
  }

  @override
  String get plannerRepeatSummaryDaily => 'Todos los días';

  @override
  String plannerRepeatSummaryWeekly(String days) {
    return 'Cada semana los $days';
  }

  @override
  String plannerRepeatSummaryInterval(int count) {
    return 'Cada $count días';
  }

  @override
  String plannerRepeatSummaryMonthly(int day) {
    return 'Mensual el día $day';
  }

  @override
  String plannerRepeatSummaryEndsDate(String date) {
    return ' · hasta el $date';
  }

  @override
  String plannerRepeatSummaryEndsCount(int count) {
    return ' · $count apariciones';
  }

  @override
  String get plannerCopyConfirmTitle => '¿Copiar tareas pendientes?';

  @override
  String plannerCopyConfirmBody(int count) {
    return '$count tarea pendiente de ayer se copiará hoy.';
  }

  @override
  String plannerCopyConfirmBody_plural(Object count) {
    return '$count tareas pendientes de ayer se copiarán hoy.';
  }

  @override
  String get plannerRepeatLabel => 'Repetir';

  @override
  String get plannerRepeatNone => 'No se repite';

  @override
  String get plannerRepeatDaily => 'Diariamente';

  @override
  String get plannerRepeatWeekly => 'Semanalmente';

  @override
  String get plannerRepeatInterval => 'Cada N días';

  @override
  String get plannerRepeatMonthly => 'Mensualmente';

  @override
  String get plannerRepeatWeekdays => 'Repetir el';

  @override
  String get plannerRepeatEvery => 'Cada';

  @override
  String get plannerRepeatDays => 'días';

  @override
  String get plannerRepeatMonthDay => 'Día del mes';

  @override
  String get plannerRepeatEnds => 'Termina';

  @override
  String get plannerRepeatEndsNever => 'Nunca';

  @override
  String get plannerRepeatEndsOnDate => 'En la fecha';

  @override
  String get plannerRepeatEndsAfter => 'Después de';

  @override
  String get plannerRepeatOccurrences => 'veces';

  @override
  String get notesAppBar => 'Notas';

  @override
  String get notesEmptyTitle => 'Aún no hay notas';

  @override
  String get notesEmptyBody =>
      'Anota cualquier cosa que tengas en mente — rutinas, recetas, aprendizajes de un entrenamiento. Las notas son privadas de este dispositivo.';

  @override
  String get notesFab => 'Nueva nota';

  @override
  String get notesEditorNewTitle => 'Nueva nota';

  @override
  String get notesEditorEditTitle => 'Editar nota';

  @override
  String get notesTitleLabel => 'Título';

  @override
  String get notesBodyLabel => 'Nota';

  @override
  String get notesBodyPreviewTooltip => 'Vista previa';

  @override
  String get notesBodyEditTooltip => 'Editar';

  @override
  String get notesToolbarBold => 'Negrita';

  @override
  String get notesToolbarItalic => 'Cursiva';

  @override
  String get notesToolbarHeading => 'Encabezado';

  @override
  String get notesToolbarList => 'Lista';

  @override
  String get notesTitleRequired => 'El título es obligatorio';

  @override
  String get notesSave => 'Guardar';

  @override
  String get notesEditing => 'Guardando…';

  @override
  String get notesDelete => 'Eliminar nota';

  @override
  String get notesDeleteConfirmTitle => '¿Eliminar nota?';

  @override
  String notesDeleteConfirmBody(Object title) {
    return '«$title» se eliminará permanentemente. Esta acción no se puede deshacer.';
  }

  @override
  String get notesVoiceRecord => 'Añadir nota de voz';

  @override
  String notesVoiceRecording(String elapsed) {
    return 'Grabando $elapsed';
  }

  @override
  String get notesVoiceStopPlayback => 'Detener reproducción';

  @override
  String get notesVoicePlay => 'Reproducir';

  @override
  String get notesVoiceRemove => 'Eliminar nota de voz';

  @override
  String get notesVoicePermissionDenied =>
      'Se necesita permiso de micrófono para grabar notas de voz.';

  @override
  String get notesVoiceNone => 'Aún no hay notas de voz';

  @override
  String notesVoiceClipLabel(int index) {
    return 'Clip $index';
  }

  @override
  String notesVoiceCount(int count) {
    return '$count nota de voz';
  }

  @override
  String notesVoiceCount_plural(Object count) {
    return '$count notas de voz';
  }

  @override
  String get settingsAppBar => 'Ajustes';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsAgeLabel => 'Edad (años)';

  @override
  String get settingsAgeInvalid => 'Introduce una edad entre 0 y 120';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsDarkPalette => 'Paleta oscura';

  @override
  String get settingsLightPalette => 'Paleta clara';

  @override
  String get settingsPaletteDefault => 'Predeterminada';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangFr => 'Francés';

  @override
  String get settingsLangEs => 'Español';

  @override
  String get settingsLangSystem => 'Sistema';

  @override
  String get settingsProfileSubtitle => 'Edad, sexo, actividad y objetivos';

  @override
  String get settingsNotificationsSubtitle =>
      'Recordatorios de tareas y alarma de descanso';

  @override
  String get settingsAppearanceLanguage => 'Apariencia e idioma';

  @override
  String get settingsAppearanceLanguageSubtitle =>
      'Tema e idioma de la aplicación';

  @override
  String get settingsBodyWeightGoal => 'Objetivo de peso';

  @override
  String get settingsGoalLose => 'Perder peso';

  @override
  String get settingsGoalMaintain => 'Mantener peso';

  @override
  String get settingsGoalGain => 'Subir de peso';

  @override
  String get settingsGender => 'Género';

  @override
  String get settingsGenderMale => 'Hombre';

  @override
  String get settingsGenderFemale => 'Mujer';

  @override
  String get settingsActivityLevel => 'Nivel de actividad';

  @override
  String get settingsActivitySedentary => 'Sedentario';

  @override
  String get settingsActivityLight => 'Ligero';

  @override
  String get settingsActivityModerate => 'Moderado';

  @override
  String get settingsActivityActive => 'Activo';

  @override
  String get settingsActivityVeryActive => 'Muy activo';

  @override
  String get settingsTrackBodyFat => 'Registrar grasa corporal';

  @override
  String get settingsBodyFatLabel => 'Grasa corporal (%)';

  @override
  String get settingsBodyFatInvalid =>
      'Introduce un porcentaje de grasa corporal entre 0 y 70';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsPlannerNotifications => 'Recordatorios de tareas';

  @override
  String get settingsPlannerNotificationsSubtitle =>
      'Notificarme las tareas del plan con hora prevista.';

  @override
  String get settingsRestAlarmSound => 'Sonido de la alarma de descanso';

  @override
  String get settingsRestAlarmVibration => 'Vibración de la alarma de descanso';

  @override
  String get settingsData => 'Datos';

  @override
  String get settingsResetData => 'Restablecer todos los datos';

  @override
  String get settingsAdvanced => 'Avanzado';

  @override
  String get settingsAdvancedSubtitle =>
      'Horizonte del plan, ajuste de calorías, temporizadores';

  @override
  String get settingsPlannerHorizonLabel => 'Antelación del plan (días)';

  @override
  String get settingsPhasesLabel => 'Fase';

  @override
  String get settingsPhasesHelp =>
      'Tus objetivos de calorías y macronutrientes siguen la fase que elijas. Cada fase guarda su propia configuración.';

  @override
  String get settingsPhaseProteinLabel => 'Proteína (g por kg de peso)';

  @override
  String get settingsPhaseProteinHelp =>
      'El peso corporal por este número da tu objetivo diario de proteína.';

  @override
  String get settingsPhaseFatLabel => 'Grasa (% de calorías)';

  @override
  String get settingsPhaseFatHelp =>
      'Parte de tu objetivo calórico dedicada a grasa. Los carbohidratos reciben lo que quede.';

  @override
  String get settingsPhaseFiberLabel => 'Fibra (g)';

  @override
  String get settingsPhaseFiberHelp =>
      'Objetivo diario de fibra para esta fase.';

  @override
  String get settingsSetActiveGoal => 'Establecer como objetivo activo';

  @override
  String get settingsActiveGoalLabel => 'Objetivo activo';

  @override
  String get settingsMacrosExceedWarning =>
      'Proteína y grasa usan más calorías que tu objetivo, así que los carbohidratos son 0.';

  @override
  String get settingsBmrLabel => 'TMB';

  @override
  String get settingsTdeeLabel => 'TDEE';

  @override
  String get settingsEstimatedSuffix => 'estimado';

  @override
  String get settingsCalorieAdjustmentLabel =>
      'Ajuste del objetivo calórico (kcal)';

  @override
  String get settingsDefaultRestLabel =>
      'Descanso por defecto entre series (min)';

  @override
  String get settingsReminderLeadLabel =>
      'Antelación del recordatorio previo (min)';

  @override
  String get settingsUntimedReminderLabel => 'Valor por defecto sin hora (min)';

  @override
  String get settingsApiTimeoutLabel =>
      'Tiempo de espera de sincronización (s)';

  @override
  String get settingsPlannerHorizonHelp =>
      'Cuántos días por adelantado se crean las tareas recurrentes en el plan.';

  @override
  String get settingsCalorieAdjustmentHelp =>
      'Kcal que se suman al objetivo diario de esta fase. Negativo crea un déficit, positivo un excedente.';

  @override
  String get settingsDefaultRestHelp =>
      'Rellena el campo de descanso al añadir una serie nueva. Déjalo vacío para no usar ninguno.';

  @override
  String get settingsReminderLeadHelp =>
      'Minutos antes de la hora de inicio de una tarea en que salta la notificación previa.';

  @override
  String get settingsUntimedReminderHelp =>
      'Hora de los recordatorios de tareas sin hora, en minutos tras la medianoche (540 = 09:00).';

  @override
  String get settingsApiTimeoutHelp =>
      'Cuánto esperan las peticiones de sincronización al servidor antes de rendirse.';

  @override
  String get settingsValueInvalid => 'Introduce un número válido no negativo.';

  @override
  String get settingsResetDataSubtitle =>
      'Borra todos los entrenamientos, comidas, mediciones, tareas del plan y notas, y restablece los ajustes por defecto.';

  @override
  String get settingsResetDataConfirmTitle => '¿Restablecer todos los datos?';

  @override
  String get settingsResetDataConfirmBody =>
      'Esto elimina permanentemente todos tus datos y restablece tus ajustes. No se puede deshacer.';

  @override
  String get settingsResetDataConfirmAction => 'Eliminar todo';

  @override
  String get taskReminderDueSoon => 'Vence en 30 minutos';

  @override
  String get taskReminderDueNow => 'Vence ahora';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get exerciseTypeWeightlifting => 'Musculación';

  @override
  String get exerciseTypeCardio => 'Cardio';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAlsoDeleted => 'También se elimina';

  @override
  String commonDeleteTitle(String item) {
    return '¿Eliminar $item?';
  }

  @override
  String commonDeleted(String item) {
    return '$item eliminado';
  }

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonUndo => 'Deshacer';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get commonSearch => 'Buscar';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String errorLoadingResource(String resource, String message) {
    return 'Error al cargar $resource: $message';
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
    return '${grams}g  ·  $calories kcal  ·  P ${protein}g  ·  C ${carbs}g  ·  G ${fat}g';
  }

  @override
  String ingredientNutrientSodium(String value) {
    return 'Na ${value}g';
  }

  @override
  String ingredientNutrientFiber(String value) {
    return 'Fibra ${value}g';
  }

  @override
  String ingredientNutrientSugar(String value) {
    return 'Azúcar ${value}g';
  }

  @override
  String get ingredientFormBrandLabel => 'Marca';

  @override
  String get ingredientFormBarcodeLabel => 'Código de barras';

  @override
  String get ingredientFormScanTile => 'Escanear código de barras';

  @override
  String get ingredientFormScanning => 'Escaneando…';

  @override
  String get ingredientFormPicturesSection => 'Fotos';

  @override
  String get ingredientFormAddPicture => 'Añadir foto';

  @override
  String get ingredientDetailPricesTitle => 'Precios';

  @override
  String get ingredientDetailNoPrices => 'Aún no hay precios registrados.';

  @override
  String ingredientDetailCostPerKg(String value) {
    return '$value /kg';
  }

  @override
  String get ingredientPriceAdd => 'Añadir precio';

  @override
  String get ingredientPriceEdit => 'Editar precio';

  @override
  String get ingredientPriceStoreLabel => 'Tienda';

  @override
  String get ingredientPriceAmountLabel => 'Precio';

  @override
  String get ingredientPriceGramsLabel => 'Tamaño del paquete';

  @override
  String get ingredientPriceSourceUrlLabel => 'URL de origen (opcional)';

  @override
  String get ingredientPriceHistoryTitle => 'Historial de precios';

  @override
  String get ingredientDetailManageStores => 'Gestionar tiendas';

  @override
  String get storeManagerTitle => 'Tiendas';

  @override
  String get storeManagerEmpty =>
      'Aún no hay tiendas. Añade una para registrar precios.';

  @override
  String get storeManagerAddTile => 'Añadir tienda';

  @override
  String get storeNameLabel => 'Nombre de la tienda';

  @override
  String get storeNameRequired => 'El nombre es obligatorio';

  @override
  String get settingsFxAutoRefresh => 'Actualización automática de tasas';

  @override
  String get settingsFxAutoRefreshSubtitle =>
      'Obtiene las tasas de cambio en segundo plano';

  @override
  String get settingsFxRefreshInterval => 'Intervalo de actualización';

  @override
  String get settingsSyncServer => 'Servidor de sincronización';

  @override
  String get settingsSyncServerHint =>
      'Apunta esto a tu servidor de sincronización para obtener ejercicios, ingredientes y divisas. Déjalo vacío para desactivar la sincronización.';

  @override
  String get syncExercisesTooltip => 'Sincronizar ejercicios';

  @override
  String get syncIngredientsTooltip => 'Sincronizar ingredientes';

  @override
  String get syncPushIngredientTooltip => 'Publicar en el catálogo compartido';

  @override
  String get syncServerNotConfigured =>
      'La URL del servidor de sincronización no está configurada';

  @override
  String get syncAll => 'Sincronizar todo';

  @override
  String get syncSelect => 'Seleccionar…';

  @override
  String get selectServerExercises => 'Seleccionar ejercicios del servidor';

  @override
  String get exerciseImportFromServer => 'Importar del servidor…';

  @override
  String get exerciseRemoveFromPhone => 'Quitar del teléfono…';

  @override
  String get exerciseRemoveTitle => 'Quitar del teléfono';

  @override
  String get exerciseRemoveNothing =>
      'Nada que quitar: todos los ejercicios se usan en un entrenamiento o plantilla.';

  @override
  String get exerciseRemoveUnused => 'Quitar ejercicios sin usar';

  @override
  String exerciseRemoveUnusedConfirm(int count) {
    return '¿Quitar $count ejercicios que no has usado en ningún entrenamiento ni plantilla? Siguen en el servidor y puedes volver a importarlos.';
  }

  @override
  String get exerciseUsedInTemplate =>
      'Se usa en una plantilla de entrenamiento. Quítalo primero de la plantilla.';

  @override
  String exerciseRemovedCount(int count) {
    return 'Quitados del teléfono: $count. Siguen en el servidor.';
  }

  @override
  String get selectServerIngredients => 'Seleccionar ingredientes del servidor';

  @override
  String get syncNothingNew =>
      'Nada nuevo en el servidor — todo ya está importado';

  @override
  String get ingredientListSearchHint => 'Buscar ingredientes';

  @override
  String get refreshList => 'Actualizar la lista';

  @override
  String get syncServerUnreachable =>
      'Servidor inalcanzable — comprueba la URL/clave o aumenta el tiempo de espera en Ajustes';

  @override
  String get pushAllDataTooltip =>
      'Sube todos los datos locales al servidor (unidireccional)';

  @override
  String get exportServerTooltip =>
      'Sube una copia de seguridad completa de tus datos locales al servidor';

  @override
  String get importServerTooltip =>
      'Reemplaza tus datos locales con la copia del servidor';

  @override
  String get importFailed => 'Error al importar';

  @override
  String get exportFailed => 'Error al exportar';

  @override
  String get settingsPlanner => 'Planificador';

  @override
  String get settingsPlannerSubtitle => 'Entrenamientos, tareas y metas';

  @override
  String get settingsNutrition => 'Nutrición';

  @override
  String get settingsNutritionSubtitle => 'Unidades y objetivos calóricos';

  @override
  String get settingsBudgetCurrencySubtitle => 'Divisa base y tipos de cambio';

  @override
  String get settingsUnits => 'Unidades';

  @override
  String get settingsWeightUnitLabel => 'Peso';

  @override
  String get settingsLengthUnitLabel => 'Altura';

  @override
  String get settingsExportDb => 'Exportar copia de seguridad';

  @override
  String get settingsExportDbSubtitle =>
      'Comparte una copia de seguridad JSON comprimida de todos tus datos';

  @override
  String get settingsReplayPrefillLabel =>
      'Al repetir una sesión, precargar las series desde';

  @override
  String get settingsReplayPrefillActuals => 'Los valores reales anteriores';

  @override
  String get settingsReplayPrefillPlanned => 'Los valores planificados';

  @override
  String get workoutSummaryDoAgain => 'Repetir';

  @override
  String get workoutActionReplay => 'Repetir sesión';

  @override
  String get workoutActionDuplicate => 'Duplicar';

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
    return '$planned · descanso $rest';
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
  String get bodyMetricsTitle => 'Medidas corporales';

  @override
  String get bodyMetricsAddWeight => 'Añadir peso';

  @override
  String get bodyMetricsAddHeight => 'Añadir altura';

  @override
  String get bodyMetricsWeightLabel => 'Peso (kg)';

  @override
  String get bodyMetricsHeightLabel => 'Altura (cm)';

  @override
  String get bodyMetricsDialogWeightTitle => 'Nueva entrada de peso';

  @override
  String get bodyMetricsDialogHeightTitle => 'Nueva entrada de altura';

  @override
  String get bodyMetricsValueRequired => 'Introduce un valor';

  @override
  String get bodyMetricsValuePositive => 'El valor debe ser mayor que 0';

  @override
  String get bodyMetricsEmptyWeight => 'Aún no hay entradas de peso.';

  @override
  String get bodyMetricsEmptyHeight => 'Aún no hay entradas de altura.';

  @override
  String bodyMetricsLatestWeight(String value, String unit) {
    return 'Último: $value $unit';
  }

  @override
  String bodyMetricsLatestHeight(String value, String unit) {
    return 'Última: $value $unit';
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
    return 'Objetivo: $goal';
  }

  @override
  String get restTimerTitle => 'Temporizador de descanso';

  @override
  String get restTimerCancel => 'Cancelar descanso';

  @override
  String restTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get activeWorkoutElapsedLabel => 'Transcurrido';

  @override
  String get activeWorkoutRestLabel => 'Descanso';

  @override
  String get activeWorkoutResume => 'Reanudar';

  @override
  String get restAlarmTitle => 'El descanso ha terminado';

  @override
  String get restAlarmBody => 'Tu descanso planificado ha terminado.';

  @override
  String restAlarmBodyWithDuration(String duration) {
    return 'Tu descanso planificado de $duration ha terminado.';
  }

  @override
  String get workoutSummaryAppBar => 'Resumen';

  @override
  String get workoutSummaryEdit => 'Editar entrenamiento';

  @override
  String workoutSummarySetLabel(int number) {
    return 'Serie $number';
  }

  @override
  String workoutSummarySetRest(String rest) {
    return 'descanso $rest';
  }

  @override
  String get workoutSummaryDone => 'Hecho';

  @override
  String get workoutSummaryDurationLabel => 'Duración';

  @override
  String get workoutSummaryEnergyLabel => 'Energía estimada';

  @override
  String workoutSummaryEnergyValue(int kcal) {
    return '~$kcal kcal';
  }

  @override
  String workoutSummaryEnergyNotCounted(String names) {
    return 'No contabilizado: $names';
  }

  @override
  String get workoutSummaryAvgRest => 'Descanso medio';

  @override
  String get workoutSummaryVolume => 'Volumen';

  @override
  String get workoutSummaryMaxWeight => 'Peso máximo';

  @override
  String get workoutSummaryTotalReps => 'Repeticiones';

  @override
  String get workoutSummaryTotalDuration => 'Duración total';

  @override
  String get workoutSummaryTotalDistance => 'Distancia total';

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
    return 'Actualizado el $date';
  }

  @override
  String transactionRateUsed(String rate, String base, String code) {
    return 'convertido a $rate $base por $code';
  }

  @override
  String accountDeleteBlockedBody(int count) {
    return 'Esta cuenta es usada por $count transacción(es) y no puede eliminarse.';
  }

  @override
  String get accountDeleteBlockedTitle => 'Cuenta en uso';

  @override
  String accountDeleteConfirmBody(String name) {
    return 'Eliminar la cuenta \'$name\' también eliminará sus transacciones y recibos.';
  }

  @override
  String get accountDeleteConfirmTitle => '¿Eliminar la cuenta?';

  @override
  String get accountFormEditTitle => 'Editar cuenta';

  @override
  String get accountFormNameLabel => 'Nombre';

  @override
  String get accountFormNameRequired => 'Escribe un nombre';

  @override
  String get accountFormNewTitle => 'Nueva cuenta';

  @override
  String get accountFormOpeningHelper =>
      'Importe ya presente en esta cuenta cuando empezaste a registrarla. Deja 0 si no estás seguro.';

  @override
  String get accountFormIntro =>
      'Registra una cartera, una cuenta bancaria o una tarjeta.';

  @override
  String get accountFormNoteLabel => 'Account Form Note Label';

  @override
  String get accountFormOpeningLabel => 'Saldo inicial';

  @override
  String get accountFormTypeLabel => 'Tipo';

  @override
  String accountOpeningLabel(String value) {
    return 'Saldo inicial: $value';
  }

  @override
  String get accountReceipts => 'Recibos';

  @override
  String get accountTransactions => 'Transacciones';

  @override
  String get accountTypeBank => 'Cuenta bancaria';

  @override
  String get accountTypeCash => 'Efectivo';

  @override
  String get accountTypeCredit => 'Tarjeta de crédito';

  @override
  String get accountTypeInvestment => 'Inversión';

  @override
  String get accountTypeOther => 'Otro';

  @override
  String get accountTypeSavings => 'Ahorros';

  @override
  String get accountTypeSecurities => 'Valores';

  @override
  String get budgetAccounts => 'Cuentas';

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
  String get budgetMonthExpense => 'Gastos del mes';

  @override
  String get budgetMonthIncome => 'Ingresos del mes';

  @override
  String get budgetNoReceipts => 'Aún no hay recibos';

  @override
  String get budgetNoTransactions => 'Aún no hay transacciones';

  @override
  String budgetPendingReceipts(int count) {
    return '$count recibo(s) pendiente(s)';
  }

  @override
  String get budgetRecentTransactions => 'Transacciones recientes';

  @override
  String get budgetThisMonth => 'Budget This Month';

  @override
  String get budgetViewAll => 'Ver todo';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get receiptAppBar => 'Recibo';

  @override
  String get receiptCreateDraft => 'Crear borrador';

  @override
  String get receiptDeleteConfirmBody => '¿Eliminar este recibo?';

  @override
  String get receiptDeleteConfirmTitle => '¿Eliminar el recibo?';

  @override
  String get receiptEmptyBody =>
      'Aún no hay recibos. Toma una foto de un recibo para empezar a registrar.';

  @override
  String get receiptListAppBar => 'Recibos';

  @override
  String get receiptNotFound => 'Recibo no encontrado';

  @override
  String get receiptNotParsed => 'Aún sin analizar';

  @override
  String get receiptParsed => 'Analizado';

  @override
  String get receiptParsing => 'Analizando el recibo…';

  @override
  String get receiptParsedData => 'Datos analizados';

  @override
  String get receiptPickGallery => 'Desde la galería';

  @override
  String get receiptReviewDraft => 'Revisar borrador';

  @override
  String receiptStatusLabel(String status) {
    return '$status';
  }

  @override
  String receiptStatusShort(String status) {
    return '$status';
  }

  @override
  String get receiptTakePhoto => 'Tomar foto';

  @override
  String get receiptUpload => 'Subir';

  @override
  String get settingsCurrencyBudget => 'Moneda del presupuesto';

  @override
  String get settingsFxRates => 'Tasas de cambio';

  @override
  String get settingsFxRatesEmpty => 'No hay tasas de cambio configuradas';

  @override
  String get settingsFxRefresh => 'Actualizar tasas';

  @override
  String get transactionAmountInvalid => 'Escribe un importe válido';

  @override
  String get transactionCategoryLabel => 'Categoría';

  @override
  String transactionConvertedLabel(String amount) {
    return '≈ $amount en moneda base';
  }

  @override
  String get transactionDraft => 'Borrador';

  @override
  String get transactionDraftHint =>
      'Borrador de un recibo escaneado: revisa los datos antes de guardar';

  @override
  String get transactionHasReceipt => 'Recibo adjunto';

  @override
  String get transactionListAppBar => 'Transacciones';

  @override
  String get transactionTypeExpense => 'Gasto';

  @override
  String get transactionTypeIncome => 'Ingreso';

  @override
  String get transactionTypeTransfer => 'Transferencia';

  @override
  String get budgetAppBar => 'Presupuesto';

  @override
  String get budgetSubtitle => 'Cuentas, transacciones y recibos';

  @override
  String get budgetTotalBalance => 'Saldo total';

  @override
  String get budgetNetWorth => 'Patrimonio neto';

  @override
  String get budgetIncomeLabel => 'Ingresos';

  @override
  String get budgetExpenseLabel => 'Gastos';

  @override
  String get budgetEmptyAccounts =>
      'Aún no hay cuentas. Vienen del servidor: descarga Budget en Sync.';

  @override
  String get budgetAddAccount => 'Agregar cuenta';

  @override
  String get budgetAddTransaction => 'Agregar transacción';

  @override
  String get accountFormTitleNew => 'Nueva cuenta';

  @override
  String get accountFormTitleEdit => 'Editar cuenta';

  @override
  String get accountNameLabel => 'Nombre';

  @override
  String get accountTypeLabel => 'Tipo';

  @override
  String get accountCurrencyLabel => 'Moneda';

  @override
  String get accountInitialBalanceLabel => 'Saldo inicial';

  @override
  String get accountSave => 'Guardar';

  @override
  String get accountDetailTitle => 'Cuenta';

  @override
  String get accountDelete => 'Eliminar cuenta';

  @override
  String get accountTransactionsTitle => 'Transacciones';

  @override
  String get accountBalanceLabel => 'Saldo';

  @override
  String get accountEdit => 'Editar';

  @override
  String get transactionFormNewExpenseTitle => 'Nuevo gasto';

  @override
  String get transactionFormNewIncomeTitle => 'Nuevo ingreso';

  @override
  String get transactionFormTransferTitle => 'Transferencia';

  @override
  String get transactionFormEditTitle => 'Editar transacción';

  @override
  String get transactionTypeLabel => 'Tipo';

  @override
  String get transactionAmountLabel => 'Monto';

  @override
  String get transactionCurrencyLabel => 'Moneda';

  @override
  String get transactionDateLabel => 'Fecha';

  @override
  String get transactionNoteLabel => 'Nota';

  @override
  String get transactionAccountLabel => 'Cuenta';

  @override
  String get transactionToAccountLabel => 'A la cuenta';

  @override
  String get transactionReceiptLabel => 'Recibo';

  @override
  String get transactionSave => 'Guardar';

  @override
  String get transactionDelete => 'Eliminar';

  @override
  String get transactionDraftBadge => 'Borrador';

  @override
  String get transactionConfirmDraft => 'Confirmar';

  @override
  String get transactionTransferSameAccount =>
      'La transferencia requiere dos cuentas distintas.';

  @override
  String get transactionAccountRequired => 'Se requiere una cuenta.';

  @override
  String get transactionTransferAccountsRequired =>
      'Ambas cuentas son requeridas para una transferencia.';

  @override
  String get transactionAmountPositive => 'El monto debe ser mayor que cero.';

  @override
  String get receiptListTitle => 'Recibos';

  @override
  String get receiptCapture => 'Capturar recibo';

  @override
  String get receiptCaptureStandalone => 'Recibo independiente';

  @override
  String get receiptUploadError => 'Error al enviar el recibo';

  @override
  String get receiptViewTitle => 'Recibo';

  @override
  String get receiptStatusLocal => 'Local';

  @override
  String get receiptStatusUploading => 'Enviando';

  @override
  String get receiptStatusUploaded => 'Enviado';

  @override
  String get receiptStatusError => 'Error';

  @override
  String get receiptAttach => 'Adjuntar a la transacción';

  @override
  String get receiptChooseSource => 'Elegir origen';

  @override
  String get receiptFromCamera => 'Cámara';

  @override
  String get receiptFromGallery => 'Galería';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get settingsBaseCurrency => 'Moneda base';

  @override
  String get settingsCategoryFx => 'Tipos de cambio';

  @override
  String get settingsRefreshRates => 'Actualizar tasas';

  @override
  String get settingsEditRate => 'Editar tasa';

  @override
  String settingsRateBase(Object base) {
    return 'Por 1 $base';
  }

  @override
  String get settingsRateInvalid => 'Ingrese una tasa positiva.';

  @override
  String get tabBudget => 'Presupuesto';

  @override
  String get plannerViewDay => 'Vista de día';

  @override
  String get plannerViewWeek => 'Vista semanal';

  @override
  String get plannerViewMonth => 'Vista mensual';

  @override
  String get plannerGoToday => 'Ir a hoy';

  @override
  String get goalLinkTask => 'Vincular tarea';

  @override
  String get goalUnlinkTask => 'Desvincular tarea';

  @override
  String get goalSearchTasksHint => 'Buscar tareas…';

  @override
  String get linkGoal => 'Vincular meta';

  @override
  String get unlinkGoal => 'Desvincular meta';

  @override
  String get linkNote => 'Vincular nota';

  @override
  String get unlinkNote => 'Desvincular nota';

  @override
  String get plannerViewGoals => 'Vista de metas';

  @override
  String get plannerModeTimeline => 'Cronología';

  @override
  String get plannerModeInitiatives => 'Iniciativas';

  @override
  String get prioritiesTitle => 'Tags';

  @override
  String get prioritiesManage => 'Gestionar tags';

  @override
  String get prioritiesAdd => 'Añadir tag';

  @override
  String get prioritiesRename => 'Renombrar tag';

  @override
  String get prioritiesNameLabel => 'Nombre';

  @override
  String get prioritiesNameRequired => 'Introduce un nombre';

  @override
  String get prioritiesAlreadyExists => 'Ya existe un tag con este nombre.';

  @override
  String get prioritiesColor => 'Color';

  @override
  String get prioritiesDeleteConfirmTitle => '¿Eliminar tag?';

  @override
  String prioritiesDeleteConfirmBody(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      zero: 'ningún elemento',
    );
    return '«$name» se quitará de $_temp0.';
  }

  @override
  String get prioritiesEmpty =>
      'Aún no hay tags. Crea uno para organizar tus metas, tareas y notas.';

  @override
  String prioritiesUsageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
      zero: 'sin uso',
    );
    return '$_temp0';
  }

  @override
  String get tagsFilterAll => 'Todos';

  @override
  String get initiativesEmptyAllTitle => 'Aún no hay metas';

  @override
  String get initiativesEmptyAll => 'Crea una meta a lograr.';

  @override
  String get initiativesEmptyFilterTitle => 'No hay iniciativas que coincidan';

  @override
  String get initiativesEmptyFilter =>
      'Ninguna meta lleva los tags seleccionados.';

  @override
  String get goalsNew => 'Nueva meta';

  @override
  String get goalsEdit => 'Editar meta';

  @override
  String get goalsMissing => 'Meta no encontrada.';

  @override
  String get goalsFormTitleLabel => 'Meta';

  @override
  String get goalsFormTitleHint => 'p. ej. Correr una carrera de 10k';

  @override
  String get goalsFormTitleRequired => 'Introduce una meta';

  @override
  String get goalsFormDescriptionLabel => 'Descripción';

  @override
  String get goalsFormStartLabel => 'Fecha de inicio';

  @override
  String get goalsFormEndLabel => 'Fecha objetivo (opcional)';

  @override
  String get goalsNoEndDate => 'Sin fecha límite';

  @override
  String get goalsFormStatusLabel => 'Estado';

  @override
  String get goalsStatusPlanned => 'Planificada';

  @override
  String get goalsStatusActive => 'Activa';

  @override
  String get goalsStatusDone => 'Completada';

  @override
  String get goalsStatusAborted => 'Abandonada';

  @override
  String get goalsTargetTypeLabel => 'Objetivo';

  @override
  String get goalsTargetTypeNone => 'Ninguno';

  @override
  String get goalsTargetTypeNumeric => 'Numérico';

  @override
  String get goalsTargetTypeBoolean => 'Logro';

  @override
  String get goalsTargetValueLabel => 'Valor objetivo';

  @override
  String get goalsTargetValueInvalid => 'Introduce un número';

  @override
  String get goalsUnitLabel => 'Unidad';

  @override
  String get goalsBaselineLabel => 'Valor inicial';

  @override
  String get goalsReminderLabel => 'Recordatorio diario de la meta';

  @override
  String get goalsReminderSubtitle =>
      'Una notificación mantiene esta meta presente.';

  @override
  String get goalsReminderTimeLabel => 'Hora del recordatorio';

  @override
  String get goalsRelatedTasks => 'Tareas relacionadas';

  @override
  String get goalsNoLinkedTasks => 'Aún no hay tareas relacionadas.';

  @override
  String get goalsDeleteConfirmTitle => '¿Eliminar meta?';

  @override
  String get goalsDeleteConfirmBody =>
      'La meta y su registro de progreso se eliminarán permanentemente.';

  @override
  String get goalsMarkActive => 'Activar';

  @override
  String get goalsMarkDone => 'Marcar completada';

  @override
  String get goalsAbort => 'Abandonar';

  @override
  String get goalsReopen => 'Reabrir';

  @override
  String get goalsProgressSection => 'Progreso';

  @override
  String get goalsRecordProgress => 'Registrar progreso';

  @override
  String get goalsCurrentValueLabel => 'Actual';

  @override
  String get goalsTargetLabel => 'Objetivo';

  @override
  String get goalsAchievedQuestion => '¿Logrado? (1 = sí)';

  @override
  String get goalsAchieved => 'Lograda';

  @override
  String get goalsNotAchieved => 'Todavía no';

  @override
  String get goalsProgressNoteHint => 'Nota (opcional)';

  @override
  String get goalsProgressDateLabel => 'Registrado el';

  @override
  String get goalsLogTitle => 'Registro';

  @override
  String get goalsNoProgressYet => 'Nada registrado todavía.';

  @override
  String get goalsEmptyAllTitle => 'Aún no hay metas';

  @override
  String get goalsEmptyAll =>
      'Define un resultado a largo plazo y vincúlalo a tus prioridades.';

  @override
  String get goalsEmptyFilterTitle => 'No hay metas aquí';

  @override
  String get goalsEmptyFilter =>
      'Ninguna meta lleva las prioridades seleccionadas.';

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
      'Al eliminar una meta, elige si también se eliminan sus tareas vinculadas.';

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
  String get receiptsNonePending => 'Nada pendiente de enviar';

  @override
  String get receiptListSentNote =>
      'Los recibos enviados se eliminan del teléfono y viven en el servidor.';

  @override
  String get receiptSendAll => 'Enviar todo';

  @override
  String get receiptSendSelected => 'Enviar seleccionados';

  @override
  String receiptSelectedCount(int count) {
    return '$count seleccionado(s)';
  }

  @override
  String receiptSendingProgress(int done, int total) {
    return 'Enviando $done de $total';
  }

  @override
  String receiptSentCount(int count) {
    return '$count enviado(s)';
  }

  @override
  String receiptFailedCount(int count) {
    return '$count fallido(s)';
  }

  @override
  String receiptNoPictureCount(int count) {
    return '$count sin imagen';
  }

  @override
  String receiptSaveFailedCount(int count) {
    return '$count no se pudo añadir';
  }

  @override
  String get receiptsNoServer =>
      'No hay servidor de sincronización configurado: los recibos se quedan en este teléfono.';

  @override
  String get receiptOpenSync => 'Abrir ajustes de sincronización';

  @override
  String get receiptStatusParsing => 'Leyendo…';

  @override
  String get syncHubTitle => 'Sincronización y copia de seguridad';

  @override
  String get syncGlobalPool => 'Fondo global';

  @override
  String get syncGlobalPoolHint =>
      'Descargar ejercicios, ingredientes y divisas compartidos';

  @override
  String get syncPersonalPool => 'Fondo personal';

  @override
  String get syncPersonalPoolHint =>
      'Enviar/descargar tus tareas, notas, objetivos, entrenamientos, plantillas, comidas, cuerpo, presupuesto';

  @override
  String get syncLocalBackup => 'Copia local';

  @override
  String get syncLocalBackupHint =>
      'Exportar a un archivo o restaurar desde un archivo';

  @override
  String syncErrorUnreachable(String url) {
    return 'No se puede contactar con el servidor en $url. Comprueba que el servidor de sincronización está en marcha en el ordenador y que el teléfono está en la misma red Wi-Fi (o configurado con adb reverse). Usa «Probar /health» arriba para reintentar.';
  }

  @override
  String get syncErrorServerTooOld =>
      'Este servidor es una versión antigua que aún no puede recibir estos datos. Actualiza el servidor de sincronización en el ordenador y vuelve a enviar.';

  @override
  String get syncErrorUnknownOperation =>
      'El servidor no reconoce esta operación de sincronización; puede que su versión sea demasiado antigua. Actualiza el servidor en el ordenador y vuelve a intentarlo.';

  @override
  String get syncErrorKeyRejected =>
      'El servidor rechazó la clave API. Revisa la clave de este servidor (elimínalo y vuelve a añadirlo o a escanear el código QR).';

  @override
  String get syncErrorTooLarge =>
      'Estos datos son demasiado grandes para que el servidor los acepte de una vez. Envía menos categorías a la vez (desmarca algunas casillas arriba).';

  @override
  String get syncErrorServerInternal =>
      'El servidor tuvo un problema interno al recibir estos datos. Su actividad reciente quedó registrada en el ordenador; revisa la consola del servidor.';

  @override
  String syncConnected(String url) {
    return '✓ Conectado ($url)';
  }

  @override
  String syncConnectionFailed(String reason) {
    return 'Error de conexión: $reason';
  }

  @override
  String get syncAddServer => 'Añadir servidor';

  @override
  String get syncServerUrl => 'URL del servidor';

  @override
  String get syncApiKey => 'Clave API';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get syncInvalidUrl => 'URL no válida';

  @override
  String get syncApiKeyRequired => 'Se requiere la clave API';

  @override
  String get syncServerExists => 'El servidor ya existe';

  @override
  String get syncServers => 'Servidores';

  @override
  String get syncServersHint =>
      'Añade varios pares de URL + clave API. Selecciona el activo para sincronizar. Mantén adb reverse + http://127.0.0.1:3030 para el punto de acceso.';

  @override
  String get syncNoServers =>
      'Aún no hay servidores; añade uno con Escanear QR o Añadir';

  @override
  String get syncRemoveServerTitle => '¿Eliminar el servidor?';

  @override
  String syncRemoveServerBody(String label) {
    return '¿Eliminar $label?';
  }

  @override
  String get syncScanQr => 'Escanear QR';

  @override
  String get syncNoActiveServer => 'No hay servidor activo';

  @override
  String get syncTestHealth => 'Probar /health';

  @override
  String get syncNever => 'nunca';

  @override
  String syncMinutesAgo(int n) {
    return 'hace $n min';
  }

  @override
  String syncHoursAgo(int n) {
    return 'hace $n h';
  }

  @override
  String syncDaysAgo(int n) {
    return 'hace $n d';
  }

  @override
  String syncLastSync(String when) {
    return 'Última sincronización: $when';
  }

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get syncSelectExercises => 'Elegir ejercicios…';

  @override
  String get syncSelectIngredients => 'Elegir ingredientes…';

  @override
  String get syncNoExercisesOnServer => 'No hay ejercicios en el servidor';

  @override
  String get syncNoIngredientsOnServer => 'No hay ingredientes en el servidor';

  @override
  String get syncSelectServerExercises => 'Elegir ejercicios del servidor';

  @override
  String get syncSearchServerExercises => 'Buscar ejercicios del servidor';

  @override
  String get syncSelectServerIngredients => 'Elegir ingredientes del servidor';

  @override
  String get syncSearchServerIngredients => 'Buscar ingredientes del servidor';

  @override
  String get syncRefreshList => 'Actualizar la lista';

  @override
  String syncCouldNotPush(String entity, String reason) {
    return 'No se pudo enviar $entity: $reason';
  }

  @override
  String syncCouldNotPull(String entity, String reason) {
    return 'No se pudo descargar $entity: $reason';
  }

  @override
  String get syncUnknownError => 'error desconocido';

  @override
  String syncPulledWithErrors(String entities) {
    return 'Descargado con errores: $entities';
  }

  @override
  String get syncRelatedExercises => 'Ejercicios (relacionados)';

  @override
  String syncPushEntity(String entity) {
    return 'Enviar $entity';
  }

  @override
  String syncPullEntity(String entity) {
    return 'Descargar $entity';
  }

  @override
  String get syncExerciseUpdates =>
      'Actualizar los ejercicios de este teléfono';

  @override
  String get syncPushAll => 'Enviar todo';

  @override
  String get syncPullAll => 'Descargar todo';

  @override
  String get syncEntityTags => 'Etiquetas';

  @override
  String get syncEntityExercises => 'Ejercicios';

  @override
  String get syncEntityTasks => 'Tareas';

  @override
  String get syncEntityNotes => 'Notas';

  @override
  String get syncEntityGoals => 'Objetivos';

  @override
  String get syncEntityWorkouts => 'Entrenamientos';

  @override
  String get syncEntityTemplates => 'Plantillas';

  @override
  String get syncEntityStores => 'Tiendas';

  @override
  String get syncEntityIngredients => 'Ingredientes';

  @override
  String get syncEntityFoods => 'Alimentos';

  @override
  String get syncEntityMeals => 'Comidas';

  @override
  String get syncEntityBody => 'Cuerpo';

  @override
  String get syncEntityBudget => 'Presupuesto';

  @override
  String get syncEntityTransactions => 'Transacciones';

  @override
  String get syncEntityReceipts => 'Recibos';

  @override
  String get syncBackupFormatHint =>
      'JSON → .json.gz (comprimido, filtrado por la selección)';

  @override
  String syncBackupGroupsSelected(int selected, int total) {
    return '$selected/$total grupos: se aplica a Exportar e Importar';
  }

  @override
  String get syncExport => 'Exportar';

  @override
  String get syncImport => 'Importar';

  @override
  String get syncSelectOneGroup => 'Selecciona al menos un grupo';

  @override
  String syncExportJson(int count) {
    return 'Exportar JSON ($count)';
  }

  @override
  String get syncImportJson => 'Importar JSON';

  @override
  String get syncServerCopy => 'Copia en el servidor';

  @override
  String get syncServerCopyHint =>
      'Subir una copia JSON comprimida o restaurar la guardada en el ordenador';

  @override
  String get syncBackUpToServer => 'Copiar al servidor';

  @override
  String get syncRestoreFromServer => 'Restaurar desde el servidor';

  @override
  String get syncReplaceLocalTitle => '¿Reemplazar los datos locales?';

  @override
  String get syncReplaceFromServerBody =>
      'La importación borrará las filas existentes de cada grupo respaldado y restaurará la copia guardada en el servidor.';

  @override
  String syncReplaceFromFileBody(String groups) {
    return 'La importación borrará las filas existentes de estos grupos y restaurará la copia: $groups.';
  }

  @override
  String get syncEntityCurrencies => 'Divisas';

  @override
  String get syncNotConfiguredOpenHub =>
      'Servidor de sincronización no configurado: abre Sincronización y copia de seguridad para definir la URL';

  @override
  String syncTimeoutWithSeconds(int seconds) {
    return 'Servidor inaccesible: revisa la URL/clave o aumenta el tiempo de espera en Ajustes → Avanzado ($seconds s)';
  }

  @override
  String get commonOpen => 'Abrir';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncNowHint => 'Envía tus cambios y luego trae los del servidor';

  @override
  String syncStep(String entity) {
    return 'Sincronizando $entity…';
  }

  @override
  String get syncYourData => 'Tus datos';

  @override
  String syncShowAll(int count) {
    return 'Ver los $count';
  }

  @override
  String get syncShowLess => 'Ver menos';

  @override
  String get syncLibraryTitle => 'Biblioteca del servidor';

  @override
  String get syncLibraryHint =>
      'Nada se descarga solo. Elige lo que quieras en este teléfono.';

  @override
  String syncOnPhoneCount(int count) {
    return '$count en este teléfono';
  }

  @override
  String get syncBrowse => 'Explorar';

  @override
  String get syncBackups => 'Copias de seguridad';

  @override
  String get syncBackupsSubtitle =>
      'Exportar archivo · copia en el servidor · restaurar';

  @override
  String get syncServerSheetTitle => 'Servidor';

  @override
  String syncStatusConnected(String server) {
    return '$server · conectado';
  }

  @override
  String syncStatusOffline(String server) {
    return '$server · no disponible';
  }

  @override
  String syncStatusChecking(String server) {
    return '$server · comprobando…';
  }

  @override
  String get syncNoServerYet => 'Aún no hay servidor';

  @override
  String get syncRescanQr => 'Volver a escanear el QR';

  @override
  String get syncRescanQrHint =>
      'Úsalo si cambió la dirección o la clave del ordenador. Sustituye la URL y la clave de este servidor.';

  @override
  String get syncRescanQrTooltip => 'Volver a escanear el QR del servidor';

  @override
  String get syncTestConnection => 'Probar conexión';

  @override
  String get syncAddServerByHand => 'Añadir un servidor a mano';

  @override
  String get syncServerUpdated => 'Servidor actualizado';

  @override
  String get syncSendToServer => 'Enviar al servidor';

  @override
  String get syncGetFromServer => 'Traer del servidor';

  @override
  String get syncRescan => 'Escanear';

  @override
  String syncCantReach(String server) {
    return 'No se puede conectar con $server';
  }

  @override
  String get syncCantReachHint =>
      'Tus datos siguen en este teléfono. Vuelve a escanear si cambió la dirección del ordenador.';

  @override
  String get syncBackup => 'Copia de seguridad';

  @override
  String get commonError => 'Error';

  @override
  String get dashboardStableTrend => 'Tendencia estable';

  @override
  String get dashboardTrendingDown => '→ tendencia a la baja';

  @override
  String get dashboardTrendingUp => '→ tendencia al alza';

  @override
  String dashboardDelta7d(String delta) {
    return '$delta (7 d)';
  }

  @override
  String dashboardDelta30d(String delta) {
    return '$delta (30 d)';
  }

  @override
  String get dashboardToday => 'Hoy';

  @override
  String get budgetRecent => 'Recientes';

  @override
  String get settingsSync => 'Sincronización';

  @override
  String get settingsSyncSubtitle =>
      'Servidores y copias: abrir Sincronización y copia de seguridad';

  @override
  String get selectSheetTitle => 'Seleccionar';

  @override
  String selectSheetCount(int count) {
    return '$count elementos';
  }

  @override
  String get selectSheetSelectAll => 'Seleccionar todo';

  @override
  String selectSheetSyncSelected(int count) {
    return 'Sincronizar selección ($count)';
  }

  @override
  String get wizardSkip => 'Omitir';

  @override
  String get wizardDone => 'Listo';

  @override
  String get ingredientOffApply => 'Aplicar al formulario';

  @override
  String get ingredientOffImport => 'Guardar en el servidor y aplicar';

  @override
  String get ingredientOffShare => 'Compartir el enlace de OpenFoodFacts';

  @override
  String get workoutStartedNoNotification =>
      'Entrenamiento iniciado, pero no se pudo mostrar la notificación. Permite las notificaciones y pon la batería en Sin restricciones.';

  @override
  String syncQrInvalid(String payload) {
    return 'QR no válido: se esperaba $payload';
  }

  @override
  String syncQrHint(String payload) {
    return 'Apunta la cámara a un QR con $payload';
  }

  @override
  String get dashboardNutrition => 'Nutrición';

  @override
  String get dashboardTasks => 'Tareas';

  @override
  String get dashboardTraining => 'Entrenamiento';

  @override
  String get dashboardWeight => 'Peso';

  @override
  String get dashboardMoney => 'Dinero';

  @override
  String dashboardKcalLeft(int count) {
    return 'quedan $count';
  }

  @override
  String dashboardKcalOver(int count) {
    return '$count de más';
  }

  @override
  String get dashboardNoMealsToday => 'Aún no has registrado nada hoy.';

  @override
  String get dashboardLogMeal => 'Registrar comida';

  @override
  String dashboardTasksDone(int done, int total) {
    return '$done de $total hechas';
  }

  @override
  String dashboardTasksMore(int count) {
    return '+$count más';
  }

  @override
  String get dashboardNoTasksToday => 'Nada planeado para hoy.';

  @override
  String get dashboardThisWeek => 'Esta semana';

  @override
  String dashboardStartedAt(String time) {
    return 'Empezado a las $time';
  }

  @override
  String get dashboardContinue => 'Continuar';

  @override
  String dashboardGoalsActive(int count) {
    return '$count activos';
  }

  @override
  String get dashboardGoalsEmptyHint =>
      'Aún no hay objetivos. Sigue un levantamiento, un ahorro o una distancia.';

  @override
  String get dashboardSetGoal => 'Crear objetivo';

  @override
  String get dashboardNoAccounts =>
      'Aún no hay cuentas. Llegan del servidor al sincronizar.';

  @override
  String get dashboardSpent => 'gastado';

  @override
  String dashboardIncome(String amount) {
    return 'Ingresos $amount';
  }

  @override
  String syncSending(String entity) {
    return 'Enviando $entity…';
  }

  @override
  String syncFetching(String entity) {
    return 'Recibiendo $entity…';
  }

  @override
  String get syncOpen => 'Abrir sincronización';

  @override
  String get settingsDashboard => 'Panel';

  @override
  String get settingsDashboardSubtitle => 'Tarjetas y su orden';

  @override
  String get settingsDashboardHint =>
      'Arrastra para reordenar. Las tarjetas desactivadas se ocultan.';

  @override
  String get settingsResetOrder => 'Restablecer';

  @override
  String get settingsSearch => 'Buscar ajustes';

  @override
  String settingsNoResults(String query) {
    return 'Ningún ajuste coincide con «$query»';
  }

  @override
  String get settingsMore => 'Más';

  @override
  String get settingsPalettes => 'Paletas';

  @override
  String get settingsGeneral => 'General';

  @override
  String get trainingTitle => 'Entrenamiento';

  @override
  String get trainingRecent => 'Recientes';

  @override
  String get trainingAll => 'Todo';

  @override
  String get trainingStart => 'Empezar';

  @override
  String get trainingStartAgain => 'Repetir';

  @override
  String get trainingNew => 'Nuevo';

  @override
  String get trainingNewWorkout => 'Nuevo entrenamiento';

  @override
  String get trainingNoWorkouts =>
      'Tus entrenamientos aparecerán aquí al terminar uno. Empieza con +.';

  @override
  String get trainingNoTemplates =>
      'Guarda cualquier entrenamiento como plantilla desde su menú ⋮.';

  @override
  String trainingLastDone(String day, int count) {
    return 'último $day · ×$count';
  }

  @override
  String trainingLast(String day) {
    return 'último $day';
  }

  @override
  String get trainingNeverDone => 'aún sin hacer';

  @override
  String trainingTemplateSize(int exercises, int sets) {
    return '$exercises ej · $sets series';
  }

  @override
  String trainingRunningFor(int minutes) {
    return '$minutes min hasta ahora';
  }

  @override
  String get trainingWorkouts => 'Entrenamientos';

  @override
  String get trainingSearchWorkouts => 'Buscar entrenamientos';

  @override
  String get trainingAllTime => 'Todo';

  @override
  String get trainingRange => 'Rango';

  @override
  String trainingLastDays(int count) {
    return 'Últimos $count días';
  }

  @override
  String trainingLastMonths(int count) {
    return 'Últimos $count meses';
  }

  @override
  String get trainingThisYear => 'Este año';

  @override
  String get trainingPickDates => 'Elegir fechas';

  @override
  String get trainingNoMatchTitle => 'No hay entrenamientos';

  @override
  String get trainingNoMatchBody => 'Prueba otro mes o rango.';

  @override
  String get trainingCascadeExercises => 'Ejercicios';

  @override
  String get trainingCascadeSets => 'Series planificadas';

  @override
  String get trainingSearchTemplates => 'Buscar plantillas';

  @override
  String workoutDetailPrLine(int count, String detail) {
    return '$count récord · $detail';
  }

  @override
  String workoutDetailVsLast(String change) {
    return '$change vs la última vez';
  }

  @override
  String get workoutDetailTime => 'Tiempo';

  @override
  String get workoutDetailSets => 'Series';

  @override
  String get workoutDetailAvgRest => 'Descanso medio';

  @override
  String get workoutDetailBurned => 'Quemadas';

  @override
  String get workoutDetailSaveTemplate => 'Guardar como plantilla';

  @override
  String get workoutDetailOther => 'Otros';

  @override
  String get workoutDetailDelete => 'Eliminar entrenamiento';

  @override
  String workoutDetailDeleteConsequence(int count) {
    return 'También elimina $count series registradas';
  }

  @override
  String workoutDetailFromTemplate(String name) {
    return 'De la plantilla $name';
  }

  @override
  String workoutDetailSetsDone(int count) {
    return '$count series';
  }

  @override
  String workoutDetailAvgRestShort(String rest) {
    return 'descanso medio $rest';
  }

  @override
  String get workoutDetailNotDone => 'No hecha';

  @override
  String get trainingCascadeSetsDone => 'Series registradas';

  @override
  String exerciseFilterShow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ver $count ejercicios',
      one: 'Ver 1 ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get exerciseDetailChartWeight => 'Peso';

  @override
  String get exerciseDetailChartReps => 'Reps';

  @override
  String get exerciseDetailChartVolume => 'Volumen';

  @override
  String get exerciseDetailChartDuration => 'Duración';

  @override
  String get exerciseDetailSessions => 'Sesiones';

  @override
  String get exerciseDetailBest => 'Mejor';

  @override
  String get exerciseDetailLast => 'Última';

  @override
  String get exerciseDetailSessionCount => 'Sesiones';

  @override
  String exerciseDetailSince(String date) {
    return 'desde $date';
  }

  @override
  String get exerciseDetailMuscles => 'Músculos';

  @override
  String get exerciseDetailDelete => 'Eliminar ejercicio';

  @override
  String get macroProtein => 'Proteína';

  @override
  String get macroCarbs => 'Carbohidratos';

  @override
  String get macroFat => 'Grasa';

  @override
  String get macroFiber => 'Fibra';

  @override
  String get macroSodium => 'Sodio';

  @override
  String get macroSugar => 'Azúcar';

  @override
  String foodHistoryFoods(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos',
      one: '1 alimento',
    );
    return '$_temp0';
  }

  @override
  String get foodHistoryEditMeal => 'Editar comida';

  @override
  String get foodHistoryLogAgain => 'Registrar de nuevo ahora';

  @override
  String foodHistoryLoggedAgain(int kcal) {
    return 'Registrada de nuevo · $kcal kcal';
  }

  @override
  String get foodHistorySearch => 'Buscar alimentos';

  @override
  String get foodHistoryNoMatchTitle => 'No hay comidas';

  @override
  String get foodHistoryNoMatchBody => 'Prueba otro mes, rango o búsqueda.';

  @override
  String mealEditBarcodeUnknown(String code) {
    return 'Ningún ingrediente tiene el código $code';
  }

  @override
  String get mealEditItemName => 'Comida';

  @override
  String get mealEditDelete => 'Eliminar comida';

  @override
  String mealEditDay(String eaten) {
    return 'día $eaten kcal';
  }

  @override
  String mealEditDayOf(String eaten, String target) {
    return 'día $eaten / $target';
  }

  @override
  String get mealEditSearch => 'Añadir alimento';

  @override
  String get mealEditScan => 'Escanear código';

  @override
  String get mealEditNoMatch => 'Ningún alimento coincide';

  @override
  String get mealEditRecent => 'Recientes';

  @override
  String get mealEditRecipe => 'Receta';

  @override
  String mealEditLast(String grams) {
    return 'último $grams g';
  }

  @override
  String mealEditPer100(int kcal) {
    return '$kcal kcal/100 g';
  }

  @override
  String get recipeSearch => 'Buscar recetas';

  @override
  String get recipeSortNewest => 'Recientes';

  @override
  String get recipeSortName => 'Nombre';

  @override
  String get recipeSortKcal => 'kcal';

  @override
  String recipeCooked(String grams) {
    return '$grams g cocinado';
  }

  @override
  String recipeEaten(String grams) {
    return '$grams g comidos';
  }

  @override
  String recipeLeft(String grams) {
    return 'quedan $grams g';
  }

  @override
  String recipeNoneEaten(String grams) {
    return '$grams g · nada comido aún';
  }

  @override
  String get recipeAllEaten => 'Todo comido';

  @override
  String get recipeEdit => 'Editar receta';

  @override
  String get recipeMissingIngredient => 'Ingrediente que falta';

  @override
  String get recipeColIngredient => 'Ingrediente';

  @override
  String get recipeTypeIngredient => 'Escribe un ingrediente…';

  @override
  String get recipeRaw => 'Crudo';

  @override
  String get recipePer100 => '/100 g';

  @override
  String recipeYield(int percent) {
    return 'rendimiento $percent%';
  }

  @override
  String get recipeDelete => 'Eliminar receta';

  @override
  String get recipeDeleteConsequence =>
      'Las comidas ya registradas la conservan';

  @override
  String get recipeCookedWeight => 'Peso cocinado';

  @override
  String ingredientSearchCount(int count) {
    return 'Buscar $count ingredientes';
  }

  @override
  String get ingredientTabNutrition => 'Nutrición';

  @override
  String get ingredientPer100 => 'por 100 g';

  @override
  String get ingredientCalories => 'Calorías';

  @override
  String get ingredientOfWhichSugar => 'de los cuales azúcar';

  @override
  String get ingredientDelete => 'Eliminar ingrediente';

  @override
  String get ingredientDeleteConsequence =>
      'Las recetas y comidas pasadas lo conservan';

  @override
  String moneyTransferTo(String account) {
    return 'Transferencia a $account';
  }

  @override
  String moneyTransferFrom(String account) {
    return 'Transferencia de $account';
  }

  @override
  String moneyOriginalAt(
    String amount,
    String rate,
    String base,
    String currency,
  ) {
    return '$amount a 1 $currency = $rate $base';
  }

  @override
  String get moneyFieldAccounts => 'Cuentas';

  @override
  String get moneyFieldAccount => 'Cuenta';

  @override
  String get moneyFieldCategory => 'Categoría';

  @override
  String get moneyFieldDate => 'Fecha';

  @override
  String get moneyFieldNote => 'Nota';

  @override
  String moneyOpenStatement(String account) {
    return 'Abrir $account';
  }

  @override
  String moneyThisMonth(String amount) {
    return '$amount este mes';
  }

  @override
  String get moneyGroupEveryday => 'Día a día';

  @override
  String get moneyGroupSavings => 'Ahorro e inversión';

  @override
  String get moneyGroupOther => 'Otras';

  @override
  String get moneyRecent => 'Recientes';

  @override
  String get moneySearch => 'Buscar notas y categorías';

  @override
  String get moneyNoMatchTitle => 'No hay movimientos';

  @override
  String get moneyNoMatchBody => 'Prueba otros filtros.';

  @override
  String get moneyKindIn => 'Ingresos';

  @override
  String get moneyKindOut => 'Gastos';

  @override
  String get moneyKindTransfers => 'Transferencias';

  @override
  String get moneyFilters => 'Filtros';

  @override
  String moneyFiltersCount(int count) {
    return 'Filtros · $count';
  }

  @override
  String get moneyClearFilters => 'Borrar';

  @override
  String get moneyWhen => 'Cuándo';

  @override
  String get moneyType => 'Tipo';

  @override
  String moneyShowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count movimientos',
      one: 'Mostrar 1 movimiento',
      zero: 'Ningún movimiento',
    );
    return '$_temp0';
  }

  @override
  String moneyIn(String amount) {
    return 'Entra $amount';
  }

  @override
  String moneyOut(String amount) {
    return 'Sale $amount';
  }

  @override
  String get plannerViewsTooltip => 'Día, semana o mes';

  @override
  String get plannerTabTasks => 'Tareas';

  @override
  String get plannerTabGoals => 'Objetivos';

  @override
  String plannerDoneOf(int done, int total) {
    return '$done de $total hechas';
  }

  @override
  String get quickAddEndTime => 'Hora de fin (opcional)';

  @override
  String get quickAddRepeatNone => 'No se repite';

  @override
  String get quickAddRepeatDaily => 'Cada día';

  @override
  String get quickAddRepeatWeekly => 'Cada semana';

  @override
  String get quickAddRepeatMonthly => 'Cada mes';

  @override
  String get quickAddRepeat => 'Repetir';

  @override
  String get quickAddNoGoal => 'Sin objetivo';

  @override
  String get quickAddGoal => 'Objetivo';

  @override
  String get quickAddTime => 'Hora';

  @override
  String get quickAddHint => 'Nueva tarea';

  @override
  String quickAddAnother(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count añadidas · siguiente tarea',
      one: 'Añadida · siguiente tarea',
    );
    return '$_temp0';
  }

  @override
  String get quickAddMore => 'Más opciones';

  @override
  String get quickAddAdd => 'Añadir';

  @override
  String get goalSourceManual => 'Manual';

  @override
  String goalLast(String when) {
    return 'último $when';
  }

  @override
  String goalUpdated(String when) {
    return 'actualizado $when';
  }

  @override
  String get goalToday => 'hoy';

  @override
  String get goalYesterday => 'ayer';

  @override
  String goalSourceExerciseBest(String exercise) {
    return 'Auto · mejor serie de $exercise';
  }

  @override
  String goalSourceExerciseDistance(String exercise) {
    return 'Auto · $exercise más largo';
  }

  @override
  String get goalSourceWorkouts => 'Auto · entrenamientos hechos';

  @override
  String get goalSourceBodyWeight => 'Auto · peso corporal';

  @override
  String goalSourceAccount(String account) {
    return 'Auto · saldo de $account';
  }

  @override
  String get goalSourceProtein => 'Auto · proteína, media de 7 días';

  @override
  String get goalSourceTasks => 'Auto · tareas vinculadas hechas';

  @override
  String goalBy(String date) {
    return 'para $date';
  }

  @override
  String goalTasksDone(int done, int total) {
    return '$done de $total tareas hechas';
  }

  @override
  String goalNext(String task) {
    return 'siguiente: $task';
  }

  @override
  String goalOf(String target) {
    return 'de $target';
  }

  @override
  String get goalRecord => 'Anotar';

  @override
  String goalTabTasks(int count) {
    return 'Tareas · $count';
  }

  @override
  String get goalTrackTitle => 'Medir el progreso con';

  @override
  String get goalTrackLabel => 'Medir progreso';

  @override
  String get goalTrackManualHint => 'Anotas cada valor tú';

  @override
  String get goalTrackPickExercise => '¿Qué ejercicio?';

  @override
  String get goalTrackExerciseBest => 'Mejor serie';

  @override
  String get goalTrackExerciseBestHint =>
      'El mayor peso levantado en un ejercicio';

  @override
  String get goalTrackExerciseDistance => 'Mayor distancia';

  @override
  String get goalTrackExerciseDistanceHint =>
      'La carrera, salida o nado más largo';

  @override
  String get goalTrackWorkouts => 'Entrenamientos hechos';

  @override
  String get goalTrackWorkoutsHint =>
      'Entrenamientos terminados desde el inicio';

  @override
  String get goalTrackBodyWeight => 'Peso corporal';

  @override
  String get goalTrackBodyWeightHint => 'Tu último pesaje';

  @override
  String get goalTrackAccount => 'Saldo de una cuenta';

  @override
  String get goalTrackAccountHint => 'El saldo de una de tus cuentas';

  @override
  String get goalTrackProtein => 'Proteína';

  @override
  String get goalTrackProteinHint => 'Proteína diaria media en 7 días';

  @override
  String get goalTrackTasks => 'Tareas vinculadas';

  @override
  String get goalTrackTasksHint => 'Cuántas tareas vinculadas están hechas';

  @override
  String get goalReminderReplyBody =>
      '¿Cuánto llevas? Responde con el nuevo valor.';

  @override
  String get goalReminderReplyAction => 'Anotar';

  @override
  String get goalReminderReplyHint => 'Nuevo valor';

  @override
  String get dashboardKcalLeftShort => 'kcal restantes';

  @override
  String get dashboardKcalOverShort => 'kcal de más';

  @override
  String dashboardPlannedOn(String date) {
    return 'Planificado · $date';
  }

  @override
  String dashboardNowUntil(String time) {
    return 'Ahora · hasta las $time';
  }

  @override
  String dashboardNextAt(String time) {
    return 'Siguiente · $time';
  }

  @override
  String get dashboardNextUp => 'Siguiente';

  @override
  String get dashboardAllDoneToday => 'Todo hecho por hoy';

  @override
  String dashboardGoalBehind(String amount) {
    return 'Por detrás del ritmo: faltan $amount por semana';
  }

  @override
  String get dashboardGoalOnPace => 'Al ritmo previsto';

  @override
  String dashboardGoalBy(String date) {
    return 'para $date';
  }

  @override
  String dashboardOfIncome(String amount) {
    return 'de $amount ingresados';
  }

  @override
  String dashboardAmountLeft(String amount) {
    return 'quedan $amount';
  }

  @override
  String dashboardAmountOver(String amount) {
    return '$amount de más';
  }

  @override
  String dashboardDaysLeftInMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count días',
      one: 'queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteCustom => 'Personalizada';

  @override
  String get settingsPaletteEditCustom => 'Editar paleta personalizada';

  @override
  String get customPaletteTitleDark => 'Paleta oscura personalizada';

  @override
  String get customPaletteTitleLight => 'Paleta clara personalizada';

  @override
  String get customPaletteHint =>
      'Colores base16. Cada uno indica qué colorea; escribe un valor hexadecimal para cambiarlo.';

  @override
  String get customPaletteInUse => 'En uso';

  @override
  String get customPaletteUse => 'Usar esta paleta';

  @override
  String get customPalettePaste => 'Pegar colores base16';

  @override
  String get customPaletteReset => 'Restablecer valores';

  @override
  String customPalettePasted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colores pegados',
      one: '1 color pegado',
    );
    return '$_temp0';
  }

  @override
  String get customPalettePasteNone =>
      'No hay colores base16 en el portapapeles';

  @override
  String get paletteRoleBackground => 'fondo';

  @override
  String get paletteRoleCards => 'tarjetas';

  @override
  String get paletteRoleChips => 'chips y barras';

  @override
  String get paletteRoleSheets => 'hojas y menús';

  @override
  String get paletteRoleText => 'texto';

  @override
  String get paletteRoleSecondaryText => 'texto secundario';

  @override
  String get paletteRoleLines => 'líneas';

  @override
  String get paletteRoleAccent => 'acento';

  @override
  String get paletteRoleTextOnColor => 'texto sobre botones de color';

  @override
  String get paletteRoleSuccess => 'éxito';

  @override
  String get paletteRoleWarning => 'aviso';

  @override
  String get paletteRoleDanger => 'peligro';

  @override
  String get paletteRoleUnused => 'Aún sin uso';
}
