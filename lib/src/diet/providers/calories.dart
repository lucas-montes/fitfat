import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../body/providers/body_metrics.dart';
import '../../exercise/providers/exercises.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/activity_level.dart';
import '../../models/body_weight_goal.dart';
import '../../models/gender.dart';
import '../../settings/providers/settings.dart';
import 'health_connect_steps.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// MET values used for computed activity (kcal = MET × weight_kg × hours).
const double kWeightliftingMet = 6.0;
const double kCardioMet = 10.0;

/// kcal burned per step per kg of body weight (validated walking estimate,
/// ~0.04 kcal per step for a 100 kg person).
const double kKcalPerStepPerKg = 0.0004;

/// kcal adjustment applied on top of TDEE for the body-weight goal
/// (default; user-configurable via `settings.calorieGoalAdjustment`).
const double kGoalAdjustment = 500;

// ---------------------------------------------------------------------------
// Pure formula helpers (unit-testable, no I/O)
// ---------------------------------------------------------------------------

/// Mifflin-St Jeor basal metabolic rate (kcal/day).
double mifflinBmr({
  required Gender gender,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return gender == Gender.male ? base + 5 : base - 161;
}

/// Katch-McArdle basal metabolic rate from lean body mass (kcal/day).
/// [bodyFatPercent] is 0–70 (e.g. 20 = 20%).
double katchMcardleBmr({
  required double weightKg,
  required double bodyFatPercent,
}) {
  final leanMass = weightKg * (1 - bodyFatPercent / 100);
  return 370 + 21.6 * leanMass;
}

/// kcal for a session of [minutes] at the given MET, for a person of
/// [weightKg]. kcal = MET × kg × hours.
double workoutKcal({
  required double met,
  required double weightKg,
  required int minutes,
}) => met * weightKg * (minutes / 60);

/// kcal burned walking [steps] for a person of [weightKg].
double stepsKcal({required double weightKg, required int steps}) =>
    steps * kKcalPerStepPerKg * weightKg;

/// Applies the body-weight-goal adjustment on top of TDEE.
/// lose → −[adjustment], gain → +[adjustment], maintain/unset → 0.
double adjustForGoal(
  double tdee,
  BodyWeightGoal? goal, {
  double adjustment = kGoalAdjustment,
}) => switch (goal) {
  BodyWeightGoal.lose => tdee - adjustment,
  BodyWeightGoal.gain => tdee + adjustment,
  BodyWeightGoal.maintain || null => tdee,
};

/// P/C/F gram targets from a daily calorie target (30/40/30 split).
typedef MacroTargets = ({double protein, double carbs, double fat});

MacroTargets macroTargetsFor(double kcal) =>
    (protein: kcal * 0.30 / 4, carbs: kcal * 0.40 / 4, fat: kcal * 0.30 / 9);

// ---------------------------------------------------------------------------
// Steps provider
// ---------------------------------------------------------------------------

/// Today's step count. Android reads it from Health Connect (T04); other
/// platforms fall back to 0 (workouts-only activity).
final stepsProvider = FutureProvider<int>((ref) async {
  return ref.watch(todayStepsProvider.future);
});

// ---------------------------------------------------------------------------
// Daily activity kcal (computed mode)
// ---------------------------------------------------------------------------

/// Today's activity kcal from workouts (MET × kg × hours) + daily steps.
final dailyActivityKcalProvider = FutureProvider<double>((ref) async {
  final latest = await ref.watch(latestBodyMetricsProvider.future);
  final weight = latest?.weightKg ?? 0;
  final workoutKcal = await _todayWorkoutKcal(ref, weight);
  final steps = await ref.watch(stepsProvider.future);
  return workoutKcal + stepsKcal(weightKg: weight, steps: steps);
});

Future<double> _todayWorkoutKcal(Ref ref, double weight) async {
  if (weight <= 0) return 0;
  final workouts = await ref.watch(workoutListProvider.future);
  final exercises = await ref.watch(exerciseListProvider.future);
  final typeById = {for (final e in exercises) e.id: e.exerciseType};

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  var total = 0.0;
  for (final workout in workouts) {
    if (!workout.isCompleted) continue;
    final completed = workout.completedAt!;
    final day = DateTime(completed.year, completed.month, completed.day);
    if (day.isBefore(todayStart) || !day.isBefore(todayEnd)) continue;

    final detail = await ref.watch(workoutDetailProvider(workout.id).future);
    if (detail == null) continue;
    for (final block in detail.exercises) {
      final type = typeById[block.exercise.exerciseId];
      final met = type == 'cardio' ? kCardioMet : kWeightliftingMet;
      total += workoutKcal(
        met: met,
        weightKg: weight,
        minutes: workout.duration.inMinutes,
      );
    }
  }
  return total;
}

// ---------------------------------------------------------------------------
// Calorie target
// ---------------------------------------------------------------------------

/// The daily calorie target (kcal/day), or `null` when inputs are incomplete
/// (missing age / gender / latest weight / height).
final calorieTargetProvider = FutureProvider<double?>((ref) async {
  final settings = ref.watch(settingsProvider);
  final latest = await ref.watch(latestBodyMetricsProvider.future);
  final weight = latest?.weightKg;
  final height = latest?.heightCm;
  final age = settings.age;
  final gender = settings.gender;
  if (weight == null || height == null || age == null || gender == null) {
    return null;
  }

  final double bmr;
  if (settings.trackBodyFat && settings.bodyFatPercent != null) {
    bmr = katchMcardleBmr(
      weightKg: weight,
      bodyFatPercent: settings.bodyFatPercent!,
    );
  } else {
    bmr = mifflinBmr(
      gender: gender,
      weightKg: weight,
      heightCm: height,
      age: age,
    );
  }

  final double tdee;
  if (settings.computeActivity) {
    final activity = await ref.watch(dailyActivityKcalProvider.future);
    tdee = bmr + activity;
  } else {
    final level = settings.activityLevel ?? ActivityLevel.moderate;
    tdee = bmr * level.multiplier;
  }

  return adjustForGoal(
    tdee,
    settings.bodyWeightGoal,
    adjustment: settings.calorieGoalAdjustment,
  );
});

/// P/C/F gram targets derived from the daily calorie target, or `null` when
/// the target cannot be computed.
final macroTargetsProvider = FutureProvider<MacroTargets?>((ref) async {
  final target = await ref.watch(calorieTargetProvider.future);
  if (target == null) return null;
  return macroTargetsFor(target);
});
