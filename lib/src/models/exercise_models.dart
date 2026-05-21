class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.category = 'General',
  });

  final String id;
  final String name;
  final String category;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
  };

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) =>
      ExerciseDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'General',
      );
}

class ExerciseSet {
  const ExerciseSet({required this.reps, required this.weight});

  final int reps;
  final double weight;

  Map<String, dynamic> toJson() => {'reps': reps, 'weight': weight};

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    reps: json['reps'] as int,
    weight: (json['weight'] as num).toDouble(),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise': exercise.toJson(),
    'sets': sets.map((s) => s.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
    id: json['id'] as String,
    exercise: ExerciseDefinition.fromJson(
      json['exercise'] as Map<String, dynamic>,
    ),
    sets: (json['sets'] as List)
        .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
        .toList(),
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startedAt': startedAt.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'completedAt': completedAt?.toIso8601String(),
    'restBetweenSetsMillis': restBetweenSets.inMilliseconds,
  };

  factory Seance.fromJson(Map<String, dynamic> json) => Seance(
    id: json['id'] as String,
    name: json['name'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    exercises: (json['exercises'] as List)
        .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    restBetweenSets: Duration(
      milliseconds: json['restBetweenSetsMillis'] as int? ?? 60000,
    ),
  );
}
