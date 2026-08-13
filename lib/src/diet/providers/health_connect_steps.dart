import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reads today's step count from Google Health Connect on Android.
///
/// Returns 0 on other platforms, when authorization is missing/denied, or on
/// any failure, so the calorie engine degrades gracefully to workouts-only.
final class HealthConnectSteps {
  final Health _health;
  HealthConnectSteps() : _health = Health();

  /// Steps since local midnight, or 0 when unavailable.
  Future<int> getTodaySteps() async {
    if (!Platform.isAndroid) return 0;
    try {
      await _health.configure();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      await Permission.activityRecognition.request();
      var authorized =
          await _health.hasPermissions([HealthDataType.STEPS]) ?? false;
      if (!authorized) {
        authorized = await _health.requestAuthorization([HealthDataType.STEPS]);
      }
      if (!authorized) return 0;

      try {
        await _health.requestHealthDataHistoryAuthorization();
      } catch (_) {
        // Best-effort: older Health Connect versions may not expose it.
      }
      try {
        await _health.requestHealthDataInBackgroundAuthorization();
      } catch (_) {
        // Best-effort: background access may be unavailable.
      }

      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

final healthConnectStepsProvider = Provider<HealthConnectSteps>(
  (ref) => HealthConnectSteps(),
);

/// Today's step count from the platform health store (0 when unavailable).
final todayStepsProvider = FutureProvider<int>((ref) async {
  return ref.watch(healthConnectStepsProvider).getTodaySteps();
});
