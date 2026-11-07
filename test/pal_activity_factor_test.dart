import 'package:fitfat/src/diet/services/activity_factor_source.dart';
import 'package:fitfat/src/diet/services/calorie_inputs.dart';
import 'package:fitfat/src/models/activity_level.dart';
import 'package:fitfat/src/models/gender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pal = PalActivityFactor();

  CalorieInputs inputsWith(ActivityLevel? level) => (
    age: 30,
    gender: Gender.male,
    bodyFatPercent: null,
    trackBodyFat: false,
    activityLevel: level,
  );

  group('PalActivityFactor', () {
    test('returns the level multiplier', () async {
      for (final level in ActivityLevel.values) {
        expect(
          await pal.factorFor(inputs: inputsWith(level), bmr: 1780),
          level.multiplier,
        );
      }
    });

    test('falls back to moderate when no level is set', () async {
      expect(
        await pal.factorFor(inputs: inputsWith(null), bmr: 1780),
        ActivityLevel.moderate.multiplier,
      );
    });

    test('ignores BMR, since a PAL multiplier does not depend on it', () async {
      expect(
        await pal.factorFor(inputs: inputsWith(ActivityLevel.active), bmr: 1),
        ActivityLevel.active.multiplier,
      );
      expect(
        await pal.factorFor(
          inputs: inputsWith(ActivityLevel.active),
          bmr: 9999,
        ),
        ActivityLevel.active.multiplier,
      );
    });

    test('sedentary is the lowest and veryActive the highest multiplier', () {
      expect(ActivityLevel.sedentary.multiplier, 1.2);
      expect(ActivityLevel.veryActive.multiplier, 1.9);
      for (final level in ActivityLevel.values) {
        expect(level.multiplier, greaterThanOrEqualTo(1.2));
        expect(level.multiplier, lessThanOrEqualTo(1.9));
      }
    });
  });
}