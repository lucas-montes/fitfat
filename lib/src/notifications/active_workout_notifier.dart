import 'dart:async';
import 'dart:io';

// `NotificationVisibility` is hidden here: the rest popup uses
// flutter_local_notifications' enum, and both packages export one.
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fft;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../settings/providers/settings.dart';
import 'rest_alarm.dart';
import 'rest_timer.dart';

/// Stable notification id for the foreground-handler-driven "rest is over"
/// popup. Distinct from planner reminder ids (which are derived from task ids).
const restPopupNotificationId = 424242;

/// Heartbeat written by the foreground handler on every successful tick so the
/// UI watchdog can detect (and recover from) a frozen service.
const _lastTickKey = 'active_workout_last_tick';

/// SharedPreferences keys written by the UI isolate and read by the background
/// task callback (which cannot use `AppLocalizations`): the active workout
/// session plus the localized label fragments for the notification text.
const activeWorkoutNameKey = 'active_workout_name';
const activeWorkoutStartedAtKey = 'active_workout_started_at';
const notificationElapsedLabelKey = 'notification_elapsed_label';
const notificationRestLabelKey = 'notification_rest_label';

const _serviceId = 256;
const _iosNotificationId = 1001;

/// Persisted watchdog state so a restarted process can recover the service
/// even though the in-memory [_lastWorkoutName]/[_lastStartedAt] are lost.
const _watchdogNameKey = 'active_workout_watchdog_name';
const _watchdogStartedAtKey = 'active_workout_watchdog_started_at';

bool _foregroundServiceInitialized = false;
Future<void>? _foregroundInitFuture;

/// Visible in logcat (`flutter logs` / `adb logcat`) — every service
/// start/update failure is logged here with its error instead of being
/// swallowed, so a device that refuses the service leaves a trace.
final _log = Logger('ActiveWorkout');

/// Foreground-service type for workout tracking. `health` is the declared
/// type for exercise timers on Android 14+ (manifest declares
/// `dataSync|health` + `FOREGROUND_SERVICE_HEALTH`); `dataSync` falls under
/// API 35+ quota/timeout restrictions that don't apply to workouts.
const _serviceTypes = [ForegroundServiceTypes.health];

/// Idempotent foreground-service channel init. Safe to call from startup and
/// from [ActiveWorkoutNotifier.startWorkoutNotification] (which awaits it, so
/// a workout started before post-first-frame startup still shows the ongoing
/// notification instead of silently failing on an uninitialized channel).
Future<void> ensureForegroundServiceInitialized() {
  if (_foregroundServiceInitialized) return Future.value();
  return _foregroundInitFuture ??= Future(() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'active_workout',
        channelName: 'Active Workout',
        channelDescription:
            'Shows workout duration and rest timer while a workout is active.',
        onlyAlertOnce: true,
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        visibility: fft.NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }).then((_) => _foregroundServiceInitialized = true);
}

/// Cold-start recovery: if a workout session is persisted but the service is
/// not running (process kill, reboot with `autoRunOnBoot: false`), restart it.
/// Called once from post-first-frame startup after init.
Future<void> restoreWorkoutServiceIfNeeded(SharedPreferences prefs) async {
  if (!Platform.isAndroid) return;
  try {
    if (prefs.getInt(activeWorkoutStartedAtKey) == null) return;
    if (await FlutterForegroundTask.isRunningService) return;
    final name =
        prefs.getString(_watchdogNameKey) ?? prefs.getString(activeWorkoutNameKey) ?? '';
    final startedAtMillis = prefs.getInt(_watchdogStartedAtKey) ??
        prefs.getInt(activeWorkoutStartedAtKey)!;
    final elapsedLabel =
        prefs.getString(notificationElapsedLabelKey) ?? 'Elapsed';
    final elapsed = formatRestDuration(
      Duration(
        milliseconds:
            DateTime.now().millisecondsSinceEpoch - startedAtMillis,
      ),
    );
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: _serviceTypes,
      notificationTitle: name,
      notificationText: '$elapsedLabel $elapsed',
      notificationInitialRoute: '/active-workout',
      callback: activeWorkoutTaskCallback,
    );
    if (result is ServiceRequestFailure) {
      _log.warning('restoreWorkoutServiceIfNeeded failed', result.error);
    }
  } catch (_) {}
}

