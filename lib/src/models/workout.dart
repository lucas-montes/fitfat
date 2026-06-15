import 'package:flutter/foundation.dart';

import 'exercise.dart';

/// One set within a weightlifting WorkoutEntry.
@immutable
class WeightSet {
  const WeightSet({
    required this.reps,
    required this.weightKg,
    this.completedAt,
  });

  final int reps;
  final double weightKg;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  WeightSet copyWith({int? reps, double? weightKg, DateTime? completedAt}) {
    return WeightSet(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weightKg': weightKg,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory WeightSet.fromJson(Map<String, dynamic> json) => WeightSet(
    reps: json['reps'] as int,
    weightKg: (json['weightKg'] as num).toDouble(),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}

/// Duration-based data for a cardio-type WorkoutEntry.
@immutable
class CardioDetail {
  const CardioDetail({required this.durationMinutes});

  final int durationMinutes;

  CardioDetail copyWith({int? durationMinutes}) {
    return CardioDetail(
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toJson() => {'durationMinutes': durationMinutes};

  factory CardioDetail.fromJson(Map<String, dynamic> json) =>
      CardioDetail(durationMinutes: json['durationMinutes'] as int);
}

/// One exercise within a Workout. Either weightlifting (with WeightSets)
/// or cardio (with CardioDetail), determined by the ExerciseDefinition type.
@immutable
class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.exercise,
    this.sets = const [],
    this.cardioDetail,
    this.sortOrder = 0,
    this.note,
    this.effort,
  });

  final String id;
  final ExerciseDefinition exercise;
  final List<WeightSet> sets;
  final CardioDetail? cardioDetail;
  final int sortOrder;
  final String? note;
  final int? effort;

  /// Total volume (reps × weight) for weightlifting entries.
  double get totalWeight =>
      sets.fold(0.0, (sum, set) => sum + (set.reps * set.weightKg));

  /// Total reps across all sets for weightlifting entries.
  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  WorkoutEntry copyWith({
    String? id,
    ExerciseDefinition? exercise,
    List<WeightSet>? sets,
    CardioDetail? cardioDetail,
    int? sortOrder,
    String? note,
    int? effort,
    bool clearCardioDetail = false,
  }) {
    return WorkoutEntry(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      cardioDetail: clearCardioDetail
          ? null
          : (cardioDetail ?? this.cardioDetail),
      sortOrder: sortOrder ?? this.sortOrder,
      note: note ?? this.note,
      effort: effort ?? this.effort,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise': exercise.toJson(),
    'sets': sets.map((s) => s.toJson()).toList(),
    'cardioDetail': cardioDetail?.toJson(),
    'sortOrder': sortOrder,
    'note': note,
    'effort': effort,
  };

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) => WorkoutEntry(
    id: json['id'] as String,
    exercise: ExerciseDefinition.fromJson(
      json['exercise'] as Map<String, dynamic>,
    ),
    sets:
        (json['sets'] as List?)
            ?.map((s) => WeightSet.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    cardioDetail: json['cardioDetail'] != null
        ? CardioDetail.fromJson(json['cardioDetail'] as Map<String, dynamic>)
        : null,
    sortOrder: json['sortOrder'] as int? ?? 0,
    note: json['note'] as String?,
    effort: json['effort'] as int?,
  );
}

/// A completed or in-progress workout session in the unified activity model.
@immutable
class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.entries = const [],
    this.notes,
    this.source = 'manual',
    this.plannedWorkoutId,
    this.isGuided = false,
  });

  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutEntry> entries;
  final String? notes;
  final String source;
  final String? plannedWorkoutId;
  final bool isGuided;

  /// Duration of the workout (current elapsed time if active).
  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  /// Whether this workout is still in progress.
  bool get isActive => endTime == null;

  /// Total volume across all weightlifting entries.
  double get totalVolume =>
      entries.fold(0.0, (sum, entry) => sum + entry.totalWeight);

  /// Total cardio minutes across all cardio entries.
  int get totalCardioMinutes => entries.fold(
    0,
    (sum, entry) => sum + (entry.cardioDetail?.durationMinutes ?? 0),
  );

  Workout copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutEntry>? entries,
    String? notes,
    String? source,
    String? plannedWorkoutId,
    bool? isGuided,
    bool clearEndTime = false,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      entries: entries ?? this.entries,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      plannedWorkoutId: plannedWorkoutId ?? this.plannedWorkoutId,
      isGuided: isGuided ?? this.isGuided,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'notes': notes,
    'source': source,
    'plannedWorkoutId': plannedWorkoutId,
    'isGuided': isGuided,
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'] as String)
        : null,
    entries:
        (json['entries'] as List?)
            ?.map((e) => WorkoutEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    notes: json['notes'] as String?,
    source: json['source'] as String? ?? 'manual',
    plannedWorkoutId: json['plannedWorkoutId'] as String?,
    isGuided: json['isGuided'] as bool? ?? false,
  );
}

// ---------------------------------------------------------------------------
// Planning domain models
// ---------------------------------------------------------------------------

