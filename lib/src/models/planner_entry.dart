import 'experiment.dart';
import 'task.dart';

/// One entry on the planner timeline (schema v27): either a [Task] or an
/// [Experiment]. Day/Week/Month views union both tables by date, so timeline
/// consumers work against this union while task- or experiment-specific flows
/// pattern-match to the concrete variant.
sealed class PlannerEntry {
  const PlannerEntry();

  String get id;
  String get title;
  DateTime get day;
  List<String>? get tags;

  bool get isExperiment => this is ExperimentEntry;
  bool get isTask => this is TaskEntry;

  Task get task => (this as TaskEntry).task;
  Experiment get experiment => (this as ExperimentEntry).experiment;
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

/// An experiment occupying a start→end date range on the timeline.
final class ExperimentEntry extends PlannerEntry {
  @override
  final Experiment experiment;

  const ExperimentEntry(this.experiment);

  @override
  String get id => experiment.id;

  @override
  String get title => experiment.name;

  @override
  DateTime get day => experiment.startDate;

  @override
  List<String>? get tags => experiment.tags;
}
