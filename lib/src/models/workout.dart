import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum ExerciseType { weightlifting, cardio }

enum BodyPart {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  abdominals,
  obliques,
  traps,
  lats,
  neck,
  fullBody,
}

enum WorkoutSource { manual, coach, quickLog }

// ---------------------------------------------------------------------------
// ExerciseDefinition
// ---------------------------------------------------------------------------

@immutable
class ExerciseDefinition {
  final String id;
  final String name;
  final ExerciseType type;
  final double met;
  final String description;
  final String? imageUrl;
  final List<BodyPart> bodyParts;

  /// Localized name for the current app locale, if a translation exists.
  final String? localizedName;

  /// Localized description for the current app locale, if a translation exists.
  final String? localizedDescription;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.type = ExerciseType.weightlifting,
    this.met = 5.0,
    this.description = '',
    this.imageUrl,
    this.bodyParts = const [],
    this.localizedName,
    this.localizedDescription,
  });

  ExerciseDefinition copyWith({
    String? id,
    String? name,
    ExerciseType? type,
    double? met,
    String? description,
    String? imageUrl,
    List<BodyPart>? bodyParts,
    String? localizedName,
    String? localizedDescription,
    bool clearImageUrl = false,
    bool clearLocalizedName = false,
    bool clearLocalizedDescription = false,
  }) {
    return ExerciseDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      met: met ?? this.met,
      description: description ?? this.description,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      bodyParts: bodyParts ?? this.bodyParts,
      localizedName: clearLocalizedName
          ? null
          : (localizedName ?? this.localizedName),
      localizedDescription: clearLocalizedDescription
          ? null
          : (localizedDescription ?? this.localizedDescription),
    );
  }
}

// ---------------------------------------------------------------------------
// ExerciseTranslation
// ---------------------------------------------------------------------------

/// A localized name/description pair for an exercise in a specific locale.
///
/// Locale codes follow the IETF BCP 47 format (e.g. "en", "fr", "pt-BR").
@immutable
class ExerciseTranslation {
  final String exerciseId;
  final String locale;
  final String name;
  final String description;

  const ExerciseTranslation({
    required this.exerciseId,
    required this.locale,
    required this.name,
    this.description = '',
  });

