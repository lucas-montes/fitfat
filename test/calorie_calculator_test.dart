import 'package:fitfat/src/diet/services/activity_factor_source.dart';
import 'package:fitfat/src/diet/services/bmr_equation.dart';
import 'package:fitfat/src/diet/services/calorie_calculator.dart';
import 'package:fitfat/src/diet/services/calorie_inputs.dart';
import 'package:fitfat/src/models/activity_level.dart';
import 'package:fitfat/src/models/bmr_formula.dart';
import 'package:fitfat/src/models/body_weight_goal.dart';
import 'package:fitfat/src/models/diet_phase.dart';
import 'package:fitfat/src/models/gender.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wiring the app ships with: Mifflin-St Jeor and the average PAL multiplier.
const appCalculator = CalorieCalculator(
  bmrEquation: MifflinStJeorEquation(),
  activity: PalActivityFactor(),
);

const maintenance = (
  adjustment: 0.0,
  proteinPerKg: 2.0,
  fatPercent: 30.0,
  fiberTarget: 30.0,
);

const cutting = (
  adjustment: -500.0,
  proteinPerKg: 2.0,
  fatPercent: 30.0,
  fiberTarget: 30.0,
);

BodyProfile measured({double? weight = 80, double? height = 180}) =>
    (weightKg: weight, heightCm: height);

const nothingMeasured = (weightKg: null, heightCm: null);

CalorieInputs profile({
  int? age = 30,
  Gender? gender = Gender.male,
  double? bodyFatPercent,
  bool trackBodyFat = false,
  ActivityLevel? activityLevel = ActivityLevel.moderate,
}) => (
  age: age,
  gender: gender,
  bodyFatPercent: bodyFatPercent,
  trackBodyFat: trackBodyFat,
  activityLevel: activityLevel,
);

