import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

const int _seanceServiceId = 256;
const String _seanceStartedAtKey = 'seance_started_at_millis';

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
        channelName: 'Seance',
        channelDescription: 'Running seance timer',
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

  Future<void> start(DateTime startedAt) async {
    await init();
    await FlutterForegroundTask.saveData(
      key: _seanceStartedAtKey,
      value: startedAt.millisecondsSinceEpoch,
    );
    await FlutterForegroundTask.startService(
      serviceId: _seanceServiceId,
      notificationTitle: 'Seance running',
      notificationText: _formatElapsed(DateTime.now().difference(startedAt)),
      notificationInitialRoute: '/current-seance',
      callback: seanceTaskCallback,
    );
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(key: _seanceStartedAtKey);
  }

  Future<void> _requestPermissions() async {
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid &&
        !await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  String _formatElapsed(Duration elapsed) {
    if (elapsed.inHours > 0) {
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes % 60;
      final seconds = elapsed.inSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }
}

class SeanceTaskHandler extends TaskHandler {
  DateTime? _startedAt;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final startedAtMillis = await FlutterForegroundTask.getData(
      key: _seanceStartedAtKey,
    );
    if (startedAtMillis is int) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMillis);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final startedAt = _startedAt;
    if (startedAt == null) return;

    final elapsed = timestamp.difference(startedAt);
    FlutterForegroundTask.updateService(
      notificationTitle: 'Seance running',
      notificationText: _formatElapsed(elapsed),
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
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes % 60;
      final seconds = elapsed.inSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }
}
