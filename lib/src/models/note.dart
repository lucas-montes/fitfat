/// Plain domain model for a free-form note (Notes tab, schema v9; tags v26).
final class Note {
  final String id;
  final String title;
  final String body;

  /// Tag names from the shared vocabulary (JSON string[] at rest).
  final List<String>? tags;
  final DateTime updatedAt;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.tags,
    required this.updatedAt,
    required this.createdAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? body,
    Object? tags = _unset,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    tags: identical(tags, _unset) ? this.tags : tags as List<String>?,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );

  static const _unset = Object();
}
