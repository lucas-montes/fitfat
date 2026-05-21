class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.category = 'General',
  });

  final String id;
  final String name;
  final String category;
}

class ExerciseSet {
  const ExerciseSet({required this.reps, required this.weight});

  final int reps;
  final double weight;
}

class ExerciseEntry {
  const ExerciseEntry({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.startedAt,
    this.completedAt,
  });

  final String id;
  final ExerciseDefinition exercise;
  final List<ExerciseSet> sets;
  final DateTime startedAt;
  final DateTime? completedAt;

  double get totalWeight =>
      sets.fold(0.0, (sum, set) => sum + (set.reps * set.weight));
  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);
}

class Seance {
  const Seance({
    required this.id,
    this.name,
    required this.startedAt,
    required this.exercises,
    this.completedAt,
    this.restBetweenSets = const Duration(seconds: 60),
  });

  final String id;
  final String? name;
  final DateTime startedAt;
  final List<ExerciseEntry> exercises;
  final DateTime? completedAt;
  final Duration restBetweenSets;

  Duration get duration {
    if (completedAt == null) {
      return DateTime.now().difference(startedAt);
    }
    return completedAt!.difference(startedAt);
  }

  bool get isActive => completedAt == null;
}
