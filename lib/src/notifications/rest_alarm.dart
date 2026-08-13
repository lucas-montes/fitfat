import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../settings/providers/settings.dart';
import 'notification_plugin.dart';
import 'rest_timer.dart';

/// Android channel for the one-shot rest alarm fired when the planned rest
/// between sets elapses. Channel name/description are system-level Android
/// settings and stay in English (configured before l10n is available).
const restAlarmChannelId = 'rest_alarm';
const restAlarmChannelName = 'Rest timer';
const restAlarmChannelDescription =
    'Alerts when the planned rest between sets is over.';

/// Notification payload marking a rest alarm; the tap handler routes to the
/// active-workout view.
const restAlarmPayload = 'rest_alarm';

/// Prefs keys holding the localized rest-alarm title/body, written by the
/// post-first-frame startup (which has `AppLocalizations`) and read here so
/// scheduling from the UI isolate stays context-free.
const restAlarmTitleKey = 'rest_alarm_title';
const restAlarmBodyKey = 'rest_alarm_body';

/// FNV-1a 32-bit hash of [value] — stable across process restarts so a set
/// always maps to the same notification id (and can be cancelled precisely).
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Cached result of whether exact alarm scheduling is supported.
/// Checked once at first schedule call to avoid repeated try-catch overhead.
bool? _exactAlarmsSupported;

/// Schedules and cancels the one-shot rest alarm for a set's rest period.
/// Shares the single app [FlutterLocalNotificationsPlugin] so the tap handler
/// stays unique; sound/vibration come from settings per schedule call.
final class RestAlarmScheduler {
  RestAlarmScheduler(this._plugin, this._prefs);

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferences _prefs;

  /// Schedules an alarm at [fireAt] (wall-clock, local zone) for [setId].
  /// Exact scheduling is preferred so the rest alarm fires on time; on
  /// platforms/versions without the exact-alarm permission it falls back to
  /// inexact (best-effort) instead of throwing.
  Future<void> schedule({
    required String setId,
    required DateTime fireAt,
    required bool sound,
    required bool vibrate,
    required int plannedSeconds,
  }) async {
    final title = _prefs.getString(restAlarmTitleKey) ?? 'Rest is over';
    final bodyTemplate =
        _prefs.getString('rest_alarm_body_with_duration') ??
        _prefs.getString(restAlarmBodyKey) ??
        'Your planned rest is complete.';
    final durationStr = formatRestDuration(Duration(seconds: plannedSeconds));
    final body = bodyTemplate.replaceAll('{duration}', durationStr);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        restAlarmChannelId,
        restAlarmChannelName,
        channelDescription: restAlarmChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: vibrate,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    // Use cached result if available, otherwise try exact first and cache result
    final useExact = _exactAlarmsSupported ?? true;
    final mode = useExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        notificationId(setId),
        title,
        body,
        tzFireAt,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: restAlarmPayload,
      );
      // If exact worked, cache success
      if (useExact) _exactAlarmsSupported = true;
    } catch (_) {
      // Exact scheduling not permitted — cache failure and retry with inexact
      if (useExact) {
        _exactAlarmsSupported = false;
        await _plugin.zonedSchedule(
          notificationId(setId),
          title,
          body,
          tzFireAt,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: restAlarmPayload,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Cancels the alarm for [setId] (rest replaced, cancelled, or workout
  /// completed). No-op when none is scheduled.
  Future<void> cancel(String setId) async {
    try {
      await _plugin.cancel(notificationId(setId));
    } catch (_) {}
  }

  /// Notification id for [setId].
  int notificationId(String setId) => _stableHash(setId) & 0x3FFFFFFF;
}

final restAlarmSchedulerProvider = Provider<RestAlarmScheduler>((ref) {
  return RestAlarmScheduler(
    ref.watch(flutterLocalNotificationsProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
