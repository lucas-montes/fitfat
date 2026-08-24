import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/database_provider.dart';
import '../../notifications/active_workout_notifier.dart';
import '../../notifications/rest_timer.dart';
import '../../notifications/task_reminders.dart';
import '../providers/settings.dart';

/// Erases every user-created row and every setting so the app is back to a
/// fresh first-launch state — all without killing the process.
///
/// Steps: cancel scheduled notifications → stop the active-workout foreground
/// service → close the database → delete the SQLite files → clear all prefs →
/// invalidate the database and settings providers so every screen rebuilds
/// from scratch.
Future<void> resetAllData(WidgetRef ref) async {
  final log = Logger('DataReset');

  // 1. Cancel scheduled notifications (best-effort): planner reminders, any
  // running rest alarm, and the active-workout ongoing notification.
  try {
    await ref.read(taskReminderSchedulerProvider).cancelAll();
  } catch (e) {
    log.warning('Cancelling task reminders failed: $e');
  }
  try {
    await ref.read(restTimerProvider.notifier).cancelRest();
  } catch (e) {
    log.warning('Cancelling rest timer failed: $e');
  }
  try {
    await ref.read(activeWorkoutNotifierProvider).stopWorkoutNotification();
  } catch (e) {
    log.warning('Stopping workout notification failed: $e');
  }

  // 2. Close the app's database so its files can be removed.
  try {
    await ref.read(databaseProvider).close();
  } catch (e) {
    log.warning('Closing database failed: $e');
  }
  ref.invalidate(databaseProvider);

  // 3. Delete the SQLite files (and any side files) plus synced exercise
  // media so no orphaned binaries survive the reset.
  final dbFolder = await getApplicationDocumentsDirectory();
  for (final name in [
    'fitfat.sqlite',
    'fitfat.sqlite-wal',
    'fitfat.sqlite-shm',
  ]) {
    final file = File(p.join(dbFolder.path, name));
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      log.warning('Deleting "$name" failed: $e');
    }
  }
  final mediaDir = Directory(p.join(dbFolder.path, 'exercise_media'));
  try {
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
  } catch (e) {
    log.warning('Deleting exercise media failed: $e');
  }

  // 4. Clear every preference (settings + one-time flags + session keys).
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.clear();

  // 5. Rebuild settings from the (now empty) prefs and recreate the DB lazily
  // on next access. Invalidating the database cascades to every data provider.
  ref.invalidate(settingsProvider);
}
