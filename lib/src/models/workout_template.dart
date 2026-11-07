import 'planner_recurrence.dart';

/// The reusable blueprint of a workout routine (schema v28): exercises +
/// planned sets, plus an optional repeat rule whose occurrences materialize
/// as planner tasks (tasks.workout_template_id). Templates hold no session
/// state — starting one snapshots the plan into a workouts row stamped with
/// [Workout.templateId].
final class WorkoutTemplate {
  final String id;
  final String name;
  final String? notes;

  /// Anchor day for the repeat rule (start-of-day). Rules compute upcoming
  /// occurrences relative to it.
  final DateTime startDate;

  /// Optional repeat rule (same shape as planner task recurrence).
  final PlannerRecurrence? recurrence;

  /// Occurrence days (start-of-day ms) the user deleted; the materializer
  /// skips these so deleted stays deleted.
  final Set<int>? excludedDates;

  /// Replay-lineage provenance when auto-promoted from history.
  final String? sourceRoutineId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.notes,
    required this.startDate,
    this.recurrence,
    this.excludedDates,
    this.sourceRoutineId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isScheduled => recurrence?.isValid ?? false;

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    Object? notes = _unset,
    DateTime? startDate,
    Object? recurrence = _unset,
    Object? excludedDates = _unset,
    Object? sourceRoutineId = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkoutTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    startDate: startDate ?? this.startDate,
    recurrence: identical(recurrence, _unset)
        ? this.recurrence
        : recurrence as PlannerRecurrence?,
    excludedDates: identical(excludedDates, _unset)
        ? this.excludedDates
        : excludedDates as Set<int>?,
    sourceRoutineId: identical(sourceRoutineId, _unset)
        ? this.sourceRoutineId
        : sourceRoutineId as String?,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static const _unset = Object();
}

/// One exercise entry inside a [WorkoutTemplate].
final class WorkoutTemplateExercise {
  final String id;
  final String templateId;
  final String exerciseId;
  final int sortOrder;
  final String? notes;

  const WorkoutTemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.sortOrder,
    this.notes,
  });
}

/// Planned-only set values for a [WorkoutTemplateExercise]; actual columns
/// are deliberately absent — those belong to sessions.
final class WorkoutTemplateSet {
  final String id;
  final String templateExerciseId;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? restSeconds;
  final int? durationMinutes;
  final double? distanceMeters;

  const WorkoutTemplateSet({
    required this.id,
    required this.templateExerciseId,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.restSeconds,
    this.durationMinutes,
    this.distanceMeters,
  });
}

/// An exercise block plus its planned sets — the unit the editor and the
/// instantiate flow consume.
final class TemplateBlock {
  final WorkoutTemplateExercise exercise;
  final List<WorkoutTemplateSet> sets;

  const TemplateBlock({required this.exercise, required this.sets});
}

/// A template with its full blueprint, ready to edit or instantiate.
final class WorkoutTemplateDetails {
  final WorkoutTemplate template;
  final List<TemplateBlock> blocks;

  const WorkoutTemplateDetails({required this.template, required this.blocks});
}
