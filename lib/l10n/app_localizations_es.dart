// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'fitfat';

  @override
  String get mealsTab => 'Comidas';

  @override
  String get ingredientsTab => 'Ingredientes';

  @override
  String get addMeal => 'Añadir comida';

  @override
  String get addIngredient => 'Añadir ingrediente';

  @override
  String get editIngredient => 'Editar ingrediente';

  @override
  String get editMeal => 'Editar comida';

  @override
  String get archivedIngredients => 'Ingredientes archivados';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get archive => 'Archivar';

  @override
  String get restore => 'Restaurar';

  @override
  String get add => 'Añadir';

  @override
  String get change => 'Cambiar';

  @override
  String get clear => 'Limpiar';

  @override
  String get ingredientName => 'Nombre del ingrediente';

  @override
  String get buildFromIngredients => 'Componer a partir de ingredientes';

  @override
  String get components => 'Componentes';

  @override
  String get noComponentsAdded => 'No hay componentes añadidos';

  @override
  String get addComponents => 'Añadir ingredientes';

  @override
  String get searchIngredients => 'Buscar ingredientes';

  @override
  String get typeToSearchIngredient => 'Escriba para buscar';

  @override
  String get caloriesPer100g => 'Calorías por 100g';

  @override
  String get proteinPer100g => 'Proteínas por 100g (g)';

  @override
  String get carbsPer100g => 'Carbohidratos por 100g (g)';

  @override
  String get fatPer100g => 'Grasas por 100g (g)';

  @override
  String get sodiumPer100g => 'Sodio por 100g (mg)';

  @override
  String get fiberPer100g => 'Fibra por 100g (g)';

  @override
  String get amountInGrams => 'Cantidad en gramos';

  @override
  String get gramsHint => 'ej. 80';

  @override
  String get gramsHintMeal => 'ej. 120';

  @override
  String get createNewIngredient => 'Crear nuevo ingrediente';

  @override
  String get mealNameOptional => 'Nombre de la comida (opcional)';

  @override
  String get selectedIngredients => 'Ingredientes seleccionados';

  @override
  String get noIngredientsSelected => 'No hay ingredientes seleccionados';

  @override
  String get noIngredientsFound => 'No se encontraron ingredientes';

  @override
  String get archiveIngredientTitle => 'Archivar ingrediente';

  @override
  String get archiveIngredientContent =>
      'Este ingrediente se ocultará de las vistas normales. Use la pestaña Ingredientes archivados para restaurarlo o eliminarlo.';

  @override
  String get deleteMealTitle => '¿Eliminar comida?';

  @override
  String get deleteMealContent => 'Esto eliminará la comida de su registro.';

  @override
  String get deleteIngredientTitle => '¿Eliminar ingrediente?';

  @override
  String get deleteIngredientContent =>
      'Esto eliminará el ingrediente y sus porciones de las comidas.';

  @override
  String get permanentlyDeleteTitle => 'Eliminar ingrediente permanentemente';

  @override
  String get permanentlyDeleteContent =>
      'Este ingrediente se eliminará permanentemente. No se puede restaurar.';

  @override
  String get restoreIngredientTitle => 'Restaurar ingrediente';

  @override
  String get deleteMealTooltip => 'Eliminar comida';

  @override
  String get deleteIngredientTooltip => 'Eliminar';

  @override
  String get ingredientArchived => 'Ingrediente archivado correctamente';

  @override
  String get ingredientDeleted => 'Ingrediente eliminado correctamente';

  @override
  String get ingredientRestored => 'Ingrediente restaurado correctamente';

  @override
  String get meal => 'Comida';

  @override
  String get sortAZ => 'Ordenar A-Z';

  @override
  String get sortZA => 'Ordenar Z-A';

  @override
  String get noIngredientsFoundSubtext =>
      'Pruebe con otra búsqueda o añada un nuevo ingrediente';

  @override
  String get kcalAbbrev => 'kcal';

  @override
  String get proteinAbbrev => 'P';

  @override
  String get carbsAbbrev => 'C';

  @override
  String get fatAbbrev => 'G';

  @override
  String eatenAtLabel(Object time) {
    return 'Comido a las: $time';
  }

  @override
  String failedToSave(Object error) {
    return 'Error al guardar la comida: $error';
  }

  @override
  String failedToUpdate(Object error) {
    return 'Error al actualizar la comida: $error';
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
      other: '$countString elementos',
      one: '$countString elemento',
    );
    return '$_temp0';
  }

  @override
  String formatMacros(Object kcal, Object protein, Object carbs, Object fat) {
    return '$kcal kcal · P ${protein}g · C ${carbs}g · G ${fat}g';
  }

  @override
  String formatPer100g(Object kcal, Object protein, Object carbs, Object fat) {
    return 'Por 100g: $kcal kcal · P ${protein}g · C ${carbs}g · G ${fat}g';
  }

  @override
  String formatTotal(Object total) {
    return 'Total: $total';
  }

  @override
  String get exercises => 'Ejercicios';

  @override
  String get exercise => 'Ejercicio';

  @override
  String get activeWorkout => 'Entrenamiento activo';

  @override
  String get noActiveSeance => 'No hay entrenamiento activo';

  @override
  String get guidedMode => 'Guiado';

  @override
  String get freeformMode => 'Libre';

  @override
  String get cancelSeance => 'Cancelar entrenamiento';

  @override
  String get backToApp => 'Volver a la app';

  @override
  String get discardEmptySeance => '¿Descartar entrenamiento vacío?';

  @override
  String get discardEmptySeanceContent =>
      'Este entrenamiento no tiene ejercicios y no se guardará en el historial.';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get discard => 'Descartar';

  @override
  String get completeSeance => 'Completar entrenamiento';

  @override
  String get addExercise => 'Añadir ejercicio';

  @override
  String get followPlan => 'Seguir el plan';

  @override
  String get searchToAdd => 'Buscar para añadir';

  @override
  String get searchExercises => 'Buscar ejercicios';

  @override
  String get exerciseTypeToSearch => 'Escriba para buscar...';

  @override
  String get typeToFindExercises => 'Escriba para encontrar...';

  @override
  String get sets => 'Series';

  @override
  String get set => 'Serie';

  @override
  String get setsLower => 'series';

  @override
  String get done => 'hecho';

  @override
  String get summary => 'Resumen';

  @override
  String get totalReps => 'Reps totales';

  @override
  String get totalWeight => 'Peso total';

  @override
  String get addSet => 'Añadir serie';

  @override
  String get tapToComplete => 'Tocar para completar';

  @override
  String get noExercisesFound => 'No se encontraron ejercicios para';

  @override
  String get repsLower => 'reps';

  @override
  String get preFilledFrom => 'Prellenado desde';

  @override
  String get allSetsComplete => '¡Todas las series completas!';

  @override
  String get restTimer => 'Temporizador de descanso';

  @override
  String get skip => 'Saltar';

  @override
  String get restOver => '¡Descanso terminado!';

  @override
  String get getReadyNextSet => '¡Prepárate para la próxima serie!';

  @override
  String get editSet => 'Editar serie';

  @override
  String get weightKg => 'Peso (kg)';

  @override
  String get history => 'Historial';

  @override
  String get records => 'Récords';

  @override
  String get noHistory => 'Sin historial';

  @override
  String get sessions => 'Sesiones';

  @override
  String get volume => 'Volumen';

  @override
  String get time => 'Tiempo';

  @override
  String get searchHistory => 'Buscar en historial';

  @override
  String get searchByDateHint => 'Buscar por fecha o nombre...';

  @override
  String get volumeProgression => 'Progresión de volumen';

  @override
  String get estimated1RM => 'Progresión de 1RM estimada';

  @override
  String get bestEstimated1RM => 'Mejor 1RM estimada';

  @override
  String get maxWeight => 'Peso máximo';

  @override
  String get maxVolume => 'Volumen máximo (Serie)';

  @override
  String get totalVolume => 'Volumen total';

  @override
  String get noHistoryContent =>
      'Completa un entrenamiento con este ejercicio para verlo aquí';

  @override
  String get library => 'Biblioteca';

  @override
  String get createExercise => 'Crear ejercicio';

  @override
  String get exerciseName => 'Nombre del ejercicio';

  @override
  String get category => 'Categoría';

  @override
  String get templates => 'Plantillas';

  @override
  String get createTemplate => 'Crear plantilla';

  @override
  String exercisesCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ejercicios',
      one: '$countString ejercicio',
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
      other: '$countString series',
      one: '$countString serie',
    );
    return '$_temp0';
  }

  @override
  String get workoutsTab => 'Entrenamientos';

  @override
  String get statsTab => 'Estadísticas';

  @override
  String get searchExercisesHint => 'Buscar ejercicios...';

  @override
  String get noExercisesFoundSimple => 'No se encontraron ejercicios';

  @override
  String get noExercisesFoundAction =>
      'Pruebe con otra búsqueda o borre los filtros';

  @override
  String get runningWorkout => 'Sesión en curso';

  @override
  String get viewWorkout => 'Ver';

  @override
  String get stopWorkout => 'Detener';

  @override
  String get newSeance => 'Nueva sesión';

  @override
  String get startBlankSeance => 'Iniciar sesión en blanco';

  @override
  String get create => 'Crear';

  @override
  String get noTemplatesYet =>
      'Aún no hay plantillas. ¡Crea una para empezar rápido!';

  @override
  String get browseAllTemplates => 'Explorar todas las plantillas';

  @override
  String get noWorkoutsYet =>
      'Aún no hay entrenamientos. ¡Empieza el primero arriba!';

  @override
  String get allTime => 'Todo el tiempo';

  @override
  String get workouts => 'Entrenamientos';

  @override
  String get duration => 'Duración';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get activity => 'Actividad';

  @override
  String get trends => 'Tendencias';

  @override
  String get edit => 'Editar';

  @override
  String get clone => 'Duplicar';

  @override
  String get start => 'Iniciar';

  @override
  String get createTemplateFrom => 'Crear plantilla a partir de esto';

  @override
  String get workoutAlreadyRunning => 'Entrenamiento ya en curso';

  @override
  String get workoutAlreadyRunningContent =>
      'Ya hay un entrenamiento en curso. ¿Cancelarlo y empezar uno nuevo?';

  @override
  String get startNewWorkout => 'Iniciar nuevo entrenamiento';

  @override
  String get workout => 'Entrenamiento';

  @override
  String get noExercises => 'Sin ejercicios';

  @override
  String get pr => '¡RP!';

  @override
  String get oneRM => '1RM est.';

  @override
  String get workoutSummary => 'Resumen del entrenamiento';

  @override
  String get exerciseBreakdown => 'Desglose de ejercicios';

  @override
  String get best => 'Mejor';

  @override
  String get finish => 'Finalizar';

  @override
  String previousSessions(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return 'Sesiones anteriores ($countString)';
  }

  @override
  String get tapToExpand => 'Toque para expandir';

  @override
  String get reps => 'Repeticiones';

  @override
  String get templateLibrary => 'Biblioteca de plantillas';

  @override
  String get createFirstTemplate => 'Crea tu primera plantilla';

  @override
  String get editTemplate => 'Editar plantilla';

  @override
  String get templateNameLabel => 'Nombre de la plantilla';

  @override
  String get addCustom => 'Añadir como personalizado';

  @override
  String get searchAboveHint =>
      'Busca un ejercicio arriba para añadirlo. Toca un ejercicio en la lista para configurar series y repeticiones.';

  @override
  String get noExercisesAdded => 'Aún no se han añadido ejercicios';

  @override
  String get noSetsConfigured => 'Sin series configuradas — toque para editar';

  @override
  String get remove => 'Eliminar';

  @override
  String get restSeconds => 'Descanso (s)';

  @override
  String get pastMonth => 'Último mes';

  @override
  String get past3Months => 'Últimos 3 meses';

  @override
  String get pastYear => 'Último año';

  @override
  String noHistoryFor(Object name) {
    return 'Aún no hay historial para $name';
  }

  @override
  String get completeWorkoutToSee =>
      'Completa un entrenamiento con este ejercicio para verlo aquí';

  @override
  String get date => 'Fecha';

  @override
  String get searchByDateWorkout =>
      'Buscar por fecha o nombre de entrenamiento...';

  @override
  String sessionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '$count sesión',
    );
    return '$_temp0';
  }

  @override
  String get maxVolumeSet => 'Volumen máx. (serie)';

  @override
  String get notAvailable => 'N/D';

  @override
  String get across => 'En';

  @override
  String get overviewTab => 'Resumen';

  @override
  String get goalsTab => 'Objetivos';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get weight => 'Peso';

  @override
  String get weightLogged => '¡Peso registrado!';

  @override
  String get enterWeightKg => 'Ingrese peso (kg)';

  @override
  String get log => 'Registrar';

  @override
  String get weightTracker => 'Control de peso';

  @override
  String get noWeightEntries => 'Aún no hay registros de peso.';

  @override
  String get latest => 'Último';

  @override
  String get logWeight => 'Registrar peso';

  @override
  String get historyLast7Entries => 'Historial (últimas 7 entradas)';

  @override
  String get waterIntake => 'Hidratación';

  @override
  String get goal => 'Objetivo';

  @override
  String get setDailyWaterGoal => 'Establecer objetivo de agua diario';

  @override
  String get litersExample => 'Litros (ej. 2.5)';

  @override
  String get todaysActivity => 'Actividad de hoy';

  @override
  String get workoutInProgress => 'Entrenamiento en curso';

  @override
  String get exercisesCompleted => 'ejercicios completados';

  @override
  String get noWorkoutsToday =>
      'Aún no hay entrenamientos. Inicia una sesión para ver el resumen aquí.';

  @override
  String get elapsed => 'transcurrido';

  @override
  String get last84Days => 'Últimos 84 días';

  @override
  String get noTrainingRecorded =>
      'No hay entrenamientos registrados este día.';

  @override
  String get today => 'Hoy';

  @override
  String get calories => 'Calorías';

  @override
  String get protein => 'Proteínas';

  @override
  String get carbs => 'Carbohidratos';

  @override
  String get fat => 'Grasas';

  @override
  String get setProfileForTargets =>
      'Establece un objetivo de peso y tu perfil para ver los objetivos diarios.';

  @override
  String get bodyWeightGoal => 'Objetivo de peso';

  @override
  String get noBodyweightGoalSet => 'No hay objetivo de peso establecido.';

  @override
  String get addBodyWeightGoal => 'Añadir objetivo de peso';

  @override
  String get target => 'Meta';

  @override
  String get by => 'Para el';

  @override
  String get strengthGoals => 'Objetivos de fuerza';

  @override
  String get addStrengthGoalTooltip => 'Añadir objetivo de fuerza';

  @override
  String get noStrengthGoalsYet =>
      'Aún no hay objetivos de fuerza. Toca + para añadir (uno por ejercicio).';

  @override
  String get setUpProfileFirst => 'Configura tu perfil primero';

  @override
  String get createProfile => 'Crear perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get yourProfile => 'Tu perfil';

  @override
  String get birthdate => 'Fecha de nacimiento';

  @override
  String get sex => 'Sexo';

  @override
  String get heightCm => 'Altura (cm)';

  @override
  String get activityLevel => 'Nivel de actividad';

  @override
  String get addBodyWeightGoalTitle => 'Añadir objetivo de peso';

  @override
  String get editBodyWeightGoalTitle => 'Editar objetivo de peso';

  @override
  String get direction => 'Dirección';

  @override
  String get targetWeightKg => 'Peso objetivo (kg)';

  @override
  String get targetDate => 'Fecha objetivo';

  @override
  String get notSet => 'No establecido';

  @override
  String get addStrengthGoalTitle => 'Añadir objetivo de fuerza';

  @override
  String get editStrengthGoalTitle => 'Editar objetivo de fuerza';

  @override
  String get searchOrTypeCustom => 'Buscar o escribir nombre personalizado';

  @override
  String get deleteBodyweightGoal => '¿Eliminar objetivo de peso?';

  @override
  String get deleteBodyweightGoalContent =>
      'Esto borrará tu objetivo de peso y tus objetivos de macros.';

  @override
  String deleteStrengthGoalTitle(Object exercise) {
    return '¿Eliminar objetivo de fuerza para $exercise?';
  }

  @override
  String get deleteStrengthGoalContent => 'Esto eliminará el objetivo.';

  @override
  String get deleteEverything => 'Eliminar todo';

  @override
  String get goalReached => '¡Objetivo alcanzado!';

  @override
  String get toGo => 'restante';

  @override
  String get strengthTrend => 'Tendencia de fuerza';

  @override
  String get noStrengthData => 'Sin datos de fuerza';

  @override
  String get weightTrend90Days => 'Tendencia de peso (90 días)';

  @override
  String get profile => 'Perfil';

  @override
  String get setUpProfile => 'Configurar perfil';

  @override
  String get nutrition => 'Nutrición';

  @override
  String get visibleMacros => 'Macros visibles';

  @override
  String get defaultRestTimer => 'Temporizador de descanso predeterminado';

  @override
  String get secondsBetweenSets => '60 segundos entre series';

  @override
  String get restTimerComingSoon =>
      'Próximamente: configuración del temporizador de descanso';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get themeComingSoon => 'Próximamente: configuración del tema';

  @override
  String get data => 'Datos';

  @override
  String get exportDatabase => 'Exportar base de datos';

  @override
  String get shareDbFile => 'Compartir el archivo SQLite';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get removeEverything => 'Eliminar todo y empezar de nuevo';

  @override
  String get noDbFound => 'No se encontró archivo de base de datos';

  @override
  String get deleteAllDataTitle => '¿Eliminar todos los datos?';

  @override
  String get deleteAllDataContent =>
      'Esto eliminará todos tus datos, incluyendo comidas, ejercicios, entrenamientos, objetivos y perfil. Se creará una nueva base de datos al reiniciar.';

  @override
  String get dbDeleted =>
      'Base de datos eliminada. Reinicia la aplicación para recrearla.';

  @override
  String get thisMonth => 'Este mes';

  @override
  String get couldNotLoadWeightHistory =>
      'No se pudo cargar el historial de peso.';

  @override
  String get trainingHeatmap => 'Mapa de calor de entrenamientos';

  @override
  String get heatmapLegendLow => 'Bajo';

  @override
  String get heatmapLegendMid => 'Medio';

  @override
  String get heatmapLegendHigh => 'Alto';

  @override
  String get benchPress => 'Press de banca';

  @override
  String get deadlift => 'Peso muerto';

  @override
  String get squat => 'Sentadilla';

  @override
  String get enterDetailsForMacros =>
      'Ingrese sus detalles para los cálculos de macros';

  @override
  String exportFailed(Object error) {
    return 'Error al exportar: $error';
  }

  @override
  String deleteFailed(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get navDiet => 'Comidas';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navExercise => 'Entrenamiento';
}
