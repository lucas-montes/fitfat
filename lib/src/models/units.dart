/// User-selectable display units (schema-agnostic, prefs-backed).
///
/// Stored data stays metric (kg / cm); conversion happens at display time
/// only — see `lib/src/ui/units.dart`.
enum WeightUnit { kg, lb }

// `in` is a reserved word, so the inch unit is named `inch` (persisted as
// 'inch' in prefs; display suffix stays 'in').
enum LengthUnit { cm, inch }
