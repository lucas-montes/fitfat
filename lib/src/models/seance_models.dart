import 'package:flutter/foundation.dart';

@immutable
class ExerciseTemplate {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double? plannedWeightKg;
  final int restSeconds;

  const ExerciseTemplate({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.plannedWeightKg,
    required this.restSeconds,
  });

  ExerciseTemplate copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    double? plannedWeightKg,
    int? restSeconds,
  }) {
    return ExerciseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}

@immutable
class SeanceTemplate {
  final String id;
  final String name;
  final DateTime? scheduledFor;
  final List<ExerciseTemplate> exercises;

  const SeanceTemplate({
    required this.id,
    required this.name,
    this.scheduledFor,
    this.exercises = const [],
  });

  SeanceTemplate copyWith({
    String? id,
    String? name,
    DateTime? scheduledFor,
    List<ExerciseTemplate>? exercises,
  }) {
    return SeanceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      exercises: exercises ?? this.exercises,
    );
  }
}

@immutable
class ExerciseHistoryItem {
  final String id;
  final String exerciseId;
  final DateTime timestamp;
  final int reps;
  final double weightKg;
  final int restSeconds;

  const ExerciseHistoryItem({
    required this.id,
    required this.exerciseId,
    required this.timestamp,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
  });
}
