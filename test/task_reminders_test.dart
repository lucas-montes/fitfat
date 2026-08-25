import 'package:fitfat/src/models/task.dart';
import 'package:fitfat/src/notifications/task_reminders.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('plannerReminderTimes', () {
    final now = DateTime(2026, 8, 11, 10, 0);

    Task item({int? startTimeMinutes, bool done = false}) => Task(
      id: 'task-1',
      day: DateTime(2026, 8, 11),
      title: 'Morning run',
      done: done,
      sortOrder: 0,
      startTimeMinutes: startTimeMinutes,
      createdAt: DateTime(2026, 8, 10, 8, 0),
    );

    test('schedules start + 30-min pre-reminder for a future timed task', () {
      final times = plannerReminderTimes(
        item(startTimeMinutes: 15 * 60),
        now: now,
      );
      expect(times, hasLength(2));
      expect(times.last, DateTime(2026, 8, 11, 15, 0));
      expect(times.first, DateTime(2026, 8, 11, 14, 30));
    });

    test('returns empty when there is no start time', () {
      expect(plannerReminderTimes(item(), now: now), isEmpty);
    });

    test('never schedules for a done task', () {
      expect(
        plannerReminderTimes(
          item(startTimeMinutes: 15 * 60, done: true),
          now: now,
        ),
        isEmpty,
      );
    });

    test('never schedules a past-due task', () {
      expect(
        plannerReminderTimes(item(startTimeMinutes: 9 * 60), now: now),
        isEmpty,
      );
    });

    test(
      'schedules only the start time when the pre-reminder would be past',
      () {
        final times = plannerReminderTimes(
          item(startTimeMinutes: 10 * 60 + 15),
          now: now,
        );
        expect(times, hasLength(1));
        expect(times.single, DateTime(2026, 8, 11, 10, 15));
      },
    );
  });

  group('TaskReminderScheduler notification ids', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('are stable, distinct, and within the 30-bit id space', () async {
      final prefs = await SharedPreferences.getInstance();
      final scheduler = TaskReminderScheduler(
        FlutterLocalNotificationsPlugin(),
        prefs,
      );

      final firstDue = scheduler.dueNotificationId('task-1');
      final secondDue = scheduler.dueNotificationId('task-1');
      final pre = scheduler.preReminderNotificationId('task-1');
      final otherPre = scheduler.preReminderNotificationId('task-2');

      expect(firstDue, secondDue);
      expect(pre, firstDue + 1);
      expect(firstDue, isNot(otherPre));
      for (final id in [firstDue, pre, otherPre]) {
        expect(id, inInclusiveRange(0, 0x3FFFFFFF));
      }
    });
  });
}