/// Builds the ongoing notification title/text for the active workout from
/// persisted prefs. Isolate-safe — reads only from [prefs] and never touches
/// plugins, so both the background task handler and the UI isolate can use it.
/// Returns null when no active session is persisted (nothing to show).
///
/// Callers must call `prefs.reload()` first so the instance sees values written
/// by the other isolate (notably `rest_started_at`/`rest_planned_seconds`,
/// which the UI writes after the service starts and the handler's cached
/// instance never sees otherwise).
({String title, String text})? buildActiveWorkoutNotificationText(
  SharedPreferences prefs,
) {
  final startedAtMillis = prefs.getInt(activeWorkoutStartedAtKey);
  if (startedAtMillis == null) return null;

  final now = DateTime.now().millisecondsSinceEpoch;
  final elapsed = formatRestDuration(
    Duration(milliseconds: now - startedAtMillis),
  );
  final elapsedLabel =
      prefs.getString(notificationElapsedLabelKey) ?? 'Elapsed';
  var text = '$elapsedLabel $elapsed';

  // Count-up rest: show the elapsed rest while a rest is running (the rest
  // keeps running past the planned duration — never auto-cleared here).
  final restStartedAt = prefs.getInt(restStartedAtKey);
  if (restStartedAt != null) {
    final restLabel = prefs.getString(notificationRestLabelKey) ?? 'Rest';
    final restElapsed = formatRestDuration(
      Duration(milliseconds: now - restStartedAt),
    );
    text = '$text\n$restLabel $restElapsed';
  }

  return (title: prefs.getString(activeWorkoutNameKey) ?? '', text: text);
}

/// Best-effort push of the current notification text from the UI isolate,
/// used right after a session/rest/set event or on app resume so the ongoing
/// notification is current at interaction points even if the background
/// `onRepeatEvent` tick stalls under Doze / OEM battery optimization. Android
/// only; never throws.
Future<void> refreshActiveWorkoutNotification() async {
  if (!Platform.isAndroid) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final snapshot = buildActiveWorkoutNotificationText(prefs);
    if (snapshot == null) return;
    final result = await FlutterForegroundTask.updateService(
      notificationTitle: snapshot.title,
      notificationText: snapshot.text,
    );
    if (result is ServiceRequestFailure) {
      _log.warning('refreshActiveWorkoutNotification failed', result.error);
    }
  } catch (e) {
    // Best-effort: never let a notification refresh break app logic.
    _log.warning('refreshActiveWorkoutNotification threw', e);
  }
}

/// Top-level entry point registered with [FlutterForegroundTask.startService].
/// Runs in a background isolate with its own FlutterEngine, so plugins
/// (including `shared_preferences`) are available inside the task handler.
@pragma('vm:entry-point')
void activeWorkoutTaskCallback() {
  FlutterForegroundTask.setTaskHandler(ActiveWorkoutTaskHandler());
}

/// Rebuilds the ongoing notification each tick from `shared_preferences`:
/// "Elapsed mm:ss" plus "· Rest mm:ss" while a rest period is running.
/// When the planned rest elapses it also fires a one-shot "rest is over" popup
/// directly from this handler (which ticks every second with a wake lock), so
/// the alert lands within ~1s of the planned time instead of being delayed by
/// Android Doze / inexact alarms.
final class ActiveWorkoutTaskHandler extends TaskHandler {
  FlutterLocalNotificationsPlugin? _plugin;

  Future<FlutterLocalNotificationsPlugin> _ensurePlugin() async {
    _plugin ??= FlutterLocalNotificationsPlugin();
    // Idempotent init for the background isolate (no tap handler here — the
    // main isolate already routes rest-alarm taps to the active-workout view).
    await _plugin!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    return _plugin!;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) {
    return _updateNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Guard the tick: an exception here would otherwise crash the foreground
    // task isolate and freeze the notification (the "stuck timers" bug).
    unawaited(_safeUpdate());
  }

