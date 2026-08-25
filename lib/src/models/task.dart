import 'planner_recurrence.dart';

/// Lifecycle of a plain task.
enum TaskStatus { pending, done, cancelled }

extension TaskStatusStorage on TaskStatus {
  int get storage => index;
}

/// Plain domain model for a daily planner task (schema v27: the task half of
/// the former [PlannerItem] union; experiments live in their own table).
final class Task {
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
  final String? workoutId; // optional linked workout (1:1, auto via replay)
  final String? workoutTemplateId; // scheduled occurrence from a template (v28)
  final List<String>? tags; // optional free-form labels (priorities)
  final PlannerRecurrence? recurrence; // optional repeat rule (schema v13)
  final String? seriesId; // groups occurrences of one recurring series
  // Task lifecycle (v25). [done] is kept in sync
  // (done == taskStatus == TaskStatus.done).
  final TaskStatus? taskStatus;
  // When a pending task's day passes: true moves it to today, false marks it
  // cancelled (see TaskRepository.rolloverPastTasks).
  final bool carryOver;
  final DateTime createdAt;

  const Task({
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
    this.workoutTemplateId,
    this.tags,
    this.recurrence,
    this.seriesId,
    this.taskStatus,
    this.carryOver = true,
    required this.createdAt,
  });

  /// Resolved task lifecycle; falls back to [done] when [taskStatus] is unset
  /// (pre-v25 rows).
  TaskStatus get taskState =>
      taskStatus ?? (done ? TaskStatus.done : TaskStatus.pending);

  bool get isCancelled => taskState == TaskStatus.cancelled;

  /// Returns a copy with the given lifecycle, keeping [done] in sync so
  /// existing "completed" checks keep working.
  Task withTaskStatus(TaskStatus status) =>
      copyWith(taskStatus: status, done: status == TaskStatus.done);

  /// Sentinel to distinguish "not passed" from "explicitly set to null".
  static const _unset = Object();

  Task copyWith({
    String? id,
    DateTime? day,
    String? title,
    bool? done,
    Object? taskStatus = _unset,
    bool? carryOver,
    int? sortOrder,
    Object? dueDate = _unset,
    Object? startTimeMinutes = _unset,
    Object? endTimeMinutes = _unset,
    Object? notes = _unset,
    Object? workoutId = _unset,
    Object? workoutTemplateId = _unset,
    Object? tags = _unset,
    Object? recurrence = _unset,
    Object? seriesId = _unset,
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    day: day ?? this.day,
    title: title ?? this.title,
    done: done ?? this.done,
    taskStatus: identical(taskStatus, _unset)
        ? this.taskStatus
        : taskStatus as TaskStatus?,
    carryOver: carryOver ?? this.carryOver,
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
    workoutTemplateId: identical(workoutTemplateId, _unset)
        ? this.workoutTemplateId
        : workoutTemplateId as String?,
    tags: identical(tags, _unset) ? this.tags : tags as List<String>?,
    recurrence: identical(recurrence, _unset)
        ? this.recurrence
        : recurrence as PlannerRecurrence?,
    seriesId: identical(seriesId, _unset) ? this.seriesId : seriesId as String?,
    createdAt: createdAt ?? this.createdAt,
  );
}
