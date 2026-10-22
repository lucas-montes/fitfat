import 'dart:math' as math;

import '../../models/bmr_formula.dart';
import '../../models/diet_phase.dart';
import 'activity_factor_source.dart';
import 'bmr_equation.dart';
import 'calorie_inputs.dart';

/// Energy density of each macronutrient (kcal per gram).
const double kKcalPerGramProtein = 4;
const double kKcalPerGramCarbs = 4;
const double kKcalPerGramFat = 9;

/// Every figure the dashboard shows about calories, derived in one pass.
///
/// BMR comes from whichever [BmrEquation] applies, TDEE adds the activity term
/// from an [ActivityFactorSource], and the daily target is TDEE plus the active
/// phase's signed adjustment. The calculator owns that derivation and nothing
/// else: where the inputs came from, and how they are stored, are the callers'
/// problem.
///
/// Two collaborators, both swappable. [bmrEquation] is the single equation the
/// caller committed to; [activity] decides whether the activity term is an
/// average PAL multiplier or a measured burn, and the calculator does not care
/// which — adding a measured source later is a wiring change, not a code change.
final class CalorieCalculator {
  final BmrEquation bmrEquation;
  final ActivityFactorSource activity;

  const CalorieCalculator({required this.bmrEquation, required this.activity});

  /// ① Basal metabolic rate, with the equation that produced it.
  ///
  /// Katch-McArdle is preferred when body fat is being tracked and a percentage
  /// is set, because lean mass predicts resting burn better than weight does.
  /// Otherwise the configured [bmrEquation] runs — which the wiring sets to
  /// Mifflin-St Jeor, so [isEstimated] still tells the UI when the inputs were
  /// placeholders.
  ({double bmr, BmrFormula formula}) bmr({
    required BodyProfile profile,
    required CalorieInputs inputs,
  }) {
    final equation = inputs.trackBodyFat && inputs.bodyFatPercent != null
        ? const KatchMcArdleEquation()
        : bmrEquation;
    final bmr = equation.calculate(
      gender: inputs.gender ?? kFallbackGender,
      weightKg: profile.weightKg ?? kFallbackWeightKg,
      heightCm: profile.heightCm ?? kFallbackHeightCm,
      age: inputs.age ?? kFallbackAge,
      bodyFatPercent: inputs.bodyFatPercent,
    );
    return (bmr: bmr, formula: equation.formula);
  }

  /// ②③ The daily target: TDEE plus the phase's signed adjustment.
  ///
  /// Carries BMR and TDEE alongside the target so a consumer — the dashboard —
  /// can read every figure it displays from one result rather than three.
  Future<CalorieTargetMeta> target({
    required BodyProfile profile,
    required CalorieInputs inputs,
    required DietPhase phase,
    required PhaseConfig config,
  }) async {
    final basal = bmr(profile: profile, inputs: inputs);
    final tdee =
        basal.bmr * await activity.factorFor(inputs: inputs, bmr: basal.bmr);
    return (
      bmr: basal.bmr,
      tdee: tdee,
      target: tdee + config.adjustment,
      formula: basal.formula,
      phase: phase,
      isEstimated: isEstimated(profile: profile, inputs: inputs),
    );
  }

  /// True when any input behind [bmr] was a placeholder rather than a
  /// measurement, which the UI surfaces next to the numbers themselves.
  bool isEstimated({
    required BodyProfile profile,
    required CalorieInputs inputs,
  }) =>
      profile.weightKg == null ||
      profile.heightCm == null ||
      inputs.age == null ||
      inputs.gender == null;

  /// Protein, carb, fat and fiber gram targets for one phase.
  ///
  /// Protein is set per kg of body weight and fat as a share of the calorie
  /// target; carbs take whatever calories are left, because they are the one
  /// macronutrient a person can vary without a fixed physiological requirement.
  MacroTargets macros({
    required double targetKcal,
    required PhaseConfig config,
    required BodyProfile profile,
  }) {
    final protein = proteinGrams(config: config, profile: profile);
    final proteinKcal = protein * kKcalPerGramProtein;
    final fatKcal = targetKcal * config.fatPercent / 100;
    // Clamped, not allowed to go negative: if protein and fat already exceed the
    // target there are no calories left for carbs, and a negative carb target
    // would render as a nonsensical progress bar rather than an error.
    final carbsKcal = math.max(0.0, targetKcal - proteinKcal - fatKcal);
    return (
      protein: protein,
      carbs: carbsKcal / kKcalPerGramCarbs,
      fat: fatKcal / kKcalPerGramFat,
      fiber: config.fiberTarget,
    );
  }

  /// The phase's protein target in grams, from the measured weight or the
  /// shared fallback — the same body BMR assumed, so the two never disagree.
  double proteinGrams({
    required PhaseConfig config,
    required BodyProfile profile,
  }) =>
      config.proteinPerKg * (profile.weightKg ?? kFallbackWeightKg);

  /// True when protein and fat alone exceed [targetKcal], leaving carbs at
  /// zero. The configuration is usable, but the user probably did not intend
  /// it, so the settings screen surfaces this as a warning.
  bool macrosExceedTarget({
    required double targetKcal,
    required double proteinGrams,
    required double fatPercent,
  }) =>
      proteinGrams * kKcalPerGramProtein + targetKcal * fatPercent / 100 >
      targetKcal;
}

/// Protein, carb, fat and fiber gram targets, in that order of derivation.
typedef MacroTargets = ({
  double protein,
  double carbs,
  double fat,
  double fiber,
});

/// Every calorie figure the dashboard displays, derived together.
typedef CalorieTargetMeta = ({
  double bmr,
  double tdee,
  double target,
  BmrFormula formula,
  DietPhase phase,
  bool isEstimated,
});