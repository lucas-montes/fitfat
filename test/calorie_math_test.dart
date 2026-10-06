import 'package:fitfat/src/diet/providers/calories.dart';
import 'package:fitfat/src/models/activity_level.dart';
import 'package:fitfat/src/models/bmr_formula.dart';
import 'package:fitfat/src/models/body_weight_goal.dart';
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

  group('adjustForGoal', () {
    // Still exercised here even though Stage B replaces it, so the refactor is
    // pinned against the behaviour it preserved.
    test('subtracts for lose, adds for gain, and is flat for maintain', () {
      const tdee = 2400.0;
      expect(
        adjustForGoal(tdee, BodyWeightGoal.lose, adjustment: 500),
        closeTo(1900, 1e-9),
      );
      expect(
        adjustForGoal(tdee, BodyWeightGoal.gain, adjustment: 500),
        closeTo(2900, 1e-9),
      );
      expect(
        adjustForGoal(tdee, BodyWeightGoal.maintain, adjustment: 500),
        closeTo(2400, 1e-9),
      );
    });
  });

  group('macroTargetsFor', () {
    // Pinned until Stage B makes this bodyweight- and percentage-driven.
    test('is a 30/40/30 split by calories', () {
      final t = macroTargetsFor(2000);
      expect(t.protein, closeTo(2000 * 0.30 / 4, 1e-9));
      expect(t.carbs, closeTo(2000 * 0.40 / 4, 1e-9));
      expect(t.fat, closeTo(2000 * 0.30 / 9, 1e-9));
    });
  });
}
