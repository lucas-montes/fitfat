import 'package:fitfat/src/diet/providers/calories.dart';
import 'package:fitfat/src/models/activity_level.dart';
import 'package:fitfat/src/models/bmr_formula.dart';
import 'package:fitfat/src/models/body_weight_goal.dart';
import 'package:fitfat/src/models/diet_phase.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/models/gender.dart';
import 'package:flutter_test/flutter_test.dart';

/// The first coverage for this file. The helpers here are pure and were
/// previously untested, which is why the BMR/TDEE split was done before any
/// behaviour change: a regression in the refactor has to be attributable to the
/// refactor.
void main() {
  group('mifflinBmr', () {
    test('10w + 6.25h − 5a, +5 male and −161 female', () {
      expect(
        mifflinBmr(gender: Gender.male, weightKg: 80, heightCm: 180, age: 30),
        closeTo(1780, 1e-9),
      );
      expect(
        mifflinBmr(gender: Gender.female, weightKg: 80, heightCm: 180, age: 30),
        closeTo(1614, 1e-9),
      );
    });

    test('falls with age and rises with height and weight', () {
      double bmr({double w = 80, double h = 180, int age = 30}) =>
          mifflinBmr(gender: Gender.male, weightKg: w, heightCm: h, age: age);
      expect(bmr(age: 50), lessThan(bmr(age: 30)));
      expect(bmr(h: 190), greaterThan(bmr(h: 180)));
      expect(bmr(w: 90), greaterThan(bmr(w: 80)));
    });
  });

  group('katchMcardleBmr', () {
    test('370 + 21.6 × lean mass', () {
      // 80 kg at 20 % body fat is 64 kg lean: 370 + 21.6 × 64.
      expect(
        katchMcardleBmr(weightKg: 80, bodyFatPercent: 20),
        closeTo(1752.4, 1e-9),
      );
    });

    test('falls as body fat rises, at a fixed weight', () {
      expect(
        katchMcardleBmr(weightKg: 80, bodyFatPercent: 30),
        lessThan(katchMcardleBmr(weightKg: 80, bodyFatPercent: 15)),
      );
    });
  });

  group('bmrFor', () {
    test('uses Mifflin-St Jeor by default', () {
      final r = bmrFor(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: null,
        trackBodyFat: false,
      );
      expect(r.formula, BmrFormula.mifflinStJeor);
      expect(r.bmr, closeTo(1780, 1e-9));
    });

    test('uses Katch-McArdle when body fat is tracked and set', () {
      final r = bmrFor(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: 20,
        trackBodyFat: true,
      );
      expect(r.formula, BmrFormula.katchMcArdle);
      expect(r.bmr, closeTo(1752.4, 1e-9));
    });

    test('stays on Mifflin when tracking is on but the percentage is unset', () {
      // The flag alone must not switch equations: without a percentage there is
      // no lean mass to work from.
      final r = bmrFor(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: null,
        trackBodyFat: true,
      );
      expect(r.formula, BmrFormula.mifflinStJeor);
    });

    test('stays on Mifflin when a percentage is set but tracking is off', () {
      final r = bmrFor(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: 20,
        trackBodyFat: false,
      );
      expect(r.formula, BmrFormula.mifflinStJeor);
    });
  });

  group('tdeeFrom', () {
    test('computed mode adds measured activity to BMR', () {
      expect(
        tdeeFrom(bmr: 1780, level: null, activityKcal: 420),
        closeTo(2200, 1e-9),
      );
    });

    test('static mode multiplies BMR by the PAL factor', () {
      expect(
        tdeeFrom(bmr: 1800, level: ActivityLevel.moderate, activityKcal: 0),
        closeTo(2790, 1e-9), // 1800 × 1.55
      );
    });

    test('ignores the argument belonging to the other mode', () {
      final computed = tdeeFrom(bmr: 1800, level: null, activityKcal: 400);
      expect(computed, closeTo(2200, 1e-9));

      // Passing a level alongside activity must not double-count them.
      final staticMode = tdeeFrom(
        bmr: 1800,
        level: ActivityLevel.moderate,
        activityKcal: 400,
      );
      expect(staticMode, closeTo(2790, 1e-9));
    });

    test('sedentary is the lowest and veryActive the highest multiplier', () {
      double tdee(ActivityLevel l) =>
          tdeeFrom(bmr: 1800, level: l, activityKcal: 0);
      expect(
        tdee(ActivityLevel.sedentary),
        lessThan(tdee(ActivityLevel.light)),
      );
      expect(tdee(ActivityLevel.light), lessThan(tdee(ActivityLevel.moderate)));
      expect(
        tdee(ActivityLevel.moderate),
        lessThan(tdee(ActivityLevel.active)),
      );
      expect(
        tdee(ActivityLevel.active),
        lessThan(tdee(ActivityLevel.veryActive)),
      );
    });
  });

  group('applyPhaseAdjustment', () {
    test('adds the signed adjustment to TDEE', () {
      const tdee = 2400.0;
      expect(applyPhaseAdjustment(tdee, -500), closeTo(1900, 1e-9));
      expect(applyPhaseAdjustment(tdee, 500), closeTo(2900, 1e-9));
      expect(applyPhaseAdjustment(tdee, 0), closeTo(2400, 1e-9));
    });
  });

  group('macroTargetsFor', () {
    const config = (
      adjustment: -500.0,
      proteinPerKg: 2.0,
      fatPercent: 30.0,
      fiberTarget: 30.0,
    );

    test('protein is bodyweight times g/kg, fat is a share of calories', () {
      final t = macroTargetsFor(
        targetKcal: 2000,
        config: config,
        bodyweightKg: 70,
      );
      expect(t.protein, closeTo(140, 1e-9));
      expect(t.fat, closeTo(2000 * 0.30 / 9, 1e-9));
      expect(t.fiber, closeTo(30, 1e-9));
    });

    test('carbs take the calories protein and fat leave behind', () {
      final t = macroTargetsFor(
        targetKcal: 2000,
        config: config,
        bodyweightKg: 70,
      );
      final expectedCarbs = (2000 - 140 * 4 - 2000 * 0.30) / 4;
      expect(t.carbs, closeTo(expectedCarbs, 1e-9));
    });

    test('carbs clamp to zero rather than going negative', () {
      // 120 kg at 2.0 g/kg is 240 g of protein = 960 kcal, and 30% fat on a 1200
      // target is 360 kcal: together 1320, which overshoots.
      final t = macroTargetsFor(
        targetKcal: 1200,
        config: config,
        bodyweightKg: 120,
      );
      expect(t.carbs, 0);
      expect(
        macrosExceedTarget(
          targetKcal: 1200,
          proteinGrams: 240,
          fatPercent: 30,
        ),
        isTrue,
      );
    });

    test('macrosExceedTarget is false when carbs still have room', () {
      expect(
        macrosExceedTarget(
          targetKcal: 2000,
          proteinGrams: 140,
          fatPercent: 30,
        ),
        isFalse,
      );
    });

    test('a zero bodyweight yields zero protein, not a division error', () {
      final t = macroTargetsFor(
        targetKcal: 2000,
        config: config,
        bodyweightKg: 0,
      );
      expect(t.protein, 0);
      expect(t.carbs, closeTo((2000 - 0 - 600) / 4, 1e-9));
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
      const config = (
        adjustment: -500.0,
        proteinPerKg: 2.0,
        fatPercent: 30.0,
        fiberTarget: 30.0,
      );
      final updated = config.copyWith(fatPercent: 25);
      expect(updated.fatPercent, 25);
      expect(updated.adjustment, -500);
      expect(updated.proteinPerKg, 2);
      expect(updated.fiberTarget, 30);
    });
  });
}
