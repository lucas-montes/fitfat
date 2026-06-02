import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'logger.dart';

final _log = logger('seance_notifications');

class SeanceNotificationService {
  SeanceNotificationService._();

  static final SeanceNotificationService instance =
      SeanceNotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  Timer? _updateTimer;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> startForeground({
    required String title,
    required DateTime startedAt,
  }) async {
    // For now, show a persistent local notification and update it periodically.
    await _showLocalNotification(
      id: 1,
      title: title,
      body: 'Tap to open current workout',
    );

    // start periodic updates to refresh notification text while app is foreground
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      final elapsed = DateTime.now().difference(startedAt);
      _updateLocalNotificationText(_formatElapsed(elapsed));
    });
  }

  Future<void> stop() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    // Nothing to stop for foreground task in this scaffold; cancel local notifications.
    try {
      await _local.cancelAll();
    } catch (e, st) {
      _log.warning('Failed to cancel local notifications', e, st);
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'seance_channel',
      'Workout',
      channelDescription: 'Active workout',
      importance: Importance.low,
      priority: Priority.defaultPriority,
      ongoing: true,
    );
    const iosDetails = DarwinNotificationDetails();
    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> _updateLocalNotificationText(String text) async {
    // On Android we can update the foreground notification via the plugin; on iOS we update a local notification when app resumes.
    try {
      await _local.show(
        1,
        'Workout',
        text,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'seance_channel',
            'Workout',
            channelDescription: 'Active workout',
            importance: Importance.low,
            priority: Priority.defaultPriority,
            ongoing: true,
          ),
        ),
      );
    } catch (e, st) {
      _log.warning('Failed to update local notification text', e, st);
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
}
