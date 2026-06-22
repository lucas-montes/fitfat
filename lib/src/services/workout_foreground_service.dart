import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Notification channel and service identifiers.
/// These must be unique to avoid conflicts with other foreground services.
const int _workoutServiceId = 256;
const String _workoutStartedAtKey = 'workout_started_at_millis';
const String _lastSetAtKey = 'last_set_completed_at_millis';
const String _workoutNameKey = 'workout_name';
const String _currentExerciseNameKey = 'current_exercise_name';
const String _notificationTitleKey = 'notification_title';

/// Entry point for the foreground service task handler.
/// This runs in a separate isolate. The @pragma ensures it's not tree-shaken.
@pragma('vm:entry-point')
void workoutTaskCallback() {
  FlutterForegroundTask.setTaskHandler(WorkoutTaskHandler());
}

/// Manages a persistent foreground notification for the active workout.
///
/// Why a foreground service?
/// 1. Android kills background services — a foreground notification with
///    an ongoing "Workout in progress" alert keeps the process alive.
/// 2. It allows the app to update the notification text from a background
///    isolate every second (elapsed time, rest timer, current exercise).
/// 3. The notification is actionable — tapping it opens the active workout.
///
/// Lifecycle:
/// - `start(...)` — called when a workout begins (free-form or scheduled)
/// - `lastSetCompleted()` — called after each set is completed, updates rest
/// - `updateExerciseName(...)` — called when the user switches exercises
/// - `stop()` — called when the workout is completed or cancelled
class WorkoutForegroundService {
  WorkoutForegroundService._();

  static final WorkoutForegroundService instance = WorkoutForegroundService._();
  bool _initialized = false;

  /// Initialize the foreground task plugin and request permissions.
  ///
  /// On Android, this requests notification permission and battery optimization
  /// exemption. Without battery exemption, the OS may kill the notification
  /// service after 10-15 minutes on some manufacturers (Xiaomi, Huawei, etc.).
  Future<void> init() async {
    if (_initialized) return;
    await _requestPermissions();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'workout_channel',
        channelName: 'Workout',
        channelDescription: 'Running workout timer',
        onlyAlertOnce: true, // Don't re-alert on every update
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false, // No sound for periodic timer updates
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000), // Update every 1s
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true, // Keep screen on during workout
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// Start the foreground service with the workout's start time.
  ///
  /// Persists `startedAt`, `workoutName`, and `exerciseName` to shared storage
  /// so the background isolate can read them on each tick. The initial
  /// notification shows just the elapsed time; rest and exercise info are
  /// added as `lastSetCompleted()` and `updateExerciseName()` are called.
  Future<void> start(
    DateTime startedAt, {
    String? workoutName,
    String? exerciseName,
    String? notificationTitle,
  }) async {
    await init();
    await FlutterForegroundTask.saveData(
      key: _workoutStartedAtKey,
      value: startedAt.millisecondsSinceEpoch,
    );
    if (workoutName != null) {
      await FlutterForegroundTask.saveData(
        key: _workoutNameKey,
        value: workoutName,
      );
    }
    if (exerciseName != null) {
      await FlutterForegroundTask.saveData(
        key: _currentExerciseNameKey,
        value: exerciseName,
      );
    }
    final title = notificationTitle ?? _formatDate(startedAt);
    if (notificationTitle != null) {
      await FlutterForegroundTask.saveData(
        key: _notificationTitleKey,
        value: notificationTitle,
      );
    }
    await FlutterForegroundTask.startService(
      serviceId: _workoutServiceId,
      notificationTitle: title,
      notificationText:
          'Elapsed: ${_formatElapsed(DateTime.now().difference(startedAt))}',
      notificationInitialRoute: '/active-workout',
      callback: workoutTaskCallback,
    );
  }

