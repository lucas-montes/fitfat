import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../models/experiment.dart';
import '../../notifications/notification_plugin.dart';

/// Android channel for daily experiment check-in reminders. Channel
/// name/description are system-level Android settings and stay in English
/// (they are configured before l10n is available).
const experimentReminderChannelId = 'experiment_reminders';
const experimentReminderChannelName = 'Experiment reminders';
const experimentReminderChannelDescription =
    'Daily check-in reminders for running experiments.';

/// Notification payload marking an experiment reminder; the tap handler
/// routes to the Experiments tab.
const experimentReminderPayload = 'experiment_reminder';

/// Fires the daily check-in reminder for a running experiment. Tapping the
/// notification opens the Experiments tab. Notification ids derive
/// deterministically from the experiment id, so edits reschedule in place and
/// done/aborted/delete cancel precisely.
final experimentReminderSchedulerProvider =
    Provider<ExperimentReminderScheduler>((ref) {
      return ExperimentReminderScheduler(
        ref.watch(flutterLocalNotificationsProvider),
      );
    });

final class ExperimentReminderScheduler {
  ExperimentReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Schedules the daily reminder for [experiment] at its reminder time.
  /// A no-op unless the experiment is active with reminders enabled.
  Future<void> scheduleForExperiment(
    Experiment experiment, {
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!experiment.isActive || !experiment.reminderEnabled) {
      await cancelForExperiment(experiment.id);
      return;
    }

    final now = DateTime.now();
    final fireAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      experiment.reminderTimeMinutes ~/ 60,
      experiment.reminderTimeMinutes % 60,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        experimentReminderChannelId,
        experimentReminderChannelName,
        channelDescription: experimentReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      notificationId(experiment.id),
      title,
      body,
      fireAt,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: experimentReminderPayload,
    );
  }

  /// Cancels the daily reminder for [experimentId] (done/aborted/delete).
  Future<void> cancelForExperiment(String experimentId) async {
    if (kIsWeb) return;
    await _plugin.cancel(notificationId(experimentId));
  }

  static int notificationId(String experimentId) =>
      _stableHash(experimentId) & 0x3FFFFFFF;
}

/// FNV-1a 32-bit hash of [value]. Unlike `String.hashCode` this is stable
/// across process restarts and platforms, so an experiment always maps to the
/// same notification id.
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
