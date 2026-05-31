import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

const int _seanceServiceId = 256;
const String _seanceStartedAtKey = 'seance_started_at_millis';
const String _lastSetAtKey = 'last_set_completed_at_millis';
const String _seanceNameKey = 'seance_name';
const String _currentExerciseNameKey = 'current_exercise_name';
const String _notificationTitleKey = 'notification_title';

@pragma('vm:entry-point')
void seanceTaskCallback() {
  FlutterForegroundTask.setTaskHandler(SeanceTaskHandler());
}

class SeanceForegroundService {
  SeanceForegroundService._();

  static final SeanceForegroundService instance = SeanceForegroundService._();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _requestPermissions();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'seance_channel',
        channelName: 'Workout',
        channelDescription: 'Running workout timer',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
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
    _initialized = true;
  }

  Future<void> start(
    DateTime startedAt, {
    String? seanceName,
    String? exerciseName,
    String? notificationTitle,
  }) async {
    await init();
    await FlutterForegroundTask.saveData(
      key: _seanceStartedAtKey,
      value: startedAt.millisecondsSinceEpoch,
    );
    if (seanceName != null) {
      await FlutterForegroundTask.saveData(
        key: _seanceNameKey,
        value: seanceName,
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
      serviceId: _seanceServiceId,
      notificationTitle: title,
      notificationText:
          'Elapsed: ${_formatElapsed(DateTime.now().difference(startedAt))}',
      notificationInitialRoute: '/current-seance',
      callback: seanceTaskCallback,
    );
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(key: _seanceStartedAtKey);
    await FlutterForegroundTask.removeData(key: _lastSetAtKey);
  }

  Future<void> lastSetCompleted() async {
    await FlutterForegroundTask.saveData(
      key: _lastSetAtKey,
      value: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> updateExerciseName(String exerciseName) async {
    await FlutterForegroundTask.saveData(
      key: _currentExerciseNameKey,
      value: exerciseName,
    );
  }

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

class SeanceTaskHandler extends TaskHandler {
  DateTime? _startedAt;
  DateTime? _lastSetAt;
  String? _seanceName;
  String? _currentExerciseName;
  String? _notificationTitle;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final startedAtMillis = await FlutterForegroundTask.getData(
      key: _seanceStartedAtKey,
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
    _seanceName =
        await FlutterForegroundTask.getData(key: _seanceNameKey) as String?;
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
    // Re-read last set time, exercise name, and title from storage each tick
    // so new values from the foreground are picked up immediately.
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

  void _buildNotification(DateTime timestamp, DateTime startedAt) {
    final elapsed = timestamp.difference(startedAt);
    final elapsedStr = _formatElapsed(elapsed);
    final title = _notificationTitle ?? _formatDate(startedAt);

    // Build body: [Exercise name] — [Seance name] or just elapsed time
    String text;
    final exercise = _currentExerciseName;
    final seance = _seanceName;

    String exerciseSeanceInfo = '';
    if (exercise != null && seance != null) {
      exerciseSeanceInfo = '$exercise — $seance\n';
    } else if (exercise != null) {
      exerciseSeanceInfo = '$exercise\n';
    } else if (seance != null) {
      exerciseSeanceInfo = '$seance\n';
    }

    final lastSet = _lastSetAt;
    String elapsedRest = '';
    if (lastSet != null) {
      final restStr = _formatElapsed(timestamp.difference(lastSet));
      elapsedRest = 'Elapsed: $elapsedStr\nRest: $restStr';
    } else {
      elapsedRest = 'Elapsed: $elapsedStr';
    }

    text = '$exerciseSeanceInfo$elapsedRest';

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationInitialRoute: '/current-seance',
    );
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.sendDataToMain({'type': 'open_current_seance'});
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
