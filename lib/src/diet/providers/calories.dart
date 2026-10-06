import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../body/providers/body_metrics.dart';
import '../../exercise/providers/exercises.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/activity_level.dart';
import '../../models/bmr_formula.dart';
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

/// ① Basal metabolic rate, from whichever equation applies.
///
/// Katch-McArdle is preferred when body fat is being tracked and a percentage is
/// set, because lean mass predicts resting burn better than weight does. Without
/// it, Mifflin-St Jeor is used and [BmrFormula] says so, so the UI can stay quiet
/// about the common case and speak up when the rarer one produced the number.
///
/// Returns the formula alongside the value so callers never have to re-derive
/// which path ran.
({double bmr, BmrFormula formula}) bmrFor({
  required Gender gender,
  required double weightKg,
  required double heightCm,
  required int age,
  required double? bodyFatPercent,
  required bool trackBodyFat,
}) {
  if (trackBodyFat && bodyFatPercent != null) {
    return (
      bmr: katchMcardleBmr(weightKg: weightKg, bodyFatPercent: bodyFatPercent),
      formula: BmrFormula.katchMcArdle,
    );
  }
  return (
    bmr: mifflinBmr(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    ),
    formula: BmrFormula.mifflinStJeor,
  );
}

/// ② Total daily energy expenditure: BMR plus activity.
///
/// Two modes, and they are genuinely different models rather than two ways of
/// expressing one:
///
/// - **Computed** ([level] null): activity is measured, from workouts and steps,
///   and added to BMR. This is the more accurate mode and costs a query.
/// - **Static**: activity is a self-reported PAL multiplier on BMR, for when
///   nothing is being measured.
///
/// [activityKcal] is ignored in static mode, and [level] is ignored in computed
/// mode, so callers can pass both without branching.
double tdeeFrom({
  required double bmr,
  required ActivityLevel? level,
  required double activityKcal,
}) => level == null ? bmr + activityKcal : bmr * level.multiplier;

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

const double _fallbackWeightKg = 70;
const double _fallbackHeightCm = 170;
const int _fallbackAge = 30;
const Gender _fallbackGender = Gender.male;

/// ① BMR and which equation produced it.
///
/// Split out from the target so the derivation reads end to end and each step is
/// independently testable. The inputs are unchanged; only the shape differs.
final bmrMetaProvider =
    FutureProvider<({double bmr, BmrFormula formula, bool isEstimated})>((
      ref,
    ) async {
      final settings = ref.watch(settingsProvider);
      final latest = await ref.watch(latestBodyMetricsProvider.future);
      final weight = latest?.weightKg;
      final height = latest?.heightCm;
      final age = settings.age;
      final gender = settings.gender;
      final isEstimated =
          weight == null || height == null || age == null || gender == null;

      final result = bmrFor(
        gender: gender ?? _fallbackGender,
        weightKg: weight ?? _fallbackWeightKg,
        heightCm: height ?? _fallbackHeightCm,
        age: age ?? _fallbackAge,
        bodyFatPercent: settings.bodyFatPercent,
        trackBodyFat: settings.trackBodyFat,
      );
      return (
        bmr: result.bmr,
        formula: result.formula,
        isEstimated: isEstimated,
      );
    });

/// ② TDEE: BMR plus activity, measured or self-reported.
final tdeeProvider = FutureProvider<double>((ref) async {
  final settings = ref.watch(settingsProvider);
  final bmr = (await ref.watch(bmrMetaProvider.future)).bmr;
  // Computed mode measures activity, static mode applies a PAL multiplier. Only
  // one of the two ever runs, so the unused one costs nothing.
  if (settings.computeActivity) {
    final activity = await ref.watch(dailyActivityKcalProvider.future);
    return tdeeFrom(bmr: bmr, level: null, activityKcal: activity);
  }
  return tdeeFrom(
    bmr: bmr,
    level: settings.activityLevel ?? ActivityLevel.moderate,
    activityKcal: 0,
  );
});

typedef CalorieTargetMeta = ({
  double bmr,
  double tdee,
  double target,
  BmrFormula formula,
  bool isEstimated,
});

/// ③ The daily target: TDEE adjusted for the user's body-weight goal.
///
/// Carries BMR and TDEE alongside the target so a consumer — the dashboard — can
/// read every figure it displays from one provider rather than three.
final calorieTargetMetaProvider = FutureProvider<CalorieTargetMeta>((
  ref,
) async {
  final settings = ref.watch(settingsProvider);
  final bmrMeta = await ref.watch(bmrMetaProvider.future);
  final tdee = await ref.watch(tdeeProvider.future);
  final target = adjustForGoal(
    tdee,
    settings.bodyWeightGoal,
    adjustment: settings.calorieGoalAdjustment,
  );
  return (
    bmr: bmrMeta.bmr,
    tdee: tdee,
    target: target,
    formula: bmrMeta.formula,
    isEstimated: bmrMeta.isEstimated,
  );
});

final calorieTargetProvider = FutureProvider<double>((ref) async {
  final meta = await ref.watch(calorieTargetMetaProvider.future);
  return meta.target;
});

final macroTargetsProvider = FutureProvider<MacroTargets>((ref) async {
  final target = await ref.watch(calorieTargetProvider.future);
  return macroTargetsFor(target);
});