  Future<void> _safeUpdate() async {
    try {
      await _updateNotification();
    } catch (_) {
      // Swallow: a single failed tick must never stop the service.
    }
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
    // The task handler runs in its own isolate with its own cached
    // `SharedPreferences` instance. Values the UI writes *after* the foreground
    // service starts (notably `rest_started_at`/`rest_planned_seconds`) are only
    // in the UI isolate's cache + native storage, never the handler's cache —
    // so without a reload the rest branch below never sees them and the rest
    // timer never appears in the notification.
    await prefs.reload();
    final snapshot = buildActiveWorkoutNotificationText(prefs);
    if (snapshot == null) return;

    // Fire the "rest is over" popup the moment the planned rest elapses. This
    // stays in the handler (side effect + tick with wake lock), unlike the text
    // building above which moved to the shared builder (T01).
    final restStartedAt = prefs.getInt(restStartedAtKey);
    if (restStartedAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final restElapsedSeconds = (now - restStartedAt) ~/ 1000;
      final restPlannedSeconds = prefs.getInt(restPlannedSecondsKey);
      final notified = prefs.getBool(restNotifiedKey) ?? false;
      if (restPlannedSeconds != null &&
          restElapsedSeconds >= restPlannedSeconds &&
          !notified) {
        await _fireRestOverPopup(prefs);
      }
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: snapshot.title,
      notificationText: snapshot.text,
    );
    // Record a heartbeat so the UI watchdog can detect a frozen service.
    await prefs.setInt(_lastTickKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Posts a high-importance "rest is over" notification and marks it fired so
  /// it is shown exactly once per rest. Falls back to English when the
  /// localized strings aren't cached yet.
  Future<void> _fireRestOverPopup(SharedPreferences prefs) async {
    try {
      final plugin = await _ensurePlugin();
      final title = prefs.getString(restAlarmTitleKey) ?? 'Rest is over';
      final body =
          prefs.getString(restAlarmBodyKey) ?? 'Your planned rest is complete.';
      await plugin.show(
        restPopupNotificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            restAlarmChannelId,
            restAlarmChannelName,
            channelDescription: restAlarmChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            // Public content visibility + alarm category so the popup shows
            // its content on a secure lock screen instead of being redacted
            // (notification-lock-screen T02).
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: restAlarmPayload,
      );
      await prefs.setBool(restNotifiedKey, true);
      // The scheduled fallback (rest_alarm.dart) is no longer needed — cancel
      // it so a late inexact alarm doesn't re-popup after the on-time alert.
      final setId = prefs.getString(restSetIdKey);
      if (setId != null) {
        try {
          await plugin.cancel(restAlarmNotificationId(setId));
        } catch (_) {}
      }
    } catch (_) {
      // Best-effort: never let a notification failure break the ticker.
    }
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

  /// Returns true when the ongoing notification/service is up (or when the
  /// permission was denied but the session was still persisted — callers show
  /// a settings nudge on false).
  Future<bool> startWorkoutNotification({
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
    await _prefs.setString(_watchdogNameKey, workoutName);
    await _prefs.setInt(
      _watchdogStartedAtKey,
      startedAt.millisecondsSinceEpoch,
    );

    if (Platform.isAndroid) {
      // The channel init runs post-first-frame; a workout started earlier
      // must wait for it or startService throws / silently shows nothing.
      try {
        await ensureForegroundServiceInitialized().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {}
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }
      final notificationsAllowed = await Permission.notification.isGranted;
      if (!notificationsAllowed) {
        _log.warning('POST_NOTIFICATIONS denied — ongoing notification hidden');
      }
      // Ask the OS to exclude us from Doze / battery optimization so the
      // foreground ticker isn't suspended (keeps the elapsed timer alive,
      // including on the lock screen). MIUI/HyperOS needs this plus manual
      // Autostart + Unrestricted battery in system settings.
      try {
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      } catch (_) {
        // Best-effort: some devices/ROMs reject this; ignore.
      }
      try {
        ServiceRequestResult startResult;
        if (await FlutterForegroundTask.isRunningService) {
          startResult = await FlutterForegroundTask.restartService();
        } else {
          startResult = await FlutterForegroundTask.startService(
            serviceId: _serviceId,
            serviceTypes: _serviceTypes,
            notificationTitle: workoutName,
            notificationText: '${l10n.activeWorkoutElapsedLabel} 00:00',
            notificationInitialRoute: '/active-workout',
            callback: activeWorkoutTaskCallback,
          );
        }
        if (startResult is ServiceRequestFailure) {
          _log.warning('workout service start failed', startResult.error);
        }
      } catch (e) {
        _log.warning('workout service start threw', e);
      }
      var running = false;
      try {
        running = await FlutterForegroundTask.isRunningService;
        if (!running) {
          final retry = await FlutterForegroundTask.startService(
            serviceId: _serviceId,
            serviceTypes: _serviceTypes,
            notificationTitle: workoutName,
            notificationText: '${l10n.activeWorkoutElapsedLabel} 00:00',
            notificationInitialRoute: '/active-workout',
            callback: activeWorkoutTaskCallback,
          );
          if (retry is ServiceRequestFailure) {
            _log.warning('workout service retry failed', retry.error);
          }
          running = await FlutterForegroundTask.isRunningService;
        }
      } catch (e) {
        _log.warning('workout service retry threw', e);
      }
      _log.info('workout service running=$running allowed=$notificationsAllowed');
      _lastWorkoutName = workoutName;
      _lastStartedAt = startedAt;
      _startWatchdog();
      // Best-effort push so the shade shows current text immediately even if
      // the first background tick is delayed.
      unawaited(refreshActiveWorkoutNotification());
      return running && notificationsAllowed;
    } else if (Platform.isIOS) {
      await _showIosNotification(workoutName: workoutName, l10n: l10n);
      return true;
    }
    return false;
  }

  Future<void> stopWorkoutNotification() async {
    _stopWatchdog();
    // Clear any lingering "rest is over" popup + scheduled fallback so neither
    // gets stuck after completion.
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(restPopupNotificationId);
      final setId = _prefs.getString(restSetIdKey);
      if (setId != null) {
        await plugin.cancel(restAlarmNotificationId(setId));
      }
    } catch (_) {
      // Best-effort.
    }
    await _prefs.remove(activeWorkoutNameKey);
    await _prefs.remove(activeWorkoutStartedAtKey);
    await _prefs.remove(_watchdogNameKey);
    await _prefs.remove(_watchdogStartedAtKey);
    await _prefs.remove(_lastTickKey);
    if (Platform.isAndroid) {
      try {
        await FlutterForegroundTask.stopService();
      } catch (_) {}
    } else if (Platform.isIOS) {
      await _iosPlugin.cancel(_iosNotificationId);
    }
  }

  String? _lastWorkoutName;
  DateTime? _lastStartedAt;
  Timer? _watchdog;

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final active =
            (await SharedPreferences.getInstance()).getInt(activeWorkoutStartedAtKey) !=
                null;
        if (!active) {
          _stopWatchdog();
          return;
        }
        final running = await FlutterForegroundTask.isRunningService;
        if (!running) {
          final sp = await SharedPreferences.getInstance();
          final name = _lastWorkoutName ??
              sp.getString(_watchdogNameKey) ??
              sp.getString(activeWorkoutNameKey);
          final startedAtMillis = _lastStartedAt?.millisecondsSinceEpoch ??
              sp.getInt(_watchdogStartedAtKey) ??
              sp.getInt(activeWorkoutStartedAtKey);
          if (name != null && startedAtMillis != null) {
            try {
              await ensureForegroundServiceInitialized();
            } catch (_) {}
            try {
              final result = await FlutterForegroundTask.startService(
                serviceId: _serviceId,
                serviceTypes: _serviceTypes,
                notificationTitle: name,
                notificationText: name,
                notificationInitialRoute: '/active-workout',
                callback: activeWorkoutTaskCallback,
              );
              if (result is ServiceRequestFailure) {
                _log.warning('watchdog service restart failed', result.error);
              } else {
                _lastWorkoutName = name;
                _lastStartedAt =
                    DateTime.fromMillisecondsSinceEpoch(startedAtMillis);
              }
            } catch (e) {
              _log.warning('watchdog service restart threw', e);
            }
          }
          return;
        }
        final last = (await SharedPreferences.getInstance()).getInt(_lastTickKey);
        final now = DateTime.now().millisecondsSinceEpoch;
        if (last != null && now - last > 15000) {
          // Service is alive but the ticker has stalled — restart it.
          final restarted = await FlutterForegroundTask.restartService();
          if (restarted is ServiceRequestFailure) {
            _log.warning('watchdog stalled-tick restart failed', restarted.error);
          }
        }
      } catch (_) {
        // Never let the watchdog break app logic.
      }
    });
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
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
