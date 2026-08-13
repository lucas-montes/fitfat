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
  String dashboardVolumeKg(String volume) {
    return '$volume kg';
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
  String get activeWorkoutInThisWorkout => 'En este entrenamiento';

  @override
  String get activeWorkoutAllExercises => 'Todos los ejercicios';

  @override
  String get activeWorkoutSearchPrompt => 'Escribe para buscar ejercicios';

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
  String get exerciseLockedEdit =>
      'Los ejercicios integrados no se pueden editar.';

  @override
  String get exerciseLockedDelete =>
      'Los ejercicios integrados no se pueden eliminar.';

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
  String exerciseDetailWeightDelta(String delta) {
    return '$delta kg';
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
  String workoutDuplicated(String name) {
    return 'Entrenamiento «$name» duplicado';
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
  String get workoutFormExercises => 'Ejercicios';

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
  String get workoutDetailSetHeaderHash => '#';

  @override
  String get workoutDetailSetHeaderPlanned => 'Planificado';

  @override
  String get workoutDetailSetHeaderActual => 'Real';

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
  String get workoutStarted => 'Entrenamiento iniciado';

  @override
  String get workoutCompleted => 'Entrenamiento completado';

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
  String get plannerAddTask => 'Nueva tarea';

  @override
  String get plannerEditTask => 'Editar tarea';

  @override
  String plannerDeleted(String title) {
    return 'Tarea «$title» eliminada';
  }

  @override
  String get plannerCopyPrevious => 'Copiar desde ayer';

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
  String get plannerCopyNothing =>
      'No hay tareas pendientes de ayer para copiar.';

  @override
  String plannerCopyDone(int count) {
    return '$count tarea copiada hoy.';
  }

  @override
  String plannerCopyDone_plural(Object count) {
    return '$count tareas copiadas hoy.';
  }

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
  String get settingsResetDataDone => 'Todos los datos se han restablecido.';

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
  String get commonSave => 'Guardar';

  @override
  String get commonSaved => 'Guardado';

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
  String workoutDetailPlannedSetRest(Object planned, Object rest) {
    return '$planned · descanso $rest';
  }

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
  String bodyMetricsLatestWeight(String value) {
    return 'Último: $value kg';
  }

  @override
  String bodyMetricsLatestHeight(String value) {
    return 'Última: $value cm';
  }

  @override
  String bodyMetricsValueKg(String value) {
    return '$value kg';
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
  String workoutSummaryValueKg(String value) {
    return '$value kg';
  }

  @override
  String workoutSummaryDistanceValue(String distance) {
    return '$distance m';
  }
}
