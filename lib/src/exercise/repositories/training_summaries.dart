import 'package:drift/drift.dart';
import 'package:material_ui/material_ui.dart' show immutable;

import '../../database/app_database.dart';

/// What a workout row on the training screens shows, computed in one pass
/// over every completed set (no per-workout detail resolution).
@immutable
final class WorkoutRowSummary {
  const WorkoutRowSummary({
    required this.minutes,
    required this.setCount,
    required this.volumeKg,
    required this.distanceKm,
    required this.hasPr,
  });

  static const empty = WorkoutRowSummary(
    minutes: 0,
    setCount: 0,
    volumeKg: 0,
    distanceKm: 0,
    hasPr: false,
  );

  final int minutes;
  final int setCount;
  final double volumeKg;
  final double distanceKm;

  /// A completed set beat every earlier set of its exercise: heavier, or the
  /// same weight for more reps. An exercise's first session is not a PR.
  final bool hasPr;

  /// Cardio-only: distance or time but no lifted volume.
  bool get isCardio => volumeKg == 0 && (distanceKm > 0 || minutes > 0);
}

/// The latest completed set of an exercise, for "last set" hints.
typedef LastSet = ({
  double? weightKg,
  int? reps,
  int? durationMinutes,
  double? distanceMeters,
});

/// A template with its blueprint, flattened for list cards.
@immutable
final class TemplateCard {
  const TemplateCard({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.exercises,
    this.lastDone,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// (exercise name, planned set count, first set reps, first set weight,
  /// duration minutes, distance meters), in template order.
  final List<TemplateExerciseLine> exercises;

  /// Date of the latest non-deleted workout started from this template.
  final DateTime? lastDone;

  int get setCount => exercises.fold(0, (a, e) => a + e.sets);

  /// Never started and created in the last 14 days — e.g. saved after a PR.
  bool isNew(DateTime now) =>
      lastDone == null && now.difference(createdAt).inDays < 14;
}

typedef TemplateExerciseLine = ({
  String name,
  int sets,
  int? reps,
  double? weightKg,
  int? durationMinutes,
  double? distanceMeters,
});

/// Read-only aggregates for the training home, history and template list.
final class TrainingSummaries {
  TrainingSummaries(this._db);

  final AppDatabase _db;

  /// A set counts once anything was logged (same rule as
  /// `ExerciseSet.isCompleted`); planned-only sets are ignored.
  Expression<bool> get _done =>
      _db.exerciseSets.actualReps.isNotNull() |
      _db.exerciseSets.actualDurationMinutes.isNotNull() |
      _db.exerciseSets.actualDistanceMeters.isNotNull();

  /// Row summaries for every non-deleted workout, keyed by workout id.
  Future<Map<String, WorkoutRowSummary>> rowSummaries() async {
    final rows =
        await (_db.select(_db.exerciseSets).join([
                innerJoin(
                  _db.workoutExercises,
                  _db.workoutExercises.id.equalsExp(
                    _db.exerciseSets.workoutExerciseId,
                  ),
                ),
                innerJoin(
                  _db.workouts,
                  _db.workouts.id.equalsExp(_db.workoutExercises.workoutId),
                ),
              ])
              ..where(_db.workouts.deletedAt.isNull() & _done)
              ..orderBy([
                OrderingTerm.asc(_db.workouts.date),
                OrderingTerm.asc(_db.exerciseSets.setNumber),
              ]))
            .get();

    final sets = <String, int>{};
    final volume = <String, double>{};
    final distance = <String, double>{};
    final loggedMinutes = <String, int>{};
    final pr = <String>{};
    // Best (weight, reps) per exercise across earlier workouts only.
    final best = <String, (double, int)>{};
    final bestThisWorkout = <String, (double, int)>{};
    String? currentWorkout;

    bool beats((double, int) a, (double, int)? b) =>
        b == null || a.$1 > b.$1 || (a.$1 == b.$1 && a.$2 > b.$2);

    void flush() {
      bestThisWorkout.forEach((ex, v) {
        if (beats(v, best[ex])) best[ex] = v;
      });
      bestThisWorkout.clear();
    }

    for (final row in rows) {
      final s = row.readTable(_db.exerciseSets);
      final we = row.readTable(_db.workoutExercises);
      final w = we.workoutId;
      if (w != currentWorkout) {
        flush();
        currentWorkout = w;
      }
      sets.update(w, (v) => v + 1, ifAbsent: () => 1);
      final reps = s.actualReps ?? 0;
      final kg = s.actualWeightKg ?? 0;
      volume.update(w, (v) => v + reps * kg, ifAbsent: () => reps * kg);
      final m = s.actualDistanceMeters ?? 0;
      if (m > 0) distance.update(w, (v) => v + m, ifAbsent: () => m);
      final mins = s.actualDurationMinutes ?? 0;
      if (mins > 0) {
        loggedMinutes.update(w, (v) => v + mins, ifAbsent: () => mins);
      }
      if (kg > 0 && reps > 0) {
        final value = (kg, reps);
        final prior = best[we.exerciseId];
        if (prior != null && beats(value, prior)) pr.add(w);
        if (beats(value, bestThisWorkout[we.exerciseId])) {
          bestThisWorkout[we.exerciseId] = value;
        }
      }
    }
    flush();

    final workouts = await (_db.select(
      _db.workouts,
    )..where((t) => t.deletedAt.isNull())).get();
    return {
      for (final w in workouts)
        w.id: WorkoutRowSummary(
          minutes: w.startedAt != null && w.completedAt != null
              ? ((w.completedAt! - w.startedAt!) / 60000).round()
              : loggedMinutes[w.id] ?? 0,
          setCount: sets[w.id] ?? 0,
          volumeKg: volume[w.id] ?? 0,
          distanceKm: (distance[w.id] ?? 0) / 1000,
          hasPr: pr.contains(w.id),
        ),
    };
  }

  /// Latest completed set per exercise id.
  Future<Map<String, LastSet>> lastSetPerExercise() async {
    final rows =
        await (_db.select(_db.exerciseSets).join([
                innerJoin(
                  _db.workoutExercises,
                  _db.workoutExercises.id.equalsExp(
                    _db.exerciseSets.workoutExerciseId,
                  ),
                ),
                innerJoin(
                  _db.workouts,
                  _db.workouts.id.equalsExp(_db.workoutExercises.workoutId),
                ),
              ])
              ..where(_db.workouts.deletedAt.isNull() & _done)
              ..orderBy([
                OrderingTerm.asc(_db.workouts.date),
                OrderingTerm.asc(_db.exerciseSets.setNumber),
              ]))
            .get();
    final out = <String, LastSet>{};
    for (final row in rows) {
      final s = row.readTable(_db.exerciseSets);
      out[row.readTable(_db.workoutExercises).exerciseId] = (
        weightKg: s.actualWeightKg,
        reps: s.actualReps,
        durationMinutes: s.actualDurationMinutes,
        distanceMeters: s.actualDistanceMeters,
      );
    }
    return out;
  }

  /// Ids of the sets in [workoutId] that beat every earlier set of their
  /// exercise (heavier, or same weight for more reps). An exercise's first
  /// session has no PRs.
  Future<Set<String>> prSetIds(String workoutId) async {
    final w = await (_db.select(
      _db.workouts,
    )..where((t) => t.id.equals(workoutId))).getSingleOrNull();
    if (w == null) return const {};
    final rows =
        await (_db.select(_db.exerciseSets).join([
              innerJoin(
                _db.workoutExercises,
                _db.workoutExercises.id.equalsExp(
                  _db.exerciseSets.workoutExerciseId,
                ),
              ),
              innerJoin(
                _db.workouts,
                _db.workouts.id.equalsExp(_db.workoutExercises.workoutId),
              ),
            ])..where(
              _db.workouts.deletedAt.isNull() &
                  _db.workouts.date.isSmallerOrEqualValue(w.date) &
                  _done,
            ))
            .get();
    final prior = <String, (double, int)>{};
    final mine = <(String, String, double, int)>[];
    for (final row in rows) {
      final s = row.readTable(_db.exerciseSets);
      final we = row.readTable(_db.workoutExercises);
      final kg = s.actualWeightKg ?? 0, reps = s.actualReps ?? 0;
      if (kg <= 0 || reps <= 0) continue;
      if (we.workoutId == workoutId) {
        mine.add((s.id, we.exerciseId, kg, reps));
      } else {
        final b = prior[we.exerciseId];
        if (b == null || kg > b.$1 || (kg == b.$1 && reps > b.$2)) {
          prior[we.exerciseId] = (kg, reps);
        }
      }
    }
    return {
      for (final (id, ex, kg, reps) in mine)
        if (prior[ex] case final b?)
          if (kg > b.$1 || (kg == b.$1 && reps > b.$2)) id,
    };
  }

  /// Every template with its exercises (in order) and when it was last used.
  Future<List<TemplateCard>> templateCards() async {
    final templates =
        await (_db.select(_db.workoutTemplates)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    final exRows =
        await (_db.select(_db.workoutTemplateExercises).join([
              innerJoin(
                _db.exercises,
                _db.exercises.id.equalsExp(
                  _db.workoutTemplateExercises.exerciseId,
                ),
              ),
            ])..orderBy([
              OrderingTerm.asc(_db.workoutTemplateExercises.sortOrder),
            ]))
            .get();
    final setRows = await (_db.select(
      _db.workoutTemplateSets,
    )..orderBy([(t) => OrderingTerm.asc(t.setNumber)])).get();
    final setsByExercise = <String, List<WorkoutTemplateSet>>{};
    for (final s in setRows) {
      (setsByExercise[s.templateExerciseId] ??= []).add(s);
    }
    final linesByTemplate = <String, List<TemplateExerciseLine>>{};
    for (final row in exRows) {
      final te = row.readTable(_db.workoutTemplateExercises);
      final ex = row.readTable(_db.exercises);
      final sets = setsByExercise[te.id] ?? const [];
      final first = sets.isEmpty ? null : sets.first;
      (linesByTemplate[te.templateId] ??= []).add((
        name: ex.name,
        sets: sets.length,
        reps: first?.reps,
        weightKg: first?.weightKg,
        durationMinutes: first?.durationMinutes,
        distanceMeters: first?.distanceMeters,
      ));
    }

    final last = <String, int>{};
    final used = await (_db.select(
      _db.workouts,
    )..where((t) => t.deletedAt.isNull() & t.templateId.isNotNull())).get();
    for (final w in used) {
      final id = w.templateId!;
      if ((last[id] ?? 0) < w.date) last[id] = w.date;
    }

    return [
      for (final t in templates)
        TemplateCard(
          id: t.id,
          name: t.name,
          createdAt: DateTime.fromMillisecondsSinceEpoch(t.createdAt),
          exercises: linesByTemplate[t.id] ?? const [],
          lastDone: last[t.id] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(last[t.id]!),
        ),
    ];
  }
}
