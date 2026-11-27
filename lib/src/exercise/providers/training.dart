import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show immutable;

import '../../dashboard/providers/dashboard.dart' show startOfCalendarWeek;
import '../../database/database_provider.dart';
import '../../models/workout.dart';
import '../repositories/training_summaries.dart';
import 'workout_templates.dart';
import 'workouts.dart';

final trainingSummariesProvider = Provider<TrainingSummaries>(
  (ref) => TrainingSummaries(ref.watch(databaseProvider)),
);

/// Row summaries for every workout. Recomputes whenever the workout list is
/// invalidated (every workout mutation already does that).
final workoutRowSummariesProvider =
    FutureProvider<Map<String, WorkoutRowSummary>>((ref) async {
      await ref.watch(workoutListProvider.future);
      return ref.watch(trainingSummariesProvider).rowSummaries();
    });

/// Latest completed set per exercise id.
final lastSetPerExerciseProvider = FutureProvider<Map<String, LastSet>>((
  ref,
) async {
  await ref.watch(workoutListProvider.future);
  return ref.watch(trainingSummariesProvider).lastSetPerExercise();
});

/// Template cards with exercises and last-done dates.
final templateCardsProvider = FutureProvider<List<TemplateCard>>((ref) async {
  await ref.watch(workoutListProvider.future);
  await ref.watch(workoutTemplateListProvider.future);
  return ref.watch(trainingSummariesProvider).templateCards();
});

/// A workout you repeat: its latest session plus how often it was done.
@immutable
final class RecentRoutine {
  const RecentRoutine({
    required this.latest,
    required this.count,
    required this.summary,
  });

  final Workout latest;
  final int count;
  final WorkoutRowSummary summary;
}

/// Groups completed workouts into routines: by `routineId` (replays share
/// it), else by case-insensitive name. Most recent first.
List<RecentRoutine> groupRoutines(
  List<Workout> workouts,
  Map<String, WorkoutRowSummary> summaries,
) {
  final byKey = <String, List<Workout>>{};
  for (final w in workouts) {
    if (!w.isCompleted) continue;
    final key = w.routineId ?? 'name:${w.name.trim().toLowerCase()}';
    (byKey[key] ??= []).add(w);
  }
  final routines = [
    for (final list in byKey.values)
      () {
        list.sort((a, b) => b.date.compareTo(a.date));
        return RecentRoutine(
          latest: list.first,
          count: list.length,
          summary: summaries[list.first.id] ?? WorkoutRowSummary.empty,
        );
      }(),
  ];
  // Two routines can share a name (a replay chain and an older one-off);
  // keep only the most recent per display name.
  routines.sort((a, b) => b.latest.date.compareTo(a.latest.date));
  final seen = <String>{};
  return [
    for (final r in routines)
      if (seen.add(r.latest.name.trim().toLowerCase())) r,
  ];
}

final recentRoutinesProvider = FutureProvider<List<RecentRoutine>>((ref) async {
  final workouts = await ref.watch(workoutListProvider.future);
  final summaries = await ref.watch(workoutRowSummariesProvider.future);
  return groupRoutines(workouts, summaries);
});

/// One calendar week of completed workouts with its totals.
@immutable
final class WeekGroup {
  const WeekGroup({required this.start, required this.workouts});

  /// Monday 00:00.
  final DateTime start;

  /// Newest first.
  final List<(Workout, WorkoutRowSummary)> workouts;

  DateTime get end => start.add(const Duration(days: 6));

  /// Days (0 = Monday) with at least one workout.
  Set<int> get days => {
    for (final (w, _) in workouts) w.date.weekday - DateTime.monday,
  };
  int get minutes => workouts.fold(0, (a, e) => a + e.$2.minutes);
  double get volumeKg => workouts.fold(0.0, (a, e) => a + e.$2.volumeKg);
  double get distanceKm => workouts.fold(0.0, (a, e) => a + e.$2.distanceKm);
}

/// Completed workouts inside [from, until) (either bound optional), grouped
/// by calendar week, newest week first.
List<WeekGroup> groupWeeks(
  List<Workout> workouts,
  Map<String, WorkoutRowSummary> summaries, {
  DateTime? from,
  DateTime? until,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  final byWeek = <DateTime, List<(Workout, WorkoutRowSummary)>>{};
  for (final w in workouts) {
    if (!w.isCompleted) continue;
    if (from != null && w.date.isBefore(from)) continue;
    if (until != null && !w.date.isBefore(until)) continue;
    if (q.isNotEmpty && !w.name.toLowerCase().contains(q)) continue;
    (byWeek[startOfCalendarWeek(w.date)] ??= []).add((
      w,
      summaries[w.id] ?? WorkoutRowSummary.empty,
    ));
  }
  final weeks = [
    for (final MapEntry(key: start, value: list) in byWeek.entries)
      WeekGroup(
        start: start,
        workouts: list..sort((a, b) => b.$1.date.compareTo(a.$1.date)),
      ),
  ]..sort((a, b) => b.start.compareTo(a.start));
  return weeks;
}
