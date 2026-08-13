/// Plain domain model for a daily planner task.
final class PlannerItem {
  final String id;
  final DateTime day; // start-of-day
  final String title;
  final bool done;
  final int sortOrder;
  final DateTime?
  dueDate; // optional due date; data + display only (no reminders)
  final int?
  dueTimeMinutes; // optional due time-of-day (schema v8), minutes since midnight
  final String? notes; // optional free-text note
  final String? workoutId; // optional linked workout (schema v11)
  final DateTime createdAt;

  const PlannerItem({
    required this.id,
    required this.day,
    required this.title,
    required this.done,
    required this.sortOrder,
    this.dueDate,
    this.dueTimeMinutes,
    this.notes,
    this.workoutId,
    required this.createdAt,
  });

  /// Sentinel to distinguish "not passed" from "explicitly set to null".
  static const _unset = Object();

  PlannerItem copyWith({
    String? id,
    DateTime? day,
    String? title,
    bool? done,
    int? sortOrder,
    Object? dueDate = _unset,
    Object? dueTimeMinutes = _unset,
    Object? notes = _unset,
    Object? workoutId = _unset,
    DateTime? createdAt,
  }) => PlannerItem(
    id: id ?? this.id,
    day: day ?? this.day,
    title: title ?? this.title,
    done: done ?? this.done,
    sortOrder: sortOrder ?? this.sortOrder,
    dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
    dueTimeMinutes: identical(dueTimeMinutes, _unset)
        ? this.dueTimeMinutes
        : dueTimeMinutes as int?,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    workoutId: identical(workoutId, _unset)
        ? this.workoutId
        : workoutId as String?,
    createdAt: createdAt ?? this.createdAt,
  );
}
