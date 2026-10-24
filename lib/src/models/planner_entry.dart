import 'task.dart';

/// One entry on the planner timeline: a [Task].
///
/// Day/Week/Month views work against this union so timeline consumers stay
/// decoupled from the task repository. (It used to also carry experiments;
/// that feature was removed in schema v37.)
sealed class PlannerEntry {
  const PlannerEntry();

  String get id;
  String get title;
  DateTime get day;
  List<String>? get tags;

  bool get isTask => this is TaskEntry;

  Task get task => (this as TaskEntry).task;
}

/// A plain scheduled task.
final class TaskEntry extends PlannerEntry {
  @override
  final Task task;

  const TaskEntry(this.task);

  @override
  String get id => task.id;

  @override
  String get title => task.title;

  @override
  DateTime get day => task.day;

  @override
  List<String>? get tags => task.tags;
}
