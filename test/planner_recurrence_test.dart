import 'package:flutter_test/flutter_test.dart';

import 'package:fitfat/src/models/planner_recurrence.dart';

void main() {
  final start = DateTime(2026, 1, 1); // Thursday

  group('daily', () {
    final r = PlannerRecurrence(type: PlannerRecurrenceType.daily);
    test('anchor day is occurrence 0', () {
      expect(r.isOccurrenceOn(start, start), isTrue);
      expect(r.occurrenceIndex(start, start), 0);
    });
    test('next days increment by one', () {
      expect(r.occurrenceIndex(start, start.add(const Duration(days: 3))), 3);
      expect(
        r.isOccurrenceOn(start, start.add(const Duration(days: 3))),
        isTrue,
      );
    });
    test('past day is not an occurrence', () {
      expect(
        r.isOccurrenceOn(start, start.subtract(const Duration(days: 1))),
        isFalse,
      );
    });
  });

  group('interval', () {
    final r = PlannerRecurrence(
      type: PlannerRecurrenceType.interval,
      intervalDays: 3,
    );
    test('multiple of step is an occurrence', () {
      final d = start.add(const Duration(days: 6));
      expect(r.isOccurrenceOn(start, d), isTrue);
      expect(r.occurrenceIndex(start, d), 2);
    });
    test('non-multiple of step is not an occurrence', () {
      expect(
        r.isOccurrenceOn(start, start.add(const Duration(days: 1))),
        isFalse,
      );
      expect(
        r.isOccurrenceOn(start, start.add(const Duration(days: 4))),
        isFalse,
      );
    });
  });

  group('weekly', () {
    final r = PlannerRecurrence(
      type: PlannerRecurrenceType.weekly,
      weekdays: {1}, // Mondays
    );
    test('matching weekday counts occurrences', () {
      // Jan 1 2026 is a Thursday; first Monday after is Jan 5 (index 0).
      final monday = DateTime(2026, 1, 5);
      expect(r.isOccurrenceOn(start, monday), isTrue);
      expect(r.occurrenceIndex(start, monday), 0);
      expect(r.occurrenceIndex(start, DateTime(2026, 1, 12)), 1);
    });
    test('non-matching weekday is not an occurrence', () {
      expect(r.isOccurrenceOn(start, DateTime(2026, 1, 6)), isFalse);
    });
  });

  group('monthly', () {
    final r = PlannerRecurrence(
      type: PlannerRecurrenceType.monthly,
      monthDay: 15,
    );
    test('same day-of-month each month', () {
      expect(r.occurrenceIndex(start, DateTime(2026, 2, 15)), 1);
      expect(r.occurrenceIndex(start, DateTime(2026, 3, 15)), 2);
    });
    test('different day-of-month is not an occurrence', () {
      expect(r.isOccurrenceOn(start, DateTime(2026, 2, 16)), isFalse);
    });
    test('defaults to start day-of-month when monthDay is null', () {
      final def = PlannerRecurrence(type: PlannerRecurrenceType.monthly);
      expect(def.occurrenceIndex(start, DateTime(2026, 4, 1)), 3);
      expect(def.isOccurrenceOn(start, DateTime(2026, 2, 28)), isFalse);
    });
  });

  group('end conditions', () {
    test('count caps occurrences', () {
      final r = PlannerRecurrence(type: PlannerRecurrenceType.daily, count: 2);
      expect(r.isOccurrenceOn(start, start), isTrue);
      expect(
        r.isOccurrenceOn(start, start.add(const Duration(days: 1))),
        isTrue,
      );
      expect(
        r.isOccurrenceOn(start, start.add(const Duration(days: 2))),
        isFalse,
      );
    });
    test('endDate is inclusive', () {
      final end = start.add(const Duration(days: 2));
      final r = PlannerRecurrence(
        type: PlannerRecurrenceType.daily,
        endDate: end,
      );
      expect(r.isOccurrenceOn(start, end), isTrue);
      expect(
        r.isOccurrenceOn(start, end.add(const Duration(days: 1))),
        isFalse,
      );
    });
  });

  group('json round-trip', () {
    test('preserves fields', () {
      final r = PlannerRecurrence(
        type: PlannerRecurrenceType.weekly,
        weekdays: {1, 3, 5},
        endDate: DateTime(2026, 6, 1),
        count: 10,
      );
      final decoded = PlannerRecurrence.fromJson(r.toJson());
      expect(decoded.type, r.type);
      expect(decoded.weekdays, r.weekdays);
      expect(decoded.endDate, r.endDate);
      expect(decoded.count, r.count);
    });
  });
}
