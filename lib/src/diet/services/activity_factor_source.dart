import '../../models/activity_level.dart';
import 'calorie_inputs.dart';

/// Supplies the activity factor that turns BMR into TDEE.
///
/// Expressed as a **multiplier** rather than a number of kcal, so every source
/// composes the same way — TDEE is BMR × factor, and the calculator never
/// branches on which source it was handed. Two shapes exist:
///
/// - **Average** ([PalActivityFactor]): a self-reported PAL multiplier for the
///   whole day, straight off [ActivityLevel].
/// - **Measured** (workouts and steps, deferred): a factor derived from the
///   day's real burn, which needs [bmr] to express extra kcal as a multiplier
///   (`1 + activityKcal / bmr`).
///
/// [bmr] is passed so the measured shape can be added without changing this
/// signature. The method is asynchronous because that shape has to read
/// workouts and steps; [PalActivityFactor] returns a completed future.
abstract class ActivityFactorSource {
  /// The activity multiplier for [inputs], applied to BMR to yield TDEE.
  Future<double> factorFor({
    required CalorieInputs inputs,
    required double bmr,
  });
}

/// The average case: the self-reported activity level's PAL multiplier.
///
/// The multipliers live on [ActivityLevel] rather than here, so the enum stays
/// the single, documented home for those numbers; this only decides which one
/// applies. An unset level falls back to `moderate`, the midpoint — an unset
/// preference should not read as sedentary.
final class PalActivityFactor implements ActivityFactorSource {
  const PalActivityFactor();

  @override
  Future<double> factorFor({
    required CalorieInputs inputs,
    required double bmr,
  }) async =>
      (inputs.activityLevel ?? ActivityLevel.moderate).multiplier;
}