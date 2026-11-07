import '../../models/bmr_formula.dart';
import '../../models/gender.dart';

/// One basal-metabolic-rate equation, as a swappable strategy.
///
/// An equation is a formula and nothing else: it takes the inputs it needs and
/// returns kcal/day. Which equation applies to a given user — and what to do
/// when an input is missing — is the calculator's policy, not the equation's,
/// so this interface stays synchronous and free of defaults.
abstract class BmrEquation {
  /// Which equation this is, so the UI can label a non-default result.
  BmrFormula get formula;

  /// Basal metabolic rate in kcal/day.
  ///
  /// [bodyFatPercent] is 0–70 (e.g. 20 = 20%) and is ignored by equations that
  /// do not need it. [age] is ignored by equations based on lean mass.
  double calculate({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required double? bodyFatPercent,
  });
}

/// Mifflin-St Jeor: 10w + 6.25h − 5a, +5 for men and −161 for women.
///
/// The default, because it needs only height, age, weight and sex — the inputs
/// almost every user has already entered for other reasons.
final class MifflinStJeorEquation implements BmrEquation {
  const MifflinStJeorEquation();

  @override
  BmrFormula get formula => BmrFormula.mifflinStJeor;

  @override
  double calculate({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required double? bodyFatPercent,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == Gender.male ? base + 5 : base - 161;
  }
}

/// Katch-McArdle: 370 + 21.6 × lean body mass (kcal/day).
///
/// Preferred when body fat is tracked, because lean mass predicts resting burn
/// better than weight does — it excludes the tissue that does not burn much.
final class KatchMcArdleEquation implements BmrEquation {
  const KatchMcArdleEquation();

  @override
  BmrFormula get formula => BmrFormula.katchMcArdle;

  @override
  double calculate({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required double? bodyFatPercent,
  }) {
    final leanMass = weightKg * (1 - (bodyFatPercent ?? 0) / 100);
    return 370 + 21.6 * leanMass;
  }
}