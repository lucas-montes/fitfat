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
  String get plannerViewMonth => 'Vista mensual';

  @override
  String get plannerViewDay => 'Vista diaria';

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
  String get plannerCopyPrevious => 'Copiar desde ayer';

  @override
  String get plannerMoreActions => 'Más acciones';

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
  String get settingsCurrencyBudgetSubtitle => 'Moneda base y tipos de cambio';

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
  String get experimentsEmptyTitle => 'Aún no hay experimentos';

  @override
  String get experimentsEmptyBody =>
      'Crea un experimento para hacer seguimiento de un hábito, un cambio de dieta o un protocolo de entrenamiento con controles diarios.';

  @override
  String get experimentsNoEndDate => 'Sin fecha de fin';

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
}
