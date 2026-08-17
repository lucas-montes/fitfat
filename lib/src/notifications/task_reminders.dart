import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/planner_item.dart';
import '../planner/repositories/planner_repository.dart';
import '../settings/providers/settings.dart';
import 'notification_plugin.dart';

/// Android channel for planner task reminders (due-time + 30-min
/// pre-reminder). Channel name/description are system-level Android settings
/// and stay in English (they are configured before l10n is available).
const plannerReminderChannelId = 'planner_reminders';
const plannerReminderChannelName = 'Task reminders';
const plannerReminderChannelDescription =
    'Reminders for planner tasks with a due time.';

/// Notification payload marking a planner reminder; the tap handler routes to
/// the Plan tab.
const plannerReminderPayload = 'planner_reminder';

/// Minutes before the due time at which the advance reminder fires.
const preReminderMinutes = 30;

/// Prefs key storing the JSON array of task ids that currently have scheduled
/// notifications, so the app-wide toggle can cancel precisely (instead of a
/// blanket `cancelAll` that would also kill the active-workout notification).
const scheduledTasksKey = 'task_reminder_scheduled_ids';

/// FNV-1a 32-bit hash of [value]. Unlike `String.hashCode` this is stable
/// across process restarts and platforms, so a task always maps to the same
/// notification ids.
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// The absolute local wall-clock instants at which reminders for [item]
/// should fire — `[pre-reminder, start-time]` when both are in the future,
/// `[start-time]` when only the start time is (the 30-min pre-reminder would
/// fall in the past), or empty when the task is done, has no start time, or is
/// already past due (past-due tasks never schedule). The reminder anchors to
/// the task's own day plus its start time-of-day.
List<DateTime> plannerReminderTimes(PlannerItem item, {DateTime? now}) {
  final minutes = item.startTimeMinutes;
  if (minutes == null || item.done) return const [];

  final day = item.day;
  final dueAt = DateTime(
    day.year,
    day.month,
    day.day,
    minutes ~/ 60,
    minutes % 60,
  );
  final reference = now ?? DateTime.now();
  if (!dueAt.isAfter(reference)) return const [];

  final pre = dueAt.subtract(const Duration(minutes: preReminderMinutes));
  if (pre.isAfter(reference)) return [pre, dueAt];
  return [dueAt];
}

/// Lazily creates the scheduler. Plugin initialization (plus cold-start tap
/// replay) happens once, in the post-first-frame `BackgroundStartup`, through
/// the shared [flutterLocalNotificationsProvider]; this scheduler only
/// schedules and cancels on that shared plugin.
final taskReminderSchedulerProvider = Provider<TaskReminderScheduler>((ref) {
  return TaskReminderScheduler(
    ref.watch(flutterLocalNotificationsProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

/// Schedules planner task reminders: one at the due time and one 30 minutes
/// before. Both fire only for pending tasks with a due date + due time that is
/// still in the future; past-due tasks never schedule.
///
/// Notification ids are derived deterministically from the task id (a stable
/// hash), so editing a task reschedules in place and done/delete can cancel
/// precisely. A prefs-backed registry tracks which task ids currently have
/// scheduled notifications for the app-wide toggle.
final class TaskReminderScheduler {
  TaskReminderScheduler(this._plugin, this._prefs);

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferences _prefs;

  /// Initializes the plugin (Android channel + iOS defaults), wires the tap

  /// Best-effort permission request (Android 13+ notification permission,
  /// iOS alert/badge/sound). Called from user-initiated flows so the OS prompt
  /// happens in context; startup rescheduling never prompts.
  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Schedules (or replaces in place) the due-time + pre-reminder for [item].
  /// A no-op when the task is done, has no due date/time, or is already past
  /// due. [dueSoonText]/[dueNowText] are the localized notification bodies.
  Future<void> scheduleForItem(
    PlannerItem item, {
    required String dueSoonText,
    required String dueNowText,
  }) async {
    final times = plannerReminderTimes(item);
    if (times.isEmpty) return;

    final tzDue = tz.TZDateTime.from(times.last, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        plannerReminderChannelId,
        plannerReminderChannelName,
        channelDescription: plannerReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // The due-time reminder is always the last (and only when pre-reminder
    // falls in the past) scheduled instant.
    await _plugin.zonedSchedule(
      dueNotificationId(item.id),
      item.title,
      dueNowText,
      tzDue,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: plannerReminderPayload,
    );
    if (times.length == 2) {
      await _plugin.zonedSchedule(
        preReminderNotificationId(item.id),
        item.title,
        dueSoonText,
        tz.TZDateTime.from(times.first, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: plannerReminderPayload,
      );
    }
    await _addToRegistry(item.id);
  }

  /// Cancels both reminders for [taskId] (done/delete/edit-away-time).
  Future<void> cancelForTask(String taskId) async {
    await _plugin.cancel(dueNotificationId(taskId));
    await _plugin.cancel(preReminderNotificationId(taskId));
    await _removeFromRegistry(taskId);
  }

  /// Cancels every currently-scheduled task reminder (app-wide toggle off).
  Future<void> cancelAll() async {
    for (final taskId in _registeredIds()) {
      await _plugin.cancel(dueNotificationId(taskId));
      await _plugin.cancel(preReminderNotificationId(taskId));
    }
    await _prefs.remove(scheduledTasksKey);
  }

  /// Reschedules the pending future timed tasks from [repository] (startup and
  /// toggle back on). Cancels first so stale registrations from tasks that
  /// were done/deleted elsewhere are dropped; past-due and done tasks are
  /// skipped by [scheduleForItem].
  Future<void> reschedulePending({
    required PlannerRepository repository,
    required String dueSoonText,
    required String dueNowText,
  }) async {
    await cancelAll();
    final items = await repository.getUpcomingWithStartTime(DateTime.now());
    for (final item in items) {
      await scheduleForItem(
        item,
        dueSoonText: dueSoonText,
        dueNowText: dueNowText,
      );
    }
  }

  /// Due-time notification id for [taskId].
  int dueNotificationId(String taskId) => _stableHash(taskId) & 0x3FFFFFFF;

  /// Pre-reminder notification id for [taskId] (offset so the two never clash).
  int preReminderNotificationId(String taskId) =>
      (dueNotificationId(taskId) + 1) & 0x3FFFFFFF;

  List<String> _registeredIds() {
    final raw = _prefs.getString(scheduledTasksKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return const [];
  }

  Future<void> _addToRegistry(String taskId) async {
    final ids = _registeredIds();
    if (ids.contains(taskId)) return;
    ids.add(taskId);
    await _prefs.setString(scheduledTasksKey, jsonEncode(ids));
  }

  Future<void> _removeFromRegistry(String taskId) async {
    final ids = _registeredIds();
    final updated = ids.where((id) => id != taskId).toList();
    if (updated.length == ids.length) return;
    if (updated.isEmpty) {
      await _prefs.remove(scheduledTasksKey);
    } else {
      await _prefs.setString(scheduledTasksKey, jsonEncode(updated));
    }
  }
}