void main() {
  group('bmr', () {
    test('uses Mifflin-St Jeor by default', () {
      final result = appCalculator.bmr(
        profile: measured(),
        inputs: profile(),
      );
      expect(result.bmr, closeTo(1780, 1e-9));
      expect(result.formula, BmrFormula.mifflinStJeor);
    });

    test('uses Katch-McArdle when body fat is tracked and set', () {
      final result = appCalculator.bmr(
        profile: measured(),
        inputs: profile(bodyFatPercent: 20, trackBodyFat: true),
      );
      expect(result.bmr, closeTo(1752.4, 1e-9));
      expect(result.formula, BmrFormula.katchMcArdle);
    });

    test('stays on Mifflin when tracking is on but the percentage is unset', () {
      final result = appCalculator.bmr(
        profile: measured(),
        inputs: profile(bodyFatPercent: null, trackBodyFat: true),
      );
      expect(result.formula, BmrFormula.mifflinStJeor);
    });

    test('stays on Mifflin when a percentage is set but tracking is off', () {
      final result = appCalculator.bmr(
        profile: measured(),
        inputs: profile(bodyFatPercent: 20, trackBodyFat: false),
      );
      expect(result.formula, BmrFormula.mifflinStJeor);
    });
  });

  group('target', () {
    test('scales BMR by the average activity level', () async {
      final meta = await appCalculator.target(
        profile: measured(),
        inputs: profile(),
        phase: DietPhase.maintenance,
        config: maintenance,
      );
      // 1780 × 1.55
      expect(meta.bmr, closeTo(1780, 1e-9));
      expect(meta.tdee, closeTo(2759, 1e-9));
      expect(meta.target, closeTo(2759, 1e-9));
      expect(meta.phase, DietPhase.maintenance);
    });

    test('applies the phase adjustment on top of TDEE', () async {
      final meta = await appCalculator.target(
        profile: measured(),
        inputs: profile(),
        phase: DietPhase.cutting,
        config: cutting,
      );
      expect(meta.tdee, closeTo(2759, 1e-9));
      expect(meta.target, closeTo(2259, 1e-9));
    });

    test('a higher activity level raises the target', () async {
      Future<double> targetFor(ActivityLevel level) async =>
          (await appCalculator.target(
            profile: measured(),
            inputs: profile(activityLevel: level),
            phase: DietPhase.maintenance,
            config: maintenance,
          ))
          .target;

      expect(
        await targetFor(ActivityLevel.veryActive),
        greaterThan(await targetFor(ActivityLevel.sedentary)),
      );
    });

    test('is not estimated once every input is measured', () async {
      final meta = await appCalculator.target(
        profile: measured(),
        inputs: profile(),
        phase: DietPhase.maintenance,
        config: maintenance,
      );
      expect(meta.isEstimated, isFalse);
    });

    test('is estimated when any input is missing, using placeholders', () async {
      final meta = await appCalculator.target(
        profile: nothingMeasured,
        inputs: profile(age: null, gender: null, activityLevel: null),
        phase: DietPhase.maintenance,
        config: maintenance,
      );
      // The shared fallback body: 70 kg, 170 cm, 30y, male.
      final fallbackBmr = appCalculator.bmr(
        profile: nothingMeasured,
        inputs: profile(age: null, gender: null),
      );
      expect(meta.bmr, closeTo(fallbackBmr.bmr, 1e-9));
      // 700 + 1062.5 − 150 + 5, the shared fallback body.
      expect(meta.bmr, closeTo(1617.5, 1e-9));
      expect(meta.isEstimated, isTrue);
      expect(meta.target, closeTo(meta.bmr * ActivityLevel.moderate.multiplier, 1e-9));
    });

    test('the target does not depend on the equation once inputs are shared', () async {
      // Both equations see the same inputs; only the BMR they produce differs,
      // and the target follows BMR exactly.
      final viaMifflin = await appCalculator.target(
        profile: measured(),
        inputs: profile(),
        phase: DietPhase.maintenance,
        config: maintenance,
      );
      final viaKatch = await appCalculator.target(
        profile: measured(),
        inputs: profile(bodyFatPercent: 20, trackBodyFat: true),
        phase: DietPhase.maintenance,
        config: maintenance,
      );
      expect(
        viaKatch.target,
        closeTo(viaKatch.bmr * ActivityLevel.moderate.multiplier, 1e-9),
      );
      expect(viaKatch.formula, BmrFormula.katchMcArdle);
      expect(viaMifflin.formula, BmrFormula.mifflinStJeor);
    });

    test('swapping the activity source changes the target, nothing else', () async {
      // This is the seam the deferred exercise-based source will plug into.
      const measuredActivity = _FixedActivity(600);
      const calculator = CalorieCalculator(
        bmrEquation: MifflinStJeorEquation(),
        activity: measuredActivity,
      );

      final withMeasured = await calculator.target(
        profile: measured(),
        inputs: profile(),
        phase: DietPhase.maintenance,
        config: maintenance,
      );
      final withAverage = await appCalculator.target(
        profile: measured(),
        inputs: profile(),
        phase: DietPhase.maintenance,
        config: maintenance,
      );

      expect(withMeasured.bmr, withAverage.bmr);
      expect(withMeasured.formula, withAverage.formula);
      expect(withMeasured.tdee, closeTo(1780 + 600, 1e-9));
      expect(withAverage.tdee, closeTo(2759, 1e-9));
      // 600 kcal of measured burn is a smaller factor than a `moderate` PAL
      // assumes, so the target drops — which is the whole point of measuring.
      expect(withMeasured.target, lessThan(withAverage.target));
    });
  });

  group('macros', () {
    test('protein is bodyweight times g/kg, fat is a share of calories', () {
      final t = appCalculator.macros(
        targetKcal: 2000,
        config: maintenance,
        profile: (weightKg: 70, heightCm: 180),
      );
      expect(t.protein, closeTo(140, 1e-9));
      expect(t.fat, closeTo(2000 * 0.30 / 9, 1e-9));
      expect(t.fiber, closeTo(30, 1e-9));
    });

    test('carbs take the calories protein and fat leave behind', () {
      final t = appCalculator.macros(
        targetKcal: 2000,
        config: maintenance,
        profile: (weightKg: 70, heightCm: 180),
      );
      expect(t.carbs, closeTo((2000 - 140 * 4 - 2000 * 0.30) / 4, 1e-9));
    });

    test('the three macros reconstruct the calorie target', () {
      // The invariant behind "macros inconsistent with calories": whatever the
      // target, P/C/F must account for exactly it.
      for (final target in [1200.0, 2000.0, 2759.0, 4000.0]) {
        final t = appCalculator.macros(
          targetKcal: target,
          config: maintenance,
          profile: measured(),
        );
        expect(t.protein * 4 + t.carbs * 4 + t.fat * 9, closeTo(target, 1e-6));
      }
    });

    test('carbs clamp to zero rather than going negative', () {
      // 120 kg at 2.0 g/kg is 240 g of protein = 960 kcal, and 30% fat on a 1200
      // target is 360 kcal: together 1320, which overshoots.
      final t = appCalculator.macros(
        targetKcal: 1200,
        config: maintenance,
        profile: (weightKg: 120, heightCm: 180),
      );
      expect(t.carbs, 0);
      expect(
        appCalculator.macrosExceedTarget(
          targetKcal: 1200,
          proteinGrams: 240,
          fatPercent: 30,
        ),
        isTrue,
      );
    });

    test('macrosExceedTarget is false when carbs still have room', () {
      expect(
        appCalculator.macrosExceedTarget(
          targetKcal: 2000,
          proteinGrams: 140,
          fatPercent: 30,
        ),
        isFalse,
      );
    });

    test('a zero bodyweight yields zero protein, not a division error', () {
      final t = appCalculator.macros(
        targetKcal: 2000,
        config: maintenance,
        profile: (weightKg: 0, heightCm: 180),
      );
      expect(t.protein, 0);
      expect(t.carbs, closeTo((2000 - 0 - 600) / 4, 1e-9));
    });

    test('protein uses the measured weight, else the shared fallback', () {
      expect(
        appCalculator.proteinGrams(
          config: maintenance,
          profile: (weightKg: 80, heightCm: 180),
        ),
        closeTo(160, 1e-9),
      );
      expect(
        appCalculator.proteinGrams(config: maintenance, profile: nothingMeasured),
        closeTo(kFallbackWeightKg * 2.0, 1e-9),
      );
    });

    test('BMR and the macro targets assume the same body', () {
      // Both fall back to the same weight, so a user with nothing measured sees
      // targets derived from one body rather than two.
      final assumed = appCalculator.proteinGrams(
        config: maintenance,
        profile: nothingMeasured,
      );
      expect(assumed, closeTo(kFallbackWeightKg * kDefaultProteinPerKg, 1e-9));
    });
  });

  group('phase defaults', () {
    test('seed cutting and bulking at +/-500 and maintenance at 0', () {
      expect(kDefaultCuttingAdjustment, -500);
      expect(kDefaultBulkingAdjustment, 500);
      expect(kDefaultMaintenanceAdjustment, 0);
    });

    test('every seeded phase uses the same protein, fat and fiber', () {
      for (final phase in DietPhase.values) {
        final config = kDefaultPhaseConfigs[phase]!;
        expect(config.proteinPerKg, kDefaultProteinPerKg);
        expect(config.fatPercent, kDefaultFatPercent);
        expect(config.fiberTarget, kDefaultFiberTarget);
      }
    });

    test('phase maps to and from the stored body-weight goal', () {
      expect(DietPhase.fromGoal(BodyWeightGoal.lose), DietPhase.cutting);
      expect(DietPhase.fromGoal(BodyWeightGoal.gain), DietPhase.bulking);
      expect(
        DietPhase.fromGoal(BodyWeightGoal.maintain),
        DietPhase.maintenance,
      );
      // Unset means maintenance, the phase that changes nothing.
      expect(DietPhase.fromGoal(null), DietPhase.maintenance);
      expect(DietPhase.cutting.goal, BodyWeightGoal.lose);
      expect(DietPhase.bulking.goal, BodyWeightGoal.gain);
      expect(DietPhase.maintenance.goal, BodyWeightGoal.maintain);
    });

    test('copyWith changes one knob and leaves the rest', () {
      final updated = maintenance.copyWith(fatPercent: 25);
      expect(updated.fatPercent, 25);
      expect(updated.adjustment, 0);
      expect(updated.proteinPerKg, 2);
      expect(updated.fiberTarget, 30);
    });
  });
}

/// A stand-in for a measured activity source, used to prove the seam swaps.
///
/// Expresses a day's burn the way the deferred real source will: extra kcal
/// turned into a multiplier against the BMR it was measured for.
final class _FixedActivity implements ActivityFactorSource {
  final double kcal;
  const _FixedActivity(this.kcal);

  @override
  Future<double> factorFor({
    required CalorieInputs inputs,
    required double bmr,
  }) async =>
      1 + kcal / bmr;
}