  ExerciseTranslation copyWith({
    String? exerciseId,
    String? locale,
    String? name,
    String? description,
  }) {
    return ExerciseTranslation(
      exerciseId: exerciseId ?? this.exerciseId,
      locale: locale ?? this.locale,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

// ---------------------------------------------------------------------------
// Workout
// ---------------------------------------------------------------------------

/// A workout is the single model for all workout types:
///
/// | `scheduledDate` | `startedAt` | Meaning         |
/// |-----------------|-------------|-----------------|
/// | null            | not null    | Free-form       |
/// | set             | null        | Scheduled/pending |
/// | set             | not null    | Scheduled, in progress or done |
///
/// `completedAt == null` → active or pending.
/// `completedAt != null` → finished.
@immutable
class Workout {
  final String id;
  final String name;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final WorkoutSource source;

  const Workout({
    required this.id,
    required this.name,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.source = WorkoutSource.manual,
  });

  bool get isScheduled => scheduledDate != null;
  bool get isFreeform => scheduledDate == null;
  bool get isPending => scheduledDate != null && startedAt == null;
  bool get isActive => startedAt != null && completedAt == null;
  bool get isCompleted => completedAt != null;

  Duration get duration {
    if (completedAt != null && startedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    if (startedAt != null) {
      return DateTime.now().difference(startedAt!);
    }
    return Duration.zero;
  }

  Workout copyWith({
    String? id,
    String? name,
    DateTime? scheduledDate,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    WorkoutSource? source,
    bool clearScheduledDate = false,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
    bool clearNotes = false,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      scheduledDate: clearScheduledDate
          ? null
          : (scheduledDate ?? this.scheduledDate),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes: clearNotes ? null : (notes ?? this.notes),
      source: source ?? this.source,
    );
  }
}

// ---------------------------------------------------------------------------
// WeightSet
// ---------------------------------------------------------------------------

/// One weightlifting set within a workout.
///
/// Planned values are pre-filled when creating a scheduled workout.
/// Actual values are filled during execution (null = not yet done).
/// For free-form workouts, planned = actual from the start.
@immutable
class WeightSet {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int sortOrder;
  final int plannedReps;
  final double plannedWeightKg;
  final int? plannedRestSeconds;
  final int? actualReps;
  final double? actualWeightKg;
  final DateTime? completedAt;
  final String? notes;
  final bool isFailed;

  const WeightSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.plannedReps = 0,
    this.plannedWeightKg = 0.0,
    this.plannedRestSeconds,
    this.actualReps,
    this.actualWeightKg,
    this.completedAt,
    this.notes,
    this.isFailed = false,
  });

  bool get isCompleted => completedAt != null;
  int get effectiveReps => actualReps ?? plannedReps;
  double get effectiveWeightKg => actualWeightKg ?? plannedWeightKg;
  double get totalWeight => effectiveReps * effectiveWeightKg;

  int? get repsDelta => actualReps != null ? actualReps! - plannedReps : null;
  double? get weightDelta =>
      actualWeightKg != null ? actualWeightKg! - plannedWeightKg : null;

  WeightSet copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sortOrder,
    int? plannedReps,
    double? plannedWeightKg,
    int? plannedRestSeconds,
    int? actualReps,
    double? actualWeightKg,
    DateTime? completedAt,
    String? notes,
    bool? isFailed,
    bool clearPlannedRestSeconds = false,
    bool clearActualReps = false,
    bool clearActualWeightKg = false,
    bool clearCompletedAt = false,
    bool clearNotes = false,
    bool clearIsFailed = false,
  }) {
    return WeightSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      plannedReps: plannedReps ?? this.plannedReps,
      plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
      plannedRestSeconds: clearPlannedRestSeconds
          ? null
          : (plannedRestSeconds ?? this.plannedRestSeconds),
      actualReps: clearActualReps ? null : (actualReps ?? this.actualReps),
      actualWeightKg: clearActualWeightKg
          ? null
          : (actualWeightKg ?? this.actualWeightKg),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes: clearNotes ? null : (notes ?? this.notes),
      isFailed: clearIsFailed ? false : (isFailed ?? this.isFailed),
    );
  }
}

// ---------------------------------------------------------------------------
// CardioSet
// ---------------------------------------------------------------------------

/// One cardio set within a workout.
///
/// Planned values are pre-filled when creating a scheduled workout.
/// Actual values are filled during execution (null = not yet done).
@immutable
class CardioSet {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int sortOrder;
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final DateTime? completedAt;
  final String? notes;
  final bool isFailed;

  const CardioSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.plannedDurationMinutes = 0,
    this.actualDurationMinutes,
    this.completedAt,
    this.notes,
    this.isFailed = false,
  });

  bool get isCompleted => completedAt != null;
  int get effectiveDurationMinutes =>
      actualDurationMinutes ?? plannedDurationMinutes;
  int? get durationDelta => actualDurationMinutes != null
      ? actualDurationMinutes! - plannedDurationMinutes
      : null;

  CardioSet copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sortOrder,
    int? plannedDurationMinutes,
    int? actualDurationMinutes,
    DateTime? completedAt,
    String? notes,
    bool? isFailed,
    bool clearActualDurationMinutes = false,
    bool clearCompletedAt = false,
    bool clearNotes = false,
    bool clearIsFailed = false,
  }) {
    return CardioSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes: clearActualDurationMinutes
          ? null
          : (actualDurationMinutes ?? this.actualDurationMinutes),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes: clearNotes ? null : (notes ?? this.notes),
      isFailed: clearIsFailed ? false : (isFailed ?? this.isFailed),
    );
  }
}
