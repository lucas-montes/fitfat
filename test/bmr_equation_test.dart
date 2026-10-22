import 'package:fitfat/src/diet/services/bmr_equation.dart';
import 'package:fitfat/src/models/bmr_formula.dart';
import 'package:fitfat/src/models/gender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mifflin = MifflinStJeorEquation();
  const katch = KatchMcArdleEquation();

  group('MifflinStJeorEquation', () {
    test('10w + 6.25h − 5a, +5 male and −161 female', () {
      double bmr({
        required Gender gender,
        double weight = 80,
        double height = 180,
        int age = 30,
      }) => mifflin.calculate(
        gender: gender,
        weightKg: weight,
        heightCm: height,
        age: age,
        bodyFatPercent: null,
      );

      // 800 + 1125 − 150 + 5
      expect(bmr(gender: Gender.male), closeTo(1780, 1e-9));
      // 800 + 1125 − 150 − 161
      expect(bmr(gender: Gender.female), closeTo(1614, 1e-9));
    });

    test('falls with age and rises with height and weight', () {
      double bmr({
        double weight = 80,
        double height = 180,
        int age = 30,
      }) => mifflin.calculate(
        gender: Gender.male,
        weightKg: weight,
        heightCm: height,
        age: age,
        bodyFatPercent: null,
      );

      expect(bmr(weight: 90), greaterThan(bmr()));
      expect(bmr(height: 190), greaterThan(bmr()));
      expect(bmr(age: 40), lessThan(bmr()));
    });

    test('reports the equation it implements', () {
      expect(mifflin.formula, BmrFormula.mifflinStJeor);
    });

    test('ignores body fat, which the equation does not use', () {
      final without = mifflin.calculate(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: null,
      );
      final with_ = mifflin.calculate(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: 25,
      );
      expect(with_, without);
    });
  });

  group('KatchMcArdleEquation', () {
    test('370 + 21.6 × lean mass', () {
      // 80 kg at 20% body fat → 64 kg lean → 370 + 1382.4
      expect(
        katch.calculate(
          gender: Gender.male,
          weightKg: 80,
          heightCm: 180,
          age: 30,
          bodyFatPercent: 20,
        ),
        closeTo(1752.4, 1e-9),
      );
    });

    test('falls as body fat rises, at a fixed weight', () {
      double at(double bodyFat) => katch.calculate(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: bodyFat,
      );
      expect(at(30), lessThan(at(20)));
      expect(at(10), greaterThan(at(20)));
    });

    test('ignores height, age and sex, which the equation does not use', () {
      final base = katch.calculate(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        bodyFatPercent: 20,
      );
      expect(
        katch.calculate(
          gender: Gender.female,
          weightKg: 80,
          heightCm: 150,
          age: 70,
          bodyFatPercent: 20,
        ),
        base,
      );
    });

    test('reports the equation it implements', () {
      expect(katch.formula, BmrFormula.katchMcArdle);
    });
  });
}