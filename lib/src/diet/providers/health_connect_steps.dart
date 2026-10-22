import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reads step counts from Google Health Connect on Android.
///
/// Returns empty (or 0) on other platforms, when authorization is
/// missing/denied, or on any failure, so consumers degrade gracefully.
final class HealthConnectSteps {
  final Health _health;
  HealthConnectSteps() : _health = Health();

  /// Daily step totals between [from] (inclusive) and [to] (inclusive),
  /// oldest first. Best-effort: returns an empty list when steps are
  /// unavailable, denied, or the range spans too far back for the platform.
  Future<List<({DateTime day, int steps})>> getDailySteps(
    DateTime from,
    DateTime to,
  ) async {
    if (!Platform.isAndroid) return const [];
    try {
      await _health.configure();
      await Permission.activityRecognition.request();
      final authorized =
          await _health.hasPermissions([HealthDataType.STEPS]) ?? false;
      if (!authorized) return const [];

      final fromDay = DateTime(from.year, from.month, from.day);
      final toDay = DateTime(
        to.year,
        to.month,
        to.day,
      ).add(const Duration(days: 1));
      final days = <({DateTime day, int steps})>[];
      var cursor = fromDay;
      while (!cursor.isAfter(toDay)) {
        final dayEnd = cursor.add(const Duration(days: 1));
        final steps = await _health.getTotalStepsInInterval(cursor, dayEnd);
        days.add((day: cursor, steps: steps ?? 0));
        cursor = dayEnd;
      }
      return days;
    } catch (_) {
      return const [];
    }
  }
}

final healthConnectStepsProvider = Provider<HealthConnectSteps>(
  (ref) => HealthConnectSteps(),
);
