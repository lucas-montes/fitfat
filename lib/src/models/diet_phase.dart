import 'body_weight_goal.dart';

/// One of the three diet phases the user configures independently.
///
/// Deliberately 1:1 with [BodyWeightGoal] rather than a parallel concept: the
/// body-weight goal already stored in settings doubles as the active phase, so
/// selecting a phase needs no new pref and the weight-trend card keeps working
/// unchanged.
enum DietPhase {
  cutting,
  bulking,
  maintenance;

  /// The stored goal this phase corresponds to.
  BodyWeightGoal get goal => switch (this) {
    DietPhase.cutting => BodyWeightGoal.lose,
    DietPhase.bulking => BodyWeightGoal.gain,
    DietPhase.maintenance => BodyWeightGoal.maintain,
  };

  /// The phase a stored goal selects. An unset goal means maintenance — the
  /// phase that changes nothing, so it is the safe default before the user has
  /// expressed an intent.
  static DietPhase fromGoal(BodyWeightGoal? goal) => switch (goal) {
    BodyWeightGoal.lose => DietPhase.cutting,
    BodyWeightGoal.gain => DietPhase.bulking,
    BodyWeightGoal.maintain || null => DietPhase.maintenance,
  };
}

/// The four knobs that define a phase.
///
/// [adjustment] is *signed*: negative is a deficit, positive a surplus. Each
/// phase owns its own value, so moving from cutting to bulking must not disturb
/// the cutting configuration the user will switch back to.
typedef PhaseConfig = ({
  double adjustment,
  double proteinPerKg,
  double fatPercent,
  double fiberTarget,
});

/// Defaults that reproduce the pre-phase behaviour exactly.
///
/// The adjustments match the old goal-based ±500, and a 2.0 g/kg protein with a
/// 30% fat split leaves carbs taking the remainder — close to the fixed 30/40/30
/// the previous code hardcoded, so a user's targets move only slightly on upgrade
/// and never unexpectedly.
const double kDefaultProteinPerKg = 2.0;
const double kDefaultFatPercent = 30.0;
const double kDefaultFiberTarget = 30.0;

/// kcal adjustment seeded per phase.
const double kDefaultCuttingAdjustment = -500;
const double kDefaultBulkingAdjustment = 500;
const double kDefaultMaintenanceAdjustment = 0;
extension PhaseConfigCopy on PhaseConfig {
  /// Records have no built-in copyWith, and reconstructing one field at a time
  /// at every call site is where a knob gets dropped by accident.
  PhaseConfig copyWith({
    double? adjustment,
    double? proteinPerKg,
    double? fatPercent,
    double? fiberTarget,
  }) => (
    adjustment: adjustment ?? this.adjustment,
    proteinPerKg: proteinPerKg ?? this.proteinPerKg,
    fatPercent: fatPercent ?? this.fatPercent,
    fiberTarget: fiberTarget ?? this.fiberTarget,
  );
}
