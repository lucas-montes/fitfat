import 'package:drift/drift.dart'
    show Variable, BooleanExpressionOperators, ComparableExpr;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/startup_gate.dart';
import '../../budget/providers/accounts.dart';
import '../../budget/providers/transactions.dart';
import '../../budget/services/money_data.dart';
import '../../database/app_database.dart' as db;
import '../../database/database_provider.dart';
import '../../diet/providers/meals.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/goal.dart';
import '../providers/goals.dart';

/// Where a goal can read its progress from. Stored as [id] in
/// `goals.track_source`; null there means the user records it by hand.
enum TrackSource {
  exerciseBest('exercise_best', needsExercise: true),
  exerciseDistance('exercise_distance', needsExercise: true),
  workoutsCount('workouts_count'),
  bodyWeight('body_weight'),
  accountBalance('account_balance', needsAccount: true),
  mealsProtein('meals_protein'),
  tasksDone('tasks_done');

  const TrackSource(
    this.id, {
    this.needsExercise = false,
    this.needsAccount = false,
  });

  final String id;
  final bool needsExercise;
  final bool needsAccount;

  static TrackSource? parse(String? id) =>
      TrackSource.values.where((s) => s.id == id).firstOrNull;

  /// The unit a source reports in (the goal's own unit wins when set).
  String get unit => switch (this) {
    exerciseBest || bodyWeight => 'kg',
    exerciseDistance => 'km',
    workoutsCount => '',
    accountBalance => '',
    mealsProtein => 'g',
    tasksDone => '',
  };
}

/// One dated value of a goal's progress.
typedef GoalPoint = ({DateTime day, double value});

/// A goal's progress: every point (oldest first), the current value and the
/// 0..1 share of the target reached.
final class GoalStatusView {
  const GoalStatusView({
    required this.points,
    required this.current,
    required this.progress,
    required this.source,
  });

  final List<GoalPoint> points;
  final double? current;
  final double? progress;
  final TrackSource? source;

  DateTime? get updated => points.isEmpty ? null : points.last.day;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Collapses same-day values (keeps the last) and sorts oldest first.
List<GoalPoint> _byDay(Iterable<GoalPoint> pts) {
  final m = <DateTime, double>{};
  for (final p in pts) {
    m[_day(p.day)] = p.value;
  }
  final days = m.keys.toList()..sort();
  return [for (final d in days) (day: d, value: m[d]!)];
}

/// Running maximum of per-day values.
List<GoalPoint> _runningMax(List<GoalPoint> pts) {
  var best = double.negativeInfinity;
  final out = <GoalPoint>[];
  for (final p in pts) {
    if (p.value > best) best = p.value;
    out.add((day: p.day, value: best));
  }
  return out;
}

/// Reads a goal's series from the app's data. Pure over the database plus
/// the already-loaded providers it is handed.
final class GoalTracker {
  GoalTracker(this._db);
  final db.AppDatabase _db;

  /// Best set weight (kg) or longest distance (km) per day for an exercise,
  /// from finished workouts, as a running best.
  Future<List<GoalPoint>> exerciseSeries(
    String exerciseId, {
    required bool distance,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT w.date AS day, MAX(${distance ? 's.actual_distance_meters' : 's.actual_weight_kg'}) AS v '
          'FROM exercise_sets s '
          'JOIN workout_exercises we ON we.id = s.workout_exercise_id '
          'JOIN workouts w ON w.id = we.workout_id '
          'WHERE we.exercise_id = ?1 AND w.deleted_at IS NULL '
          'AND w.completed_at IS NOT NULL '
          'AND ${distance ? 's.actual_distance_meters' : 's.actual_weight_kg'} IS NOT NULL '
          'GROUP BY w.date ORDER BY w.date',
          variables: [Variable.withString(exerciseId)],
          readsFrom: {_db.exerciseSets, _db.workoutExercises, _db.workouts},
        )
        .get();
    return _runningMax([
      for (final r in rows)
        (
          day: DateTime.fromMillisecondsSinceEpoch(r.read<int>('day')),
          value: distance ? r.read<double>('v') / 1000 : r.read<double>('v'),
        ),
    ]);
  }

  /// Finished workouts since [since], counted up day by day.
  Future<List<GoalPoint>> workoutsSeries(DateTime since) async {
    final rows =
        await (_db.select(_db.workouts)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.completedAt.isNotNull() &
                  t.date.isBiggerOrEqualValue(
                    _day(since).millisecondsSinceEpoch,
                  ),
            ))
            .get();
    final days =
        rows
            .map((r) => _day(DateTime.fromMillisecondsSinceEpoch(r.date)))
            .toList()
          ..sort();
    var n = 0;
    return _byDay([for (final d in days) (day: d, value: (++n).toDouble())]);
  }

