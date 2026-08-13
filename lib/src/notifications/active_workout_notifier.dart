import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../settings/providers/settings.dart';
import 'rest_timer.dart';

/// SharedPreferences keys written by the UI isolate and read by the background
/// task callback (which cannot use `AppLocalizations`): the active workout
/// session plus the localized label fragments for the notification text.
const activeWorkoutNameKey = 'active_workout_name';
const activeWorkoutStartedAtKey = 'active_workout_started_at';
const notificationElapsedLabelKey = 'notification_elapsed_label';
const notificationRestLabelKey = 'notification_rest_label';

const _serviceId = 256;
const _iosNotificationId = 1001;

/// Top-level entry point registered with [FlutterForegroundTask.startService].
/// Runs in a background isolate with its own FlutterEngine, so plugins
/// (including `shared_preferences`) are available inside the task handler.
@pragma('vm:entry-point')
void activeWorkoutTaskCallback() {
  FlutterForegroundTask.setTaskHandler(ActiveWorkoutTaskHandler());
}

/// Rebuilds the ongoing notification each tick from `shared_preferences`:
/// "Elapsed mm:ss" plus "· Rest mm:ss" while a rest period is running.
/// An expired rest period is cleared here so the rest segment drops out.
final class ActiveWorkoutTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) {
    return _updateNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_updateNotification());
  }

  @override
  void onNotificationPressed() {
    // Signal the UI isolate to open the active-workout view (T06).
    FlutterForegroundTask.sendDataToMain('active-workout');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  Future<void> _updateNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final startedAtMillis = prefs.getInt(activeWorkoutStartedAtKey);
    if (startedAtMillis == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = formatRestDuration(
      Duration(milliseconds: now - startedAtMillis),
    );
    final elapsedLabel =
        prefs.getString(notificationElapsedLabelKey) ?? 'Elapsed';
    var text = '$elapsedLabel $elapsed';

    // Count-up rest: show the elapsed rest while a rest is running. The rest
    // keeps running past the planned duration (never auto-cleared here).
    final restStartedAt = prefs.getInt(restStartedAtKey);
    if (restStartedAt != null) {
      final restLabel = prefs.getString(notificationRestLabelKey) ?? 'Rest';
      final restElapsed = formatRestDuration(
        Duration(milliseconds: now - restStartedAt),
      );
      text = '$text · $restLabel $restElapsed';
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: prefs.getString(activeWorkoutNameKey) ?? '',
      notificationText: text,
    );
  }
}

/// UI-side orchestrator: persists the active-workout session for the
/// background handler, starts/stops the foreground service on Android, and
/// shows a best-effort ongoing notification on iOS.
final class ActiveWorkoutNotifier {
  final SharedPreferences _prefs;
  ActiveWorkoutNotifier(this._prefs);

  final FlutterLocalNotificationsPlugin _iosPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> startWorkoutNotification({
    required String workoutName,
    required DateTime startedAt,
    required AppLocalizations l10n,
  }) async {
    await _prefs.setString(activeWorkoutNameKey, workoutName);
    await _prefs.setInt(
      activeWorkoutStartedAtKey,
      startedAt.millisecondsSinceEpoch,
    );
    await _prefs.setString(
      notificationElapsedLabelKey,
      l10n.activeWorkoutElapsedLabel,
    );
    await _prefs.setString(
      notificationRestLabelKey,
      l10n.activeWorkoutRestLabel,
    );

    if (Platform.isAndroid) {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceId: _serviceId,
          notificationTitle: workoutName,
          notificationText: '${l10n.activeWorkoutElapsedLabel} 00:00',
          notificationInitialRoute: '/active-workout',
          callback: activeWorkoutTaskCallback,
        );
      }
    } else if (Platform.isIOS) {
      await _showIosNotification(workoutName: workoutName, l10n: l10n);
    }
  }

  Future<void> stopWorkoutNotification() async {
    await _prefs.remove(activeWorkoutNameKey);
    await _prefs.remove(activeWorkoutStartedAtKey);
    if (Platform.isAndroid) {
      await FlutterForegroundTask.stopService();
    } else if (Platform.isIOS) {
      await _iosPlugin.cancel(_iosNotificationId);
    }
  }

  // -- iOS best-effort (per plan: no iOS foreground-service parity) ---------

  Future<void> _showIosNotification({
    required String workoutName,
    required AppLocalizations l10n,
  }) async {
    await _iosPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _iosPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _iosPlugin.show(
      _iosNotificationId,
      workoutName,
      l10n.activeWorkoutElapsedLabel,
      const NotificationDetails(iOS: DarwinNotificationDetails()),
    );
  }
}

final activeWorkoutNotifierProvider = Provider<ActiveWorkoutNotifier>((ref) {
  return ActiveWorkoutNotifier(ref.watch(sharedPreferencesProvider));
});
