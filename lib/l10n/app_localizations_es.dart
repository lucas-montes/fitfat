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
  String get dashboardRemaining => 'restante';

  @override
  String dashboardConsumedOfTarget(String consumed, String target) {
    return '$consumed / $target kcal';
  }

  @override
  String dashboardOverTarget(String kcal) {
    return '$kcal kcal por encima del objetivo';
  }

  @override
  String get dashboardMacroTargets => 'Objetivos de macros';

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
  String dashboardVolumeKg(String volume, String unit) {
    return '$volume $unit';
  }

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
  String get dashboardCalorieTargetEmptyCta => 'Complete profile';

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
  String get templatesSavedAsTemplate =>
      'Entrenamiento guardado como plantilla';

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
  String get workoutFormSelectExercise => 'Seleccione al menos un ejercicio';

  @override
  String get workoutFormSearchHint => 'Buscar ejercicios';

  @override
  String get workoutFormRestLabel => 'Descanso (min)';

  @override
  String get workoutFormSetIncomplete =>
      'Completa cada serie añadida (valores y tiempo de descanso) o elimínala';

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
  String get ingredientFormSodiumSuffix => 'mg';

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
  String mealDeleted(String name) {
    return 'Comida «$name» eliminada';
  }

  @override
  String mealListIngredientCount(int count) {
    return '$count ingrediente';
  }

  @override
  String mealListIngredientCount_plural(Object count) {
    return '$count ingredientes';
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
  String get mealFormNameHint => 'Ej.: Desayuno';

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
  String get settingsComputeActivity =>
      'Calcular la actividad desde entrenamientos y pasos';

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
  String get settingsCalorieAdjustmentLabel =>
      'Ajuste del objetivo calórico (kcal)';

  @override
  String get settingsExperimentBaselineLabel =>
      'Línea base de experimentos (días)';

  @override
  String get settingsDefaultRestLabel =>
      'Descanso por defecto entre series (min)';

  @override
  String get settingsReminderLeadLabel =>
      'Antelación del recordatorio previo (min)';

  @override
  String get settingsApiTimeoutLabel =>
      'Tiempo de espera de sincronización (s)';

  @override
  String get settingsPlannerHorizonHelp =>
      'Cuántos días por adelantado se crean las tareas recurrentes en el plan.';

  @override
  String get settingsCalorieAdjustmentHelp =>
      'Kcal que se suman (aumentar) o se restan (perder) de tu objetivo calórico diario.';

  @override
  String get settingsExperimentBaselineHelp =>
      'Días de historial antes del inicio de un experimento, usados como referencia comparativa.';

  @override
  String get settingsDefaultRestHelp =>
      'Rellena el campo de descanso al añadir una serie nueva. Déjalo vacío para no usar ninguno.';

  @override
  String get settingsReminderLeadHelp =>
      'Minutos antes de la hora de inicio de una tarea en que salta la notificación previa.';

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
    return 'Na ${value}mg';
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
  String get settingsExperimentReminders => 'Recordatorios de experimentos';

  @override
  String get settingsExperimentRemindersSubtitle =>
      'Recordatorios diarios mientras haya un experimento activo';

  @override
  String get settingsSyncServer => 'Servidor de sincronización';

  @override
  String get settingsSyncServerHint =>
      'Apunta esto a tu servidor de sincronización para obtener ejercicios, ingredientes y divisas. Déjalo vacío para desactivar la sincronización.';

  @override
  String get settingsSyncBaseUrl => 'URL del servidor';

  @override
  String get settingsSyncApiKey => 'Clave API';

  @override
  String get syncExercisesTooltip => 'Sincronizar ejercicios';

  @override
  String get syncIngredientsTooltip => 'Sincronizar ingredientes';

  @override
  String get syncCurrenciesTooltip => 'Sincronizar divisas';

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
  String get syncExercisesHelp =>
      'Descarga el catálogo de ejercicios compartido y sus medios desde el servidor.';

  @override
  String get syncIngredientsHelp =>
      'Descarga el catálogo compartido de ingredientes, tiendas y precios desde el servidor.';

  @override
  String get syncCurrenciesHelp =>
      'Descarga los tipos de cambio más recientes desde el servidor.';

  @override
  String get settingsSyncEndpoints => 'Puntos de acceso';

  @override
  String get settingsSyncEndpointsHint =>
      'Sustituye la ruta del servidor para cada operación. Deja el valor predeterminado salvo que tu servidor use rutas distintas.';

  @override
  String get endpointReset => 'Restablecer';

  @override
  String get pushAllData => 'Enviar todos los datos';

  @override
  String get pushAllDataTooltip =>
      'Sube todos los datos locales al servidor (unidireccional)';

  @override
  String get pushAllSuccess => 'Todos los datos enviados al servidor.';

  @override
  String get exportServer => 'Exportar base de datos al servidor';

  @override
  String get exportServerTooltip =>
      'Sube una copia completa de tu base de datos local al servidor';

  @override
  String get importServer => 'Importar base de datos del servidor';

  @override
  String get importServerTooltip =>
      'Reemplaza tu base de datos local con la copia del servidor';

  @override
  String get importConfirmTitle => '¿Reemplazar los datos locales?';

  @override
  String get importConfirmBody =>
      'Esto reemplaza todos los datos locales con la copia del servidor. No se puede deshacer.';

  @override
  String get importSuccess =>
      'Base de datos importada. Reinicia la app para cargarla.';

  @override
  String get importFailed => 'Error al importar';

  @override
  String get importNothing => 'Nada que importar';

  @override
  String get exportSuccess => 'Base de datos exportada.';

  @override
  String get exportFailed => 'Error al exportar';

  @override
  String get pushAllDataHelp =>
      'Sube todos tus datos locales al servidor (copia unidireccional).';

  @override
  String get exportServerHelp =>
      'Sube una copia completa de tu archivo de base de datos local al servidor.';

  @override
  String get importServerHelp =>
      'Reemplaza tu base de datos local con la copia del servidor. Pide confirmación primero.';

  @override
  String get settingsPlanner => 'Planificador';

  @override
  String get settingsPlannerSubtitle =>
      'Entrenamientos, experimentos, tareas y metas';

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
  String get settingsExportDb => 'Exportar base de datos';

  @override
  String get settingsExportDbSubtitle =>
      'Comparte una copia de tus datos (SQLite)';

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
  String get workoutSummaryDone => 'Hecho';

  @override
  String get workoutSummaryDurationLabel => 'Duración';

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
  String get settingsRateManual => 'Manual';

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
  String get commonDelete => 'Common Delete';

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
  String get settingsRateEdit => 'Editar tasa';

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
      'Aún no hay cuentas. Agrega una para empezar.';

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
  String get receiptUploadSuccess => 'Recibo enviado';

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
  String get tabExperiments => 'Experimentos';

  @override
  String get experimentsAppBar => 'Experimentos';

  @override
  String get experimentsFab => 'Nuevo experimento';

  @override
  String get plannerViewDay => 'Vista de día';

  @override
  String get plannerViewWeek => 'Vista semanal';

  @override
  String get plannerViewMonth => 'Vista mensual';

  @override
  String get plannerAllDay => 'Todo el día';

  @override
  String get plannerGoToday => 'Ir a hoy';

  @override
  String get experimentsEmptyTitle => 'Aún no hay experimentos';

  @override
  String get experimentsEmptyBody =>
      'Crea un experimento para hacer seguimiento de un hábito, un cambio de dieta o un protocolo de entrenamiento con controles diarios.';

  @override
  String get experimentLinkedTasksTitle => 'Tareas vinculadas';

  @override
  String get experimentLinkTask => 'Vincular tarea';

  @override
  String get experimentUnlinkTask => 'Desvincular tarea';

  @override
  String get experimentNoLinkedTasks =>
      'Aún no hay tareas vinculadas. Vincula tareas para seguir los pasos de este experimento.';

  @override
  String get experimentSearchTasksHint => 'Buscar tareas…';

  @override
  String get experimentsRelatedGoals => 'Metas relacionadas';

  @override
  String get experimentsRelatedNotes => 'Notas relacionadas';

  @override
  String get experimentsNoLinkedGoals => 'Aún no hay metas relacionadas.';

  @override
  String get experimentsNoLinkedNotes => 'Aún no hay notas relacionadas.';

  @override
  String get linkGoal => 'Vincular meta';

  @override
  String get unlinkGoal => 'Desvincular meta';

  @override
  String get linkNote => 'Vincular nota';

  @override
  String get unlinkNote => 'Desvincular nota';

  @override
  String experimentDaysElapsed(int days) {
    return '$days días transcurridos';
  }

  @override
  String get experimentStatusPlanned => 'Planificado';

  @override
  String get experimentStatusActive => 'Activo';

  @override
  String get experimentStatusDone => 'Completado';

  @override
  String get experimentStatusAborted => 'Abortado';

  @override
  String get experimentCategoryWorkout => 'Entrenamiento';

  @override
  String get experimentCategoryDiet => 'Dieta';

  @override
  String get experimentCategoryBody => 'Cuerpo';

  @override
  String get experimentCategorySteps => 'Pasos';

  @override
  String get experimentCategoryBudget => 'Presupuesto';

  @override
  String get experimentFormTitleNew => 'Nuevo experimento';

  @override
  String get experimentFormTitleEdit => 'Editar experimento';

  @override
  String get experimentFormNameLabel => 'Nombre';

  @override
  String get experimentFormNameHint =>
      'p. ej. bloque de hipertrofia de 8 semanas';

  @override
  String get experimentFormPurposeLabel => 'Hipótesis / propósito';

  @override
  String get experimentFormPurposeHint => '¿Qué estás probando?';

  @override
  String get experimentFormStartLabel => 'Fecha de inicio';

  @override
  String get experimentFormEndLabel => 'Fecha de fin';

  @override
  String get experimentFormStatusLabel => 'Estado';

  @override
  String get experimentFormCategoriesLabel => 'Datos a registrar';

  @override
  String get experimentFormReminderLabel => 'Recordatorio de control diario';

  @override
  String get experimentFormReminderSubtitle =>
      'Una notificación abre este experimento para una valoración rápida.';

  @override
  String get experimentFormReminderTimeLabel => 'Hora del recordatorio';

  @override
  String get experimentFormDelete => 'Eliminar';

  @override
  String get experimentFormDeleteConfirmTitle => '¿Eliminar el experimento?';

  @override
  String get experimentFormDeleteConfirmBody =>
      'Esto también elimina los controles del experimento.';

  @override
  String get experimentFormNameRequired => 'Ponle un nombre al experimento.';

  @override
  String get experimentFormInvalidDates =>
      'La fecha de fin debe ser igual o posterior a la de inicio.';

  @override
  String get experimentDetailCheckin => 'Control diario';

  @override
  String get experimentDetailCheckinToday =>
      'Ya has hecho el control de hoy. Puedes actualizarlo.';

  @override
  String get experimentDetailCheckinDialogTitle => 'Control diario';

  @override
  String get experimentDetailCheckinRatingLabel => 'Valoración';

  @override
  String get experimentDetailCheckinRatingHint =>
      '1 = mal día, 5 = excelente día';

  @override
  String get experimentDetailCheckinNoteLabel => 'Nota (opcional)';

  @override
  String get experimentDetailCheckinNoteHint => '¿Cómo te ha ido?';

  @override
  String get experimentDetailProgressTitle => 'Progreso';

  @override
  String get experimentDetailCheckinsTitle => 'Controles';

  @override
  String get experimentDetailTrackedTitle => 'Datos registrados';

  @override
  String get experimentDetailBaselineTitle => 'Línea base de 14 días';

  @override
  String get experimentDetailNoData => 'Aún no hay datos para este período.';

  @override
  String get experimentDetailMarkDone => 'Marcar como completado';

  @override
  String get experimentDetailAbort => 'Abortar';

  @override
  String experimentDetailCheckinCount(int count) {
    return '$count controles';
  }

  @override
  String experimentRatingOf5(int rating) {
    return '$rating/5';
  }

  @override
  String get experimentChartWorkout => 'Volumen de entrenamiento (kg)';

  @override
  String get experimentChartDiet => 'Calorías (kcal)';

  @override
  String get experimentChartDietProtein => 'Proteína (g)';

  @override
  String get experimentChartWeight => 'Peso (kg)';

  @override
  String get experimentChartSteps => 'Pasos';

  @override
  String experimentReminderTitle(String experiment) {
    return 'Control de $experiment';
  }

  @override
  String get experimentReminderBody => 'Valora tu día para este experimento.';

  @override
  String experimentReminderScheduled(String time) {
    return 'Recordatorio diario fijado a las $time.';
  }

  @override
  String get experimentReminderCancelled => 'Recordatorio diario desactivado.';

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
  String get initiativesEmptyAllTitle => 'Aún no hay experimentos ni metas';

  @override
  String get initiativesEmptyAll =>
      'Crea un experimento para seguir un hábito, o una meta a lograr.';

  @override
  String get initiativesEmptyFilterTitle => 'No hay iniciativas que coincidan';

  @override
  String get initiativesEmptyFilter =>
      'Ningún experimento ni meta lleva los tags seleccionados.';

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
      'When deleting experiments/goals, choose whether to also delete linked tasks.';

  @override
  String get settingsCascadeAsk => 'Ask each time';

  @override
  String get settingsCascadeAlways => 'Always delete tasks';

  @override
  String get settingsCascadeNever => 'Never delete tasks';

  @override
  String get templatesDuplicate => 'Duplicate';

  @override
  String get templatesDuplicated => 'Template duplicated';

  @override
  String get cascadeDeleteTitleWithTasks => 'Delete linked tasks?';

  @override
  String get cascadeDeleteKeepTasks => 'Keep tasks';

  @override
  String experimentDeleted(String name) {
    return 'Experiment \"$name\" deleted';
  }

  @override
  String goalDeleted(String name) {
    return 'Goal \"$name\" deleted';
  }
}
