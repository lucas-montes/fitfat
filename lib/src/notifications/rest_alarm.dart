import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final class RestAlarmScheduler {
  RestAlarmScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Schedules an alarm at [fireAt] (wall-clock, local zone) for [setId].
  ///
  /// NOTE: this one-shot alarm is intentionally a no-op. The "rest is over"
  /// popup is now driven by [ActiveWorkoutTaskHandler] (which ticks every
  /// second with a wake lock while the workout foreground service runs), so
  /// the alert fires within ~1s of the planned rest instead of being delayed
  /// by Android Doze / inexact alarms. Keeping this method avoids churn at the
  /// call site in [RestTimerNotifier.startRest].
  Future<void> schedule({
    required String setId,
    required DateTime fireAt,
    required bool sound,
    required bool vibrate,
    required int plannedSeconds,
  }) async {
    // The foreground task handler posts the popup; nothing to schedule here.
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
  return RestAlarmScheduler(ref.watch(flutterLocalNotificationsProvider));
});
