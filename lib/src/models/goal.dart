/// Lifecycle stage of a [Goal].
enum GoalStatus { planned, active, done, aborted }

/// What kind of target a goal tracks.
enum GoalTargetType {
  /// No measurable target — progress is the lifecycle itself.
  none,

  /// A numeric value to reach ([Goal.targetValue], optional unit).
  numeric,

  /// Achieve / don't achieve; progress entries record 0 or 1.
  boolean,
}

extension GoalStatusStorage on GoalStatus {
  String get storage => switch (this) {
    GoalStatus.planned => 'planned',
    GoalStatus.active => 'active',
    GoalStatus.done => 'done',
    GoalStatus.aborted => 'aborted',
  };

  static GoalStatus parse(String raw) => GoalStatus.values.firstWhere(
    (s) => s.storage == raw,
    orElse: () => GoalStatus.planned,
  );
}

extension GoalTargetTypeStorage on GoalTargetType {
  String get storage => switch (this) {
    GoalTargetType.none => 'none',
    GoalTargetType.numeric => 'numeric',
    GoalTargetType.boolean => 'boolean',
  };

  static GoalTargetType parse(String raw) => GoalTargetType.values.firstWhere(
    (t) => t.storage == raw,
    orElse: () => GoalTargetType.none,
  );
}

/// Plain domain model for a long-term outcome (schema v26). Linked to
/// priorities via its [tags] names from the shared vocabulary and tracked
/// against an optional target with daily progress entries.
final class Goal {
  final String id;
  final String title;
  final String? description;

  /// Tag names from the shared vocabulary ("priorities").
  final List<String>? tags;

  /// Start-of-day (inclusive).
  final DateTime startDate;

  /// Null = open-ended.
  final DateTime? endDate;
  final GoalStatus status;
  final GoalTargetType targetType;

  /// Target value for [GoalTargetType.numeric]; null otherwise.
  final double? targetValue;

  /// Optional starting point for numeric targets; progress is measured from
  /// [baselineValue] → [targetValue]. Null = start from zero.
  final double? baselineValue;

  /// Optional unit label ('kg', 'km', …).
  final String? unit;

  // Daily goal reminder (v27); scheduled while the goal is active.
  final bool reminderEnabled;
  final int reminderTimeMinutes; // minutes from midnight
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    this.tags,
    required this.startDate,
    this.endDate,
    this.status = GoalStatus.planned,
    this.targetType = GoalTargetType.none,
    this.targetValue,
    this.baselineValue,
    this.unit,
    this.reminderEnabled = false,
    this.reminderTimeMinutes = 20 * 60,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == GoalStatus.active;

  /// 0..1 progress derived from the latest recorded value, or null when the
  /// goal has no measurable target or no entries yet. Numeric progress runs
  /// from [baselineValue] (or zero) toward [targetValue].
  double? progressFrom(double? latestValue) {
    if (targetType == GoalTargetType.none || latestValue == null) return null;
    if (targetType == GoalTargetType.boolean) {
      return latestValue >= 1 ? 1.0 : 0.0;
    }
    final target = targetValue;
    if (target == null) return null;
    final baseline = baselineValue ?? 0;
    final span = target - baseline;
    if (span == 0) return null;
    return ((latestValue - baseline) / span).clamp(0.0, 1.0);
  }

  Goal copyWith({
    String? id,
    String? title,
    Object? description = _unset,
    Object? tags = _unset,
    DateTime? startDate,
    Object? endDate = _unset,
    GoalStatus? status,
    GoalTargetType? targetType,
    Object? targetValue = _unset,
    Object? baselineValue = _unset,
    Object? unit = _unset,
    bool? reminderEnabled,
    int? reminderTimeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    title: title ?? this.title,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    tags: identical(tags, _unset) ? this.tags : tags as List<String>?,
    startDate: startDate ?? this.startDate,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
    status: status ?? this.status,
    targetType: targetType ?? this.targetType,
    targetValue: identical(targetValue, _unset)
        ? this.targetValue
        : targetValue as double?,
    baselineValue: identical(baselineValue, _unset)
        ? this.baselineValue
        : baselineValue as double?,
    unit: identical(unit, _unset) ? this.unit : unit as String?,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static const _unset = Object();
}

/// One progress measurement for a [Goal]; unique per goal per day —
/// re-recording on the same day overwrites.
final class GoalProgress {
  final String id;
  final String goalId;

  /// Start-of-day the entry was recorded on.
  final DateTime day;
  final double value;
  final String? note;
  final DateTime createdAt;

  const GoalProgress({
    required this.id,
    required this.goalId,
    required this.day,
    required this.value,
    this.note,
    required this.createdAt,
  });
}