  /// Stop the foreground service and clean up persisted keys.
  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(key: _workoutStartedAtKey);
    await FlutterForegroundTask.removeData(key: _lastSetAtKey);
  }

  /// Record the timestamp of the last completed set.
  ///
  /// The background isolate (WorkoutTaskHandler) reads this key on each tick
  /// and displays "Rest: mm:ss" in the notification when it's set.
  Future<void> lastSetCompleted() async {
    await FlutterForegroundTask.saveData(
      key: _lastSetAtKey,
      value: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Update the current exercise name shown in the notification.
  Future<void> updateExerciseName(String exerciseName) async {
    await FlutterForegroundTask.saveData(
      key: _currentExerciseNameKey,
      value: exerciseName,
    );
  }

  /// Request notification permission and battery optimization exemption.
  /// Required on Android 13+ for notification access and to keep the
  /// foreground service alive for extended periods.
  Future<void> _requestPermissions() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (Platform.isAndroid &&
        !await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  /// Format a Duration as mm:ss or hh:mm:ss for the notification.
  String _formatElapsed(Duration elapsed) {
    if (elapsed.inHours > 0) {
      final h = elapsed.inHours;
      final m = elapsed.inMinutes % 60;
      final s = elapsed.inSeconds % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  /// Format a DateTime as DD/MM/YYYY for the default notification title.
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

/// Background isolate task handler for the workout foreground service.
///
/// This handler runs in a separate isolate from the Flutter UI. It cannot
/// access Riverpod or in-memory state. All communication happens through
/// `FlutterForegroundTask.saveData()` / `FlutterForegroundTask.getData()`,
/// which persists to a shared preferences-like store accessible from both
/// the main isolate (workout screens, providers) and this background isolate.
///
/// onRepeatEvent fires every 1 second (configured in ForegroundTaskOptions).
class WorkoutTaskHandler extends TaskHandler {
  DateTime? _startedAt;
  DateTime? _lastSetAt;
  String? _workoutName;
  String? _currentExerciseName;
  String? _notificationTitle;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Load all persisted data once on startup.
    final startedAtMillis = await FlutterForegroundTask.getData(
      key: _workoutStartedAtKey,
    );
    if (startedAtMillis is int) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMillis);
    }
    final lastSetMillis = await FlutterForegroundTask.getData(
      key: _lastSetAtKey,
    );
    if (lastSetMillis is int) {
      _lastSetAt = DateTime.fromMillisecondsSinceEpoch(lastSetMillis);
    }
    _workoutName =
        await FlutterForegroundTask.getData(key: _workoutNameKey) as String?;
    _currentExerciseName =
        await FlutterForegroundTask.getData(key: _currentExerciseNameKey)
            as String?;
    _notificationTitle =
        await FlutterForegroundTask.getData(key: _notificationTitleKey)
            as String?;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final startedAt = _startedAt;
    if (startedAt == null) return;

    // Re-read dynamic values (last set time, exercise name, title) from
    // storage on every tick. The main isolate writes these via saveData()
    // whenever a set is completed or the exercise changes. Reading them
    // here ensures the notification stays up-to-date without needing any
    // cross-isolate communication channel.
    _lastSetAt = null; // reset, will be re-read below
    // ignore: discarded_futures
    Future.wait([
      FlutterForegroundTask.getData(key: _lastSetAtKey),
      FlutterForegroundTask.getData(key: _currentExerciseNameKey),
      FlutterForegroundTask.getData(key: _notificationTitleKey),
    ]).then((values) {
      if (values[0] is int) {
        _lastSetAt = DateTime.fromMillisecondsSinceEpoch(values[0] as int);
      }
      if (values[1] is String) {
        _currentExerciseName = values[1] as String?;
      }
      if (values[2] is String) {
        _notificationTitle = values[2] as String?;
      }
      _buildNotification(timestamp, startedAt);
    });
  }

  /// Build and update the notification with current workout state.
  ///
  /// Notification format:
  /// ```
  /// [Exercise Name] — [Workout Name]
  /// Elapsed: mm:ss
  /// Rest: mm:ss          (only when lastSetAt is set)
  /// ```
  ///
  /// The rest timer counts UP from the last completed set (not a countdown),
  /// since we don't know the configured rest period in the background isolate.
  void _buildNotification(DateTime timestamp, DateTime startedAt) {
    final elapsed = timestamp.difference(startedAt);
    final elapsedStr = _formatElapsed(elapsed);
    final title = _notificationTitle ?? _formatDate(startedAt);

    // Build body: [Exercise name] — [Workout name] or just elapsed time
    String text;
    final exercise = _currentExerciseName;
    final workout = _workoutName;

    String exerciseWorkoutInfo = '';
    if (exercise != null && workout != null) {
      exerciseWorkoutInfo = '$exercise — $workout\n';
    } else if (exercise != null) {
      exerciseWorkoutInfo = '$exercise\n';
    } else if (workout != null) {
      exerciseWorkoutInfo = '$workout\n';
    }

    final lastSet = _lastSetAt;
    String elapsedRest = '';
    if (lastSet != null) {
      final restStr = _formatElapsed(timestamp.difference(lastSet));
      elapsedRest = 'Elapsed: $elapsedStr\nRest: $restStr';
    } else {
      elapsedRest = 'Elapsed: $elapsedStr';
    }

    text = '$exerciseWorkoutInfo$elapsedRest';

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationInitialRoute: '/active-workout',
    );
  }

  @override
  void onNotificationPressed() {
    // When the user taps the notification, send a message to the main isolate.
    // The ActiveWorkoutScreen listens for this and navigates to the workout.
    FlutterForegroundTask.sendDataToMain({'type': 'open_current_workout'});
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  String _formatElapsed(Duration elapsed) {
    if (elapsed.inHours > 0) {
      final h = elapsed.inHours;
      final m = elapsed.inMinutes % 60;
      final s = elapsed.inSeconds % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
