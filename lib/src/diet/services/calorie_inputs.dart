import '../../models/activity_level.dart';
import '../../models/gender.dart';

/// The measured body inputs the energy maths needs.
///
/// Records, not a class: this is a bundle of values with no behaviour, and the
/// codebase already speaks in records for exactly this shape ([MacroTargets],
/// [CalorieTargetMeta]). Null means "not measured", never "zero".
typedef BodyProfile = ({double? weightKg, double? heightCm});

/// The self-reported inputs a user has entered in settings.
///
/// Deliberately narrower than [SettingsState]: the calculator needs to know
/// who the person is, not how the app is themed or which server it syncs to.
typedef CalorieInputs = ({
  int? age,
  Gender? gender,
  double? bodyFatPercent,
  bool trackBodyFat,
  ActivityLevel? activityLevel,
});

/// Supplies the latest measured [BodyProfile].
///
/// The seam exists so the calorie chain can be driven from a test double
/// instead of the database; the Riverpod implementation just wraps
/// `latestBodyMetricsProvider`.
abstract class BodyProfileSource {
  Future<BodyProfile> latest();
}

/// Supplies the self-reported [CalorieInputs].
///
/// Synchronous because settings are already resident in memory — there is no
/// query to make, and nothing here should pretend otherwise.
abstract class UserProfileSource {
  CalorieInputs current();
}

/// Weight assumed when nothing has been measured, in kg.
const double kFallbackWeightKg = 70;

/// Height assumed when nothing has been measured, in cm.
const double kFallbackHeightCm = 170;

/// Age assumed when the user has not given one.
const int kFallbackAge = 30;

/// Sex assumed when the user has not given one.
const Gender kFallbackGender = Gender.male;

/// The placeholder body used when nothing has been measured.
///
/// One constant for every consumer: BMR, the macro targets and the settings
/// warning must never disagree about the weight they assumed, and duplicating
/// the 70 kg default across those call sites is how they eventually would.
const BodyProfile kFallbackBodyProfile = (
  weightKg: kFallbackWeightKg,
  heightCm: kFallbackHeightCm,
);