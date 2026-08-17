/// Recurrence rule for a planner task. A recurring task stores one "anchor"
/// instance (the one the user created) carrying this rule plus a [seriesId];
/// every other occurrence is a concrete [PlannerItem] generated on matching
/// days. Works for both Anytime (no time) and Scheduled tasks — the rule is
/// evaluated purely against each day, independent of the task's time.
final class PlannerRecurrence {
  final PlannerRecurrenceType type;
  final Set<int>? weekdays; // 1..7 (DateTime.weekday) — weekly only
  final int? intervalDays; // >=1 — interval ("every N days") only
  final int? monthDay; // 1..31 — monthly only
  final DateTime? endDate; // inclusive last occurrence day
  final int? count; // max total occurrences (including the anchor)
  // Start-of-day epoch millis of occurrences the user deleted; the materializer
  // skips these so a deleted occurrence of a series is not regenerated.
  final Set<int>? excludedDates;

  const PlannerRecurrence({
    required this.type,
    this.weekdays,
    this.intervalDays,
    this.monthDay,
    this.endDate,
    this.count,
    this.excludedDates,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (weekdays != null) 'weekdays': [...weekdays!]..sort(),
    if (intervalDays != null) 'intervalDays': intervalDays,
    if (monthDay != null) 'monthDay': monthDay,
    if (endDate != null) 'endDate': endDate!.millisecondsSinceEpoch,
    if (count != null) 'count': count,
    if (excludedDates != null)
      'excludedDates': [...excludedDates!]..sort(),
  };

  factory PlannerRecurrence.fromJson(Map<String, dynamic> json) {
    final endDate = json['endDate'];
    final excluded = json['excludedDates'];
    return PlannerRecurrence(
      type: PlannerRecurrenceType.values.byName(json['type'] as String),
      weekdays: json['weekdays'] is List
          ? {...(json['weekdays'] as List).cast<num>().map((e) => e.toInt())}
          : null,
      intervalDays: json['intervalDays'] as int?,
      monthDay: json['monthDay'] as int?,
      endDate: endDate is int
          ? DateTime.fromMillisecondsSinceEpoch(endDate)
          : null,
      count: json['count'] as int?,
      excludedDates: excluded is List
          ? {...excluded.cast<num>().map((e) => e.toInt())}
          : null,
    );
  }

  /// True if [day] is an occurrence of this rule, whose series started on
  /// [start] (start-of-day).
  bool isOccurrenceOn(DateTime start, DateTime day) {
    final index = occurrenceIndex(start, day);
    if (index < 0) return false;
    if (count != null && index >= count!) return false;
    if (endDate != null && _startOfDay(day).isAfter(_startOfDay(endDate!))) {
      return false;
    }
    return true;
  }

  /// 0-based index of [day] among occurrences starting at [start]; -1 when
  /// [day] is not an occurrence.
  int occurrenceIndex(DateTime start, DateTime day) {
    final d = _startOfDay(day);
    final s = _startOfDay(start);
    if (d.isBefore(s)) return -1;
    return switch (type) {
      PlannerRecurrenceType.daily => _daysBetween(s, d),
      PlannerRecurrenceType.interval => _intervalIndex(s, d),
      PlannerRecurrenceType.weekly => _weekdayIndex(s, d, weekdays ?? const {}),
      PlannerRecurrenceType.monthly => _monthlyIndex(s, d),
    };
  }

  int _intervalIndex(DateTime start, DateTime day) {
    final step = intervalDays ?? 1;
    final delta = _daysBetween(start, day);
    if (delta % step != 0) return -1;
    return delta ~/ step;
  }

  int _monthlyIndex(DateTime start, DateTime day) {
    final targetDay = monthDay ?? start.day;
    if (day.day != targetDay) return -1;
    return _monthsBetween(start, day);
  }

  /// Validates required sub-fields for the chosen [type].
  bool get isValid {
    return switch (type) {
      PlannerRecurrenceType.weekly => (weekdays?.isNotEmpty ?? false),
      PlannerRecurrenceType.interval => (intervalDays ?? 0) >= 1,
      PlannerRecurrenceType.monthly =>
        monthDay != null && monthDay! >= 1 && monthDay! <= 31,
      PlannerRecurrenceType.daily => true,
    };
  }

  static int _daysBetween(DateTime a, DateTime b) => b.difference(a).inDays;

  static int _monthsBetween(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + (b.month - a.month);

  static int _weekdayIndex(DateTime start, DateTime day, Set<int> weekdays) {
    if (weekdays.isEmpty || !weekdays.contains(day.weekday)) return -1;
    var count = 0;
    var cur = start;
    while (!cur.isAfter(day)) {
      if (weekdays.contains(cur.weekday)) count++;
      cur = cur.add(const Duration(days: 1));
    }
    return count - 1; // anchor is index 0
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}

enum PlannerRecurrenceType { daily, weekly, interval, monthly }
