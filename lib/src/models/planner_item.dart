import 'planner_recurrence.dart';

/// Plain domain model for a daily planner task.
final class PlannerItem {
  final String id;
  final DateTime day; // start-of-day
  final String title;
  final bool done;
  final int sortOrder;
  final DateTime?
  dueDate; // optional separate due date; data + display only (no reminders)
  final int?
  startTimeMinutes; // optional start time-of-day (schema v15), minutes since midnight
  final int?
  endTimeMinutes; // optional end time-of-day (schema v15); null = open-ended
  final String? notes; // optional free-text note
  final String? workoutId; // optional linked workout (schema v11)
  final List<String>? tags; // optional free-form labels (schema v12)
  final PlannerRecurrence? recurrence; // optional repeat rule (schema v13)
  final String? seriesId; // groups occurrences of one recurring series
  final DateTime createdAt;

  const PlannerItem({
    required this.id,
    required this.day,
    required this.title,
    required this.done,
    required this.sortOrder,
    this.dueDate,
    this.startTimeMinutes,
    this.endTimeMinutes,
    this.notes,
    this.workoutId,
    this.tags,
    this.recurrence,
    this.seriesId,
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
    Object? startTimeMinutes = _unset,
    Object? endTimeMinutes = _unset,
    Object? notes = _unset,
    Object? workoutId = _unset,
    Object? tags = _unset,
    Object? recurrence = _unset,
    Object? seriesId = _unset,
    DateTime? createdAt,
  }) => PlannerItem(
    id: id ?? this.id,
    day: day ?? this.day,
    title: title ?? this.title,
    done: done ?? this.done,
    sortOrder: sortOrder ?? this.sortOrder,
    dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
    startTimeMinutes: identical(startTimeMinutes, _unset)
        ? this.startTimeMinutes
        : startTimeMinutes as int?,
    endTimeMinutes: identical(endTimeMinutes, _unset)
        ? this.endTimeMinutes
        : endTimeMinutes as int?,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    workoutId: identical(workoutId, _unset)
        ? this.workoutId
        : workoutId as String?,
    tags: identical(tags, _unset) ? this.tags : tags as List<String>?,
    recurrence: identical(recurrence, _unset)
        ? this.recurrence
        : recurrence as PlannerRecurrence?,
    seriesId: identical(seriesId, _unset) ? this.seriesId : seriesId as String?,
    createdAt: createdAt ?? this.createdAt,
  );
}
