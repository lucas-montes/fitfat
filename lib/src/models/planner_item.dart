import 'experiment.dart';
import 'planner_recurrence.dart';

/// What kind of planner item this is. Experiments are planner items with a
/// start→end date range, lifecycle status and linked data categories; tasks
/// are single-day to-dos.
enum PlannerItemKind { task, experiment }

/// Lifecycle of a plain task. Experiments use [ExperimentStatus] instead.
enum TaskStatus { pending, done, cancelled }

extension TaskStatusStorage on TaskStatus {
  int get storage => index;
}

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
  // Task lifecycle (v25). Null for experiments; for tasks [done] is kept in
  // sync (done == taskStatus == TaskStatus.done).
  final TaskStatus? taskStatus;
  // When a pending task's day passes: true moves it to today, false marks it
  // cancelled (see PlannerRepository.rolloverPastTasks).
  final bool carryOver;

  // Experiment fields (schema v24); ignored for plain tasks.
  final PlannerItemKind kind;
  final DateTime? endDate; // experiment end date (start-of-day)
  final String? purpose; // hypothesis
  final ExperimentStatus? status;
  final List<ExperimentCategory>? categories;
  final bool reminderEnabled;
  final int reminderTimeMinutes; // minutes from midnight
  final String? experimentId; // set on child tasks linked to an experiment

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
    this.taskStatus,
    this.carryOver = true,
    this.kind = PlannerItemKind.task,
    this.endDate,
    this.purpose,
    this.status,
    this.categories,
    this.reminderEnabled = true,
    this.reminderTimeMinutes = 20 * 60,
    this.experimentId,
    required this.createdAt,
  });

  bool get isExperiment => kind == PlannerItemKind.experiment;

  /// Resolved task lifecycle; falls back to [done] when [taskStatus] is unset
  /// (pre-v25 rows, experiments).
  TaskStatus get taskState =>
      taskStatus ?? (done ? TaskStatus.done : TaskStatus.pending);

  bool get isCancelled => taskState == TaskStatus.cancelled;

  /// Returns a copy with the given lifecycle, keeping [done] in sync so
  /// existing "completed" checks keep working.
  PlannerItem withTaskStatus(TaskStatus status) =>
      copyWith(taskStatus: status, done: status == TaskStatus.done);

  /// Sentinel to distinguish "not passed" from "explicitly set to null".
  static const _unset = Object();

  PlannerItem copyWith({
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
    Object? tags = _unset,
    Object? recurrence = _unset,
    Object? seriesId = _unset,
    PlannerItemKind? kind,
    Object? endDate = _unset,
    Object? purpose = _unset,
    Object? status = _unset,
    Object? categories = _unset,
    bool? reminderEnabled,
    int? reminderTimeMinutes,
    Object? experimentId = _unset,
    DateTime? createdAt,
  }) => PlannerItem(
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
    tags: identical(tags, _unset) ? this.tags : tags as List<String>?,
    recurrence: identical(recurrence, _unset)
        ? this.recurrence
        : recurrence as PlannerRecurrence?,
    seriesId: identical(seriesId, _unset) ? this.seriesId : seriesId as String?,
    kind: kind ?? this.kind,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
    purpose: identical(purpose, _unset) ? this.purpose : purpose as String?,
    status: identical(status, _unset)
        ? this.status
        : status as ExperimentStatus?,
    categories: identical(categories, _unset)
        ? this.categories
        : categories as List<ExperimentCategory>?,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
    experimentId: identical(experimentId, _unset)
        ? this.experimentId
        : experimentId as String?,
    createdAt: createdAt ?? this.createdAt,
  );
}
