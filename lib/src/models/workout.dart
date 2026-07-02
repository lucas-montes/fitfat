/// Plain domain model for a workout session.
final class Workout {
  final String id;
  final String name;
  final DateTime date;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;

  const Workout({
    required this.id,
    required this.name,
    required this.date,
    this.startedAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
  });

  Workout copyWith({
    String? id,
    String? name,
    DateTime? date,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) => Workout(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt ?? this.createdAt,
  );

  bool get isPending => startedAt == null;
  bool get isActive => startedAt != null && completedAt == null;
  bool get isCompleted => completedAt != null;

  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}
