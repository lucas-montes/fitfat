/// Plain domain model for an exercise definition.
final class Exercise {
  final String id;
  final String name;
  final String exerciseType; // 'weightlifting' | 'cardio'
  final DateTime createdAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.exerciseType,
    required this.createdAt,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? exerciseType,
    DateTime? createdAt,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    exerciseType: exerciseType ?? this.exerciseType,
    createdAt: createdAt ?? this.createdAt,
  );

  bool get isWeightlifting => exerciseType == 'weightlifting';
  bool get isCardio => exerciseType == 'cardio';
}
