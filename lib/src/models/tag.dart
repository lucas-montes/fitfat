/// Plain domain model for a tag in the shared "priorities" vocabulary
/// (schema v26). Entities reference tags by [name]; this row holds the
/// display metadata (optional color + manual priority order).
final class Tag {
  final String id;
  final String name;

  /// Explicit ARGB color; null = derived deterministically from [name].
  final int? color;

  /// Manual priority rank (lower sorts first).
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tag({
    required this.id,
    required this.name,
    this.color,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    Object? color = _unset,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: identical(color, _unset) ? this.color : color as int?,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static const _unset = Object();
}
