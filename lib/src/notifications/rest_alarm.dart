import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_plugin.dart';

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

/// Schedules and cancels the one-shot rest alarm for a set's rest period.
/// Shares the single app [FlutterLocalNotificationsPlugin] so the tap handler
/// stays unique; sound/vibration come from settings per schedule call.
///
/// This is the fallback path: the foreground task handler posts the "rest is
/// over" popup within ~1s when the service is alive, and cancels this
/// scheduled fallback when it fires. When the service is dead/stalled (Doze,
/// OEM kill), this inexact alarm still delivers the alert (possibly late)
/// instead of dropping it entirely.
final class RestAlarmScheduler {
  RestAlarmScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Schedules an alarm at [fireAt] (wall-clock, local zone) for [setId].
  /// Replaces any previous alarm for the same set. Never throws.
  Future<void> schedule({
    required String setId,
    required DateTime fireAt,
    required bool sound,
    required bool vibrate,
    required int plannedSeconds,
  }) async {
    try {
      await _ensureTimeZone();
      await cancel(setId);
      final prefs = await SharedPreferences.getInstance();
      final title = prefs.getString(restAlarmTitleKey) ?? 'Rest is over';
      final template = prefs.getString('rest_alarm_body_with_duration');
      final fallbackBody =
          prefs.getString(restAlarmBodyKey) ?? 'Your planned rest is complete.';
      final body = template != null
          ? template.replaceAll('{duration}', _formatSeconds(plannedSeconds))
          : fallbackBody;
      final now = tz.TZDateTime.now(tz.local);
      final tzFire = tz.TZDateTime.from(fireAt, tz.local);
      if (!tzFire.isAfter(now)) return;
      await _plugin.zonedSchedule(
        notificationId(setId),
        title,
        body,
        tzFire,
        NotificationDetails(
          android: AndroidNotificationDetails(
            restAlarmChannelId,
            restAlarmChannelName,
            channelDescription: restAlarmChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.alarm,
            playSound: sound,
            enableVibration: vibrate,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: restAlarmPayload,
      );
    } catch (e) {
      Logger('RestAlarm').warning('rest fallback schedule failed', e);
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
  int notificationId(String setId) => restAlarmNotificationId(setId);
}

/// Stable notification id for the scheduled fallback alarm of [setId].
/// Distinct from the foreground-handler popup id (424242) so the handler can
/// cancel a pending fallback when it fires first.
int restAlarmNotificationId(String setId) => _stableHash(setId) & 0x3FFFFFFF;

String _formatSeconds(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return '$mm:$ss';
}

bool _tzInitialized = false;

Future<void> _ensureTimeZone() async {
  if (_tzInitialized) return;
  try {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
        tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
      );
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _tzInitialized = true;
  } catch (_) {}
}

final restAlarmSchedulerProvider = Provider<RestAlarmScheduler>((ref) {
  return RestAlarmScheduler(ref.watch(flutterLocalNotificationsProvider));
});
