import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rest_alarm.dart';
import 'task_reminders.dart';
import '../experiments/notifications/experiment_reminder.dart';

/// Single shared [FlutterLocalNotificationsPlugin] used by every notification
/// source (planner reminders, rest alarms). Having one instance means one tap
/// handler: [initializeNotifications] wires a payload-routed dispatcher, and
/// the individual schedulers only schedule/cancel through it.
final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

/// One-time plugin initialization with a tap handler that routes by payload,
/// plus a cold-start tap replay. Called by the post-first-frame
/// `BackgroundStartup`; must complete before any notification is scheduled.
Future<void> initializeNotifications({
  required FlutterLocalNotificationsPlugin plugin,
  required void Function() onTapPlan,
  required void Function() onTapActiveWorkout,
  required void Function() onTapExperiments,
}) async {
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      switch (response.payload) {
        case plannerReminderPayload:
          onTapPlan();
        case restAlarmPayload:
          onTapActiveWorkout();
        case experimentReminderPayload:
          onTapExperiments();
      }
    },
  );
  final launch = await plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    switch (launch?.notificationResponse?.payload) {
      case plannerReminderPayload:
        onTapPlan();
      case restAlarmPayload:
        onTapActiveWorkout();
      case experimentReminderPayload:
        onTapExperiments();
    }
  }
}
