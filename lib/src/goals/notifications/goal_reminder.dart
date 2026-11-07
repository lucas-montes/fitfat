import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/goal.dart';
import '../../notifications/notification_plugin.dart';

/// Android channel for daily goal reminders. Channel name/description are
/// system-level Android settings and stay in English (they are configured
/// before l10n is available).
const goalReminderChannelId = 'goal_reminders';
const goalReminderChannelName = 'Goal reminders';
const goalReminderChannelDescription =
    'Daily reminders that keep your goals on track.';

/// Notification payload marking a goal reminder; the tap handler routes to
/// the Plan tab (where Goals lives).
const goalReminderPayload = 'goal_reminder';

/// Fires the daily reminder for an active goal. Tapping the notification
/// opens the Planner tab. Notification ids derive deterministically from the
/// goal id, so edits reschedule in place and done/aborted/delete cancel
/// precisely.
final goalReminderSchedulerProvider = Provider<GoalReminderScheduler>((ref) {
  return GoalReminderScheduler(ref.watch(flutterLocalNotificationsProvider));
});

final class GoalReminderScheduler {
  GoalReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Schedules the daily reminder for [goal] at its reminder time.
  /// A no-op unless the goal is active with reminders enabled.
  Future<void> scheduleForGoal(
    Goal goal, {
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!goal.isActive || !goal.reminderEnabled) {
      await cancelForGoal(goal.id);
      return;
    }

    final now = DateTime.now();
    final fireAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      goal.reminderTimeMinutes ~/ 60,
      goal.reminderTimeMinutes % 60,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        goalReminderChannelId,
        goalReminderChannelName,
        channelDescription: goalReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      notificationId(goal.id),
      title,
      body,
      fireAt,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: goalReminderPayload,
    );
  }

  /// Cancels the daily reminder for [goalId] (done/aborted/delete).
  Future<void> cancelForGoal(String goalId) async {
    if (kIsWeb) return;
    await _plugin.cancel(notificationId(goalId));
  }

  static int notificationId(String goalId) => _stableHash(goalId) & 0x3FFFFFFF;
}

/// FNV-1a 32-bit hash of [value]. Unlike `String.hashCode` this is stable
/// across process restarts and platforms, so a goal always maps to the same
/// notification id.
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
