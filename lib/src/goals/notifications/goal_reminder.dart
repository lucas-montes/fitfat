import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/goal.dart';
import '../repositories/goal_repository.dart';
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

/// Action id of the reply field on a manual goal's reminder.
const goalReplyActionId = 'goal_record';

/// Replies typed into the notification, waiting to be recorded
/// (`goalId|value|epochMs`), so they survive the app being closed.
const pendingGoalRepliesKey = 'pending_goal_replies';

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
    String? replyAction,
    String? replyHint,
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

    // A manual numeric goal gets a reply field: type the value and send,
    // without opening the app.
    final reply =
        replyAction != null &&
        goal.isManual &&
        goal.targetType == GoalTargetType.numeric;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        goalReminderChannelId,
        goalReminderChannelName,
        channelDescription: goalReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        actions: reply
            ? [
                AndroidNotificationAction(
                  goalReplyActionId,
                  replyAction,
                  inputs: [AndroidNotificationActionInput(label: replyHint)],
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: notificationId(goal.id),
      title: title,
      body: body,
      scheduledDate: fireAt,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$goalReminderPayload:${goal.id}',
    );
  }

  /// Cancels the daily reminder for [goalId] (done/aborted/delete).
  Future<void> cancelForGoal(String goalId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: notificationId(goalId));
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

/// Queues a value typed into a goal reminder. Runs in the background isolate
/// when the app is closed, so it only touches preferences; the app records it
/// on its next start or resume ([drainGoalReplies]).
Future<bool> queueGoalReply(NotificationResponse response) async {
  if (response.actionId != goalReplyActionId) return false;
  final payload = response.payload ?? '';
  final goalId = payload.startsWith('$goalReminderPayload:')
      ? payload.substring(goalReminderPayload.length + 1)
      : null;
  final value = double.tryParse(
    (response.input ?? '').trim().replaceAll(',', '.'),
  );
  if (goalId == null || goalId.isEmpty || value == null) return false;
  final prefs = await SharedPreferences.getInstance();
  final pending = prefs.getStringList(pendingGoalRepliesKey) ?? const [];
  await prefs.setStringList(pendingGoalRepliesKey, [
    ...pending,
    '$goalId|$value|${DateTime.now().millisecondsSinceEpoch}',
  ]);
  return true;
}

/// Background-isolate entry point for notification actions.
@pragma('vm:entry-point')
Future<void> goalReplyBackgroundHandler(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await queueGoalReply(response);
}

/// Records every queued reply and clears the queue. Returns how many.
Future<int> drainGoalReplies(GoalRepository repo) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final pending = prefs.getStringList(pendingGoalRepliesKey) ?? const [];
  if (pending.isEmpty) return 0;
  await prefs.remove(pendingGoalRepliesKey);
  var n = 0;
  for (final line in pending) {
    final parts = line.split('|');
    if (parts.length != 3) continue;
    final value = double.tryParse(parts[1]);
    final at = int.tryParse(parts[2]);
    if (value == null || at == null) continue;
    if (await repo.getGoalById(parts[0]) == null) continue;
    await repo.recordProgress(
      goalId: parts[0],
      day: DateTime.fromMillisecondsSinceEpoch(at),
      value: value,
    );
    n++;
  }
  return n;
}
