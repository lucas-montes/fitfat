import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../exercise/providers/workouts.dart';
import '../settings/providers/settings.dart';
import '../ui/date_formats.dart';
import 'active_workout_notifier.dart';
import 'rest_alarm.dart';

/// SharedPreferences keys holding the epoch millis at which the current rest
/// period started, plus its set context. Written by the UI isolate and read
/// by the background task callback (its own isolate) so the ongoing
/// notification can render the elapsed rest time.
const restStartedAtKey = 'rest_started_at';
const restSetIdKey = 'rest_set_id';
const restPlannedSecondsKey = 'rest_planned_seconds';

/// Prefs flag (bool) set true by the foreground task handler once it has fired
/// the "rest is over" popup, so the popup is shown exactly once per rest.
/// Cleared when a rest starts or is cancelled.
const restNotifiedKey = 'rest_notified';

final class RestTimerState {
  final DateTime? startedAt;
  final String? setId;
  final int? plannedSeconds;
  const RestTimerState({this.startedAt, this.setId, this.plannedSeconds});

  bool get isResting => startedAt != null;

  /// Elapsed time at [now] since the rest started; zero when not resting.
  Duration elapsedAt(DateTime now) {
    final start = startedAt;
    if (start == null) return Duration.zero;
    final diff = now.difference(start);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Whether the elapsed rest has reached the planned duration. The count-up
  /// rest keeps running past this point — it is never auto-cancelled.
  bool isOverdue(DateTime now) {
    final planned = plannedSeconds;
    if (planned == null) return false;
    return elapsedAt(now).inSeconds >= planned;
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);

final class RestTimerNotifier extends Notifier<RestTimerState> {
  @override
  RestTimerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final startedAtMillis = prefs.getInt(restStartedAtKey);
    return RestTimerState(
      startedAt: startedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(startedAtMillis)
          : null,
      setId: prefs.getString(restSetIdKey),
      plannedSeconds: prefs.getInt(restPlannedSecondsKey),
    );
  }

  /// Starts a count-up rest. [planned] is the optional target: with one, the
  /// strip highlights once it is reached and the rest alarm fires; without
  /// one (a manual rest) the timer just counts. Either way the elapsed time
  /// is recorded on [setId] when the rest ends.
  Future<void> startRest({Duration? planned, String? setId}) async {
    // Finalize any running rest first so its actual elapsed time is recorded
    // and its alarm is cancelled before the timer is replaced. Guarded: a
    // recording failure must never abort the new rest (which would leave no
    // rest line and no rest-over alert anywhere).
    try {
      await cancelRest();
    } catch (e) {
      Logger('RestTimer').warning('finalizing previous rest failed', e);
    }
    final startedAt = DateTime.now();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(restStartedAtKey, startedAt.millisecondsSinceEpoch);
    // A target only means something for a rest attached to a set.
    final plannedSeconds = setId != null ? planned?.inSeconds : null;
    if (setId != null) {
      await prefs.setString(restSetIdKey, setId);
    } else {
      await prefs.remove(restSetIdKey);
    }
    if (plannedSeconds != null) {
      await prefs.setInt(restPlannedSecondsKey, plannedSeconds);
    } else {
      await prefs.remove(restPlannedSecondsKey);
    }
    state = RestTimerState(
      startedAt: startedAt,
      setId: setId,
      plannedSeconds: plannedSeconds,
    );
    // Allow the foreground handler to fire its "rest is over" popup again.
    await prefs.setBool(restNotifiedKey, false);

    // Schedule the one-shot rest alarm (sound/vibration from settings) to
    // fire when the planned rest elapses. A manual rest has no alarm.
    if (setId != null && plannedSeconds != null) {
      final settings = ref.read(settingsProvider);
      await ref
          .read(restAlarmSchedulerProvider)
          .schedule(
            setId: setId,
            fireAt: startedAt.add(Duration(seconds: plannedSeconds)),
            sound: settings.restAlarmSound,
            vibrate: settings.restAlarmVibration,
            plannedSeconds: plannedSeconds,
          );
    }

    // Push the updated text (rest line appears) from the UI isolate so the
    // notification is current immediately, even if the background tick stalls
    // (notification-timers T02).
    unawaited(refreshActiveWorkoutNotification());
  }

  Future<void> cancelRest() async {
    final running = state;
    if (running.setId != null) {
      await ref.read(restAlarmSchedulerProvider).cancel(running.setId!);
    }
    await _finalizeRunningRest();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(restStartedAtKey);
    await prefs.remove(restSetIdKey);
    await prefs.remove(restPlannedSecondsKey);
    await prefs.remove(restNotifiedKey);
    state = const RestTimerState();
    // Push the updated text (rest line removed) from the UI isolate
    // (notification-timers T02).
    unawaited(refreshActiveWorkoutNotification());
  }

  /// Records the actual rest taken for the running rest (if any) before it is
  /// replaced or cleared. The count-up rest keeps running past the planned
  /// duration (or has none, for a manual rest), so the recorded value is the
  /// full elapsed time, uncapped.
  Future<void> _finalizeRunningRest() async {
    final rest = state;
    final setId = rest.setId;
    if (!rest.isResting || setId == null) return;
    final elapsedSeconds = rest.elapsedAt(DateTime.now()).inSeconds;
    await ref
        .read(workoutRepositoryProvider)
        .recordSetRest(setId: setId, actualRestSeconds: elapsedSeconds);
  }
}

/// Formats a duration as `mm:ss`, or `h:mm:ss` once it reaches an hour.
/// Shared by the rest-timer UI and the background task callback. The `mm:ss`
/// notation is locale-independent and the background isolate has no
/// [BuildContext], so this stays context-free (padding via `DateFormats.twoDigit`).
String formatRestDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  return hours > 0
      ? '$hours:${DateFormats.twoDigit(minutes)}:${DateFormats.twoDigit(seconds)}'
      : '${DateFormats.twoDigit(minutes)}:${DateFormats.twoDigit(seconds)}';
}
