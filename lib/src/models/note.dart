/// Plain domain model for a free-form note (Notes tab, schema v9).
final class Note {
  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.createdAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
}
