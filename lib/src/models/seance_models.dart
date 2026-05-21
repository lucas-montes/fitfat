import 'package:flutter/foundation.dart';

@immutable
class PlannedSet {
  const PlannedSet({required this.reps, this.weightKg, this.restSeconds = 60});

  final int reps;
  final double? weightKg;
  final int restSeconds;
}

@immutable
class ExerciseTemplate {
  final String id;
  final String name;
  final List<PlannedSet> plannedSets;

  int get totalSets => plannedSets.length;

  const ExerciseTemplate({
    required this.id,
    required this.name,
    required this.plannedSets,
  });

  ExerciseTemplate copyWith({
    String? id,
    String? name,
    List<PlannedSet>? plannedSets,
  }) {
    return ExerciseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      plannedSets: plannedSets ?? this.plannedSets,
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
