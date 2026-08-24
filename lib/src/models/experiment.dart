/// Lifecycle stage of an [Experiment].
enum ExperimentStatus { planned, active, done, aborted }

/// A domain category an experiment links to; charts are aggregated per-category.
enum ExperimentCategory { workout, diet, body, steps }

/// Plain domain model for a self-tracking experiment with daily check-ins.
final class Experiment {
  final String id;
  final String name;
  final String? purpose;

  /// Start-of-day (inclusive). The 14-day baseline ends the day before.
  final DateTime startDate;

  /// Null = open-ended.
  final DateTime? endDate;
  final ExperimentStatus status;
  final List<ExperimentCategory> categories;

  /// Tag names from the shared vocabulary ("priorities"); stored on the
  /// underlying planner item's JSON tags column.
  final List<String>? tags;
  final bool reminderEnabled;

  /// Daily check-in reminder time as minutes from midnight (default 20:00).
  final int reminderTimeMinutes;
  final DateTime createdAt;

  const Experiment({
    required this.id,
    required this.name,
    this.purpose,
    required this.startDate,
    this.endDate,
    required this.status,
    this.categories = const [],
    this.tags,
    this.reminderEnabled = true,
    this.reminderTimeMinutes = 20 * 60,
    required this.createdAt,
  });

  bool get isActive => status == ExperimentStatus.active;
}

extension ExperimentStatusStorage on ExperimentStatus {
  String get storage => switch (this) {
    ExperimentStatus.planned => 'planned',
    ExperimentStatus.active => 'active',
    ExperimentStatus.done => 'done',
    ExperimentStatus.aborted => 'aborted',
  };
}

extension ExperimentCategoryStorage on ExperimentCategory {
  String get storage => switch (this) {
    ExperimentCategory.workout => 'workout',
    ExperimentCategory.diet => 'diet',
    ExperimentCategory.body => 'body',
    ExperimentCategory.steps => 'steps',
  };
}

/// One daily check-in (rating + optional note) for an experiment.
final class ExperimentCheckin {
  final String id;
  final String experimentId;

  /// Start-of-day key; unique per experiment.
  final DateTime day;

  /// 1..5 scale.
  final int rating;
  final String? note;
  final DateTime createdAt;

  const ExperimentCheckin({
    required this.id,
    required this.experimentId,
    required this.day,
    required this.rating,
    this.note,
    required this.createdAt,
  });
}
