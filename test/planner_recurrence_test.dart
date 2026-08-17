import 'package:fitfat/src/models/planner_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlannerRecurrence.isOccurrenceOn / occurrenceIndex', () {
    final start = DateTime(2026, 8, 10); // a Monday

    test('daily with no end fires every day, anchor index 0', () {
      final rule = PlannerRecurrence(type: PlannerRecurrenceType.daily);
      expect(rule.occurrenceIndex(start, start), 0);
      expect(rule.isOccurrenceOn(start, start), isTrue);
      expect(rule.isOccurrenceOn(start, start.add(const Duration(days: 3))), isTrue);
      expect(
        rule.isOccurrenceOn(start, start.subtract(const Duration(days: 1))),
        isFalse,
      );
    });

    test('daily respects count (inclusive of anchor)', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.daily,
        count: 2,
      );
      expect(rule.isOccurrenceOn(start, start), isTrue); // index 0
      expect(
        rule.isOccurrenceOn(start, start.add(const Duration(days: 1))),
        isTrue,
      ); // index 1
      expect(
        rule.isOccurrenceOn(start, start.add(const Duration(days: 2))),
        isFalse,
      ); // index 2 >= count
    });

    test('daily respects endDate (inclusive)', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.daily,
        endDate: DateTime(2026, 8, 11),
      );
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 11)), isTrue);
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 12)), isFalse);
    });

    test('weekly fires on selected weekdays only', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.weekly,
        weekdays: {DateTime.wednesday, DateTime.friday},
      );
      // Anchor is Monday, not a selected weekday.
      expect(rule.isOccurrenceOn(start, start), isFalse);
      final wed = DateTime(2026, 8, 12); // Wednesday
      final fri = DateTime(2026, 8, 14); // Friday
      final nextWed = DateTime(2026, 8, 19);
      expect(rule.occurrenceIndex(start, wed), 0);
      expect(rule.occurrenceIndex(start, fri), 1);
      expect(rule.occurrenceIndex(start, nextWed), 2);
      expect(rule.isOccurrenceOn(start, wed), isTrue);
      expect(rule.isOccurrenceOn(start, fri), isTrue);
      expect(rule.isOccurrenceOn(start, nextWed), isTrue);
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 11)), isFalse); // Tue
    });

    test('weekly respects count', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.weekly,
        weekdays: {DateTime.wednesday, DateTime.friday},
        count: 2,
      );
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 19)), isFalse); // idx 2
    });

    test('weekly respects endDate', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.weekly,
        weekdays: {DateTime.wednesday, DateTime.friday},
        endDate: DateTime(2026, 8, 14),
      );
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 19)), isFalse);
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 14)), isTrue);
    });

    test('interval fires every N days', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.interval,
        intervalDays: 2,
      );
      expect(rule.occurrenceIndex(start, start.add(const Duration(days: 2))), 1);
      expect(
        rule.isOccurrenceOn(start, start.add(const Duration(days: 1))),
        isFalse,
      );
      expect(
        rule.isOccurrenceOn(start, start.add(const Duration(days: 4))),
        isTrue,
      );
    });

    test('interval respects count', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.interval,
        intervalDays: 2,
        count: 2,
      );
      expect(
        rule.isOccurrenceOn(start, start.add(const Duration(days: 4))),
        isFalse,
      ); // index 2
    });

    test('interval respects endDate', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.interval,
        intervalDays: 2,
        endDate: DateTime(2026, 8, 13),
      );
      expect(
        rule.isOccurrenceOn(start, start.add(const Duration(days: 4))),
        isFalse,
      );
    });

    test('monthly fires on the given month day', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.monthly,
        monthDay: 15,
      );
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 15)), isTrue);
      expect(rule.isOccurrenceOn(start, DateTime(2026, 9, 15)), isTrue);
      expect(rule.occurrenceIndex(start, DateTime(2026, 9, 15)), 1);
      expect(rule.isOccurrenceOn(start, DateTime(2026, 8, 14)), isFalse);
    });

    test('monthly falls back to anchor day when monthDay is null', () {
      final rule = PlannerRecurrence(type: PlannerRecurrenceType.monthly);
      expect(rule.isOccurrenceOn(start, DateTime(2026, 9, 10)), isTrue);
      expect(rule.occurrenceIndex(start, DateTime(2026, 9, 10)), 1);
    });

    test('monthly respects count and endDate', () {
      final countRule = PlannerRecurrence(
        type: PlannerRecurrenceType.monthly,
        monthDay: 15,
        count: 1,
      );
      expect(countRule.isOccurrenceOn(start, DateTime(2026, 9, 15)), isFalse);
      final endRule = PlannerRecurrence(
        type: PlannerRecurrenceType.monthly,
        monthDay: 15,
        endDate: DateTime(2026, 8, 31),
      );
      expect(endRule.isOccurrenceOn(start, DateTime(2026, 9, 15)), isFalse);
    });

    test('isValid guards required sub-fields', () {
      expect(
        PlannerRecurrence(
          type: PlannerRecurrenceType.weekly,
        ).isValid,
        isFalse,
      );
      expect(
        PlannerRecurrence(
          type: PlannerRecurrenceType.weekly,
          weekdays: {1},
        ).isValid,
        isTrue,
      );
      expect(
        PlannerRecurrence(type: PlannerRecurrenceType.interval).isValid,
        isFalse,
      );
      expect(
        PlannerRecurrence(
          type: PlannerRecurrenceType.interval,
          intervalDays: 2,
        ).isValid,
        isTrue,
      );
      expect(
        PlannerRecurrence(type: PlannerRecurrenceType.monthly).isValid,
        isFalse,
      );
      expect(
        PlannerRecurrence(
          type: PlannerRecurrenceType.monthly,
          monthDay: 31,
        ).isValid,
        isTrue,
      );
    });

    test('round-trips through JSON', () {
      final rule = PlannerRecurrence(
        type: PlannerRecurrenceType.weekly,
        weekdays: {2, 4},
        endDate: DateTime(2026, 9, 1),
        count: 5,
        excludedDates: {DateTime(2026, 8, 14).millisecondsSinceEpoch},
      );
      final decoded = PlannerRecurrence.fromJson(rule.toJson());
      expect(decoded.type, rule.type);
      expect(decoded.weekdays, rule.weekdays);
      expect(decoded.endDate, rule.endDate);
      expect(decoded.count, rule.count);
      expect(decoded.excludedDates, rule.excludedDates);
    });
  });
}