/// Coach-prescribed duration for a cardio-type PlannedEntry.
@immutable
class PlannedCardio {
  const PlannedCardio({required this.plannedDurationMinutes});

  final int plannedDurationMinutes;

  PlannedCardio copyWith({int? plannedDurationMinutes}) {
    return PlannedCardio(
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'plannedDurationMinutes': plannedDurationMinutes,
  };

  factory PlannedCardio.fromJson(Map<String, dynamic> json) => PlannedCardio(
    plannedDurationMinutes: json['plannedDurationMinutes'] as int,
  );
}

/// One prescribed exercise within a PlannedWorkout.
@immutable
class PlannedEntry {
  const PlannedEntry({
    required this.id,
    required this.exercise,
    this.plannedReps = 0,
    this.plannedWeightKg = 0.0,
    this.plannedRestSeconds,
    this.sortOrder = 0,
    this.note,
    this.effortTarget,
    this.plannedCardio,
  });

  final String id;
  final ExerciseDefinition exercise;
  final int plannedReps;
  final double plannedWeightKg;
  final int? plannedRestSeconds;
  final int sortOrder;
  final String? note;
  final int? effortTarget;
  final PlannedCardio? plannedCardio;

  PlannedEntry copyWith({
    String? id,
    ExerciseDefinition? exercise,
    int? plannedReps,
    double? plannedWeightKg,
    int? plannedRestSeconds,
    int? sortOrder,
    String? note,
    int? effortTarget,
    PlannedCardio? plannedCardio,
    bool clearPlannedCardio = false,
  }) {
    return PlannedEntry(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      plannedReps: plannedReps ?? this.plannedReps,
      plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
      plannedRestSeconds: plannedRestSeconds ?? this.plannedRestSeconds,
      sortOrder: sortOrder ?? this.sortOrder,
      note: note ?? this.note,
      effortTarget: effortTarget ?? this.effortTarget,
      plannedCardio: clearPlannedCardio
          ? null
          : (plannedCardio ?? this.plannedCardio),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise': exercise.toJson(),
    'plannedReps': plannedReps,
    'plannedWeightKg': plannedWeightKg,
    'plannedRestSeconds': plannedRestSeconds,
    'sortOrder': sortOrder,
    'note': note,
    'effortTarget': effortTarget,
    'plannedCardio': plannedCardio?.toJson(),
  };

  factory PlannedEntry.fromJson(Map<String, dynamic> json) => PlannedEntry(
    id: json['id'] as String,
    exercise: ExerciseDefinition.fromJson(
      json['exercise'] as Map<String, dynamic>,
    ),
    plannedReps: json['plannedReps'] as int? ?? 0,
    plannedWeightKg: (json['plannedWeightKg'] as num?)?.toDouble() ?? 0.0,
    plannedRestSeconds: json['plannedRestSeconds'] as int?,
    sortOrder: json['sortOrder'] as int? ?? 0,
    note: json['note'] as String?,
    effortTarget: json['effortTarget'] as int?,
    plannedCardio: json['plannedCardio'] != null
        ? PlannedCardio.fromJson(json['plannedCardio'] as Map<String, dynamic>)
        : null,
  );
}

/// A workout scheduled for a specific date, with prescribed weights
/// from a coach or manual entry. Can be converted to a Workout when started.
@immutable
class PlannedWorkout {
  const PlannedWorkout({
    required this.id,
    required this.scheduledDate,
    required this.name,
    this.entries = const [],
    this.notes,
    this.source = 'manual',
    this.templateId,
    this.isCompleted = false,
    this.completedWorkoutId,
  });

  final String id;
  final DateTime scheduledDate;
  final String name;
  final List<PlannedEntry> entries;
  final String? notes;
  final String source;
  final String? templateId;
  final bool isCompleted;
  final String? completedWorkoutId;

  PlannedWorkout copyWith({
    String? id,
    DateTime? scheduledDate,
    String? name,
    List<PlannedEntry>? entries,
    String? notes,
    String? source,
    String? templateId,
    bool? isCompleted,
    String? completedWorkoutId,
  }) {
    return PlannedWorkout(
      id: id ?? this.id,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      templateId: templateId ?? this.templateId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedWorkoutId: completedWorkoutId ?? this.completedWorkoutId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduledDate': scheduledDate.toIso8601String(),
    'name': name,
    'entries': entries.map((e) => e.toJson()).toList(),
    'notes': notes,
    'source': source,
    'templateId': templateId,
    'isCompleted': isCompleted,
    'completedWorkoutId': completedWorkoutId,
  };

  factory PlannedWorkout.fromJson(Map<String, dynamic> json) => PlannedWorkout(
    id: json['id'] as String,
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    name: json['name'] as String? ?? '',
    entries:
        (json['entries'] as List?)
            ?.map((e) => PlannedEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    notes: json['notes'] as String?,
    source: json['source'] as String? ?? 'manual',
    templateId: json['templateId'] as String?,
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedWorkoutId: json['completedWorkoutId'] as String?,
  );
}