  Future<List<GoalPoint>> bodyWeightSeries() async {
    final rows = await (_db.select(
      _db.bodyMetrics,
    )..where((t) => t.deletedAt.isNull() & t.weightKg.isNotNull())).get();
    return _byDay([
      for (final r in rows)
        (day: DateTime.fromMillisecondsSinceEpoch(r.date), value: r.weightKg!),
    ]);
  }
}

/// Seven-day average of daily protein, one point per day with meals.
List<GoalPoint> proteinSeries(Map<DateTime, double> dailyProtein) {
  final days = dailyProtein.keys.toList()..sort();
  return [
    for (final d in days)
      (
        day: d,
        value: () {
          var sum = 0.0;
          var n = 0;
          for (var i = 0; i < 7; i++) {
            final v = dailyProtein[d.subtract(Duration(days: i))];
            if (v != null) {
              sum += v;
              n++;
            }
          }
          return n == 0 ? 0.0 : sum / n;
        }(),
      ),
  ];
}

final goalTrackerProvider = Provider<GoalTracker>(
  (ref) => GoalTracker(ref.watch(databaseProvider)),
);

/// The current status of a goal: its series (from the tracked source, or the
/// manual log), the current value and the share of the target reached.
final goalStatusProvider = FutureProvider.family<GoalStatusView, String>((
  ref,
  goalId,
) async {
  if (!ref.watch(startupGateProvider)) {
    return const GoalStatusView(
      points: [],
      current: null,
      progress: null,
      source: null,
    );
  }
  final goal = await ref.watch(goalByIdProvider(goalId).future);
  if (goal == null) {
    return const GoalStatusView(
      points: [],
      current: null,
      progress: null,
      source: null,
    );
  }
  final source = TrackSource.parse(goal.trackSource);
  final tracker = ref.watch(goalTrackerProvider);
  List<GoalPoint> points;
  switch (source) {
    case null:
      final log = await ref.watch(goalProgressProvider(goalId).future);
      points = _byDay([for (final p in log) (day: p.day, value: p.value)]);
    case TrackSource.exerciseBest || TrackSource.exerciseDistance:
      // Recompute when workouts change.
      await ref.watch(workoutListProvider.future);
      points = goal.trackParam == null
          ? const []
          : await tracker.exerciseSeries(
              goal.trackParam!,
              distance: source == TrackSource.exerciseDistance,
            );
    case TrackSource.workoutsCount:
      await ref.watch(workoutListProvider.future);
      points = await tracker.workoutsSeries(goal.startDate);
    case TrackSource.bodyWeight:
      points = await tracker.bodyWeightSeries();
    case TrackSource.accountBalance:
      final accounts = await ref.watch(accountListProvider.future);
      final txns = await ref.watch(liveTransactionsProvider.future);
      final account = accounts
          .where((a) => a.id == goal.trackParam)
          .firstOrNull;
      if (account == null) {
        points = const [];
      } else {
        final today = _day(DateTime.now());
        final from = goal.startDate.isBefore(today)
            ? goal.startDate
            : today.subtract(const Duration(days: 90));
        final series = balanceSeries(account, txns, from: from, to: today);
        // One point a week (plus today) keeps the chart readable.
        points = [
          for (var i = 0; i < series.length; i++)
            if (i % 7 == 0 || i == series.length - 1)
              (day: series[i].day, value: series[i].balance),
        ];
      }
    case TrackSource.mealsProtein:
      final meals = await ref.watch(mealListProvider.future);
      final daily = <DateTime, double>{};
      for (final m in meals) {
        final d = _day(m.eatenAt);
        daily[d] = (daily[d] ?? 0) + m.totalProtein;
      }
      points = proteinSeries(daily);
    case TrackSource.tasksDone:
      final linked = await ref.watch(tasksByGoalProvider(goalId).future);
      final days = [
        for (final l in linked)
          if (l.item.done) _day(l.item.day),
      ]..sort();
      var n = 0;
      points = _byDay([
        for (final d in days) (day: d, value: (++n).toDouble()),
      ]);
  }
  final current = points.isEmpty ? null : points.last.value;
  return GoalStatusView(
    points: points,
    current: current,
    progress: goal.progressFrom(current),
    source: source,
  );
});

/// A short label for where a goal's number comes from, for the UI.
bool goalIsAuto(Goal g) => TrackSource.parse(g.trackSource) != null;
