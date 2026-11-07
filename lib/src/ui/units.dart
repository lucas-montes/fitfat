import '../models/units.dart';

/// Pounds per kilogram and centimetres per inch — the only conversion
/// factors the app needs since storage stays metric.
const _kgPerLb = 0.45359237;
const _cmPerIn = 2.54;

/// Converts a stored kg value into the display unit.
double weightFromKg(double kg, WeightUnit unit) => switch (unit) {
  WeightUnit.kg => kg,
  WeightUnit.lb => kg / _kgPerLb,
};

/// Converts a display-unit weight back into stored kg.
double weightToKg(double value, WeightUnit unit) => switch (unit) {
  WeightUnit.kg => value,
  WeightUnit.lb => value * _kgPerLb,
};

/// Converts a stored cm value into the display unit.
double lengthFromCm(double cm, LengthUnit unit) => switch (unit) {
  LengthUnit.cm => cm,
  LengthUnit.inch => cm / _cmPerIn,
};

/// Unit suffix for weight displays ('kg' | 'lb').
String weightUnitLabel(WeightUnit unit) => switch (unit) {
  WeightUnit.kg => 'kg',
  WeightUnit.lb => 'lb',
};

/// Unit suffix for length displays ('cm' | 'in').
String lengthUnitLabel(LengthUnit unit) => switch (unit) {
  LengthUnit.cm => 'cm',
  LengthUnit.inch => 'in',
};

/// Formats a stored kg value in the user's unit, e.g. "82.5".
String formatWeightValue(double kg, WeightUnit unit) =>
    weightFromKg(kg, unit).toStringAsFixed(1);

/// Formats a stored cm value in the user's unit, e.g. "183.0".
String formatLengthValue(double cm, LengthUnit unit) =>
    lengthFromCm(cm, unit).toStringAsFixed(1);

/// Formats a stored kg **volume** — a total lifted, not a body weight.
///
/// Compacts to metric tonnes once it passes a tonne, because weekly tonnage
/// runs into five and six figures and `48210.3 kg` is unreadable at a glance in
/// a one-third-width tile. Below that it falls back to the user's chosen weight
/// unit as usual.
///
/// The threshold is on the stored kg, not the displayed figure, so a lb user's
/// 1000 kg compacts to `1.0 t` rather than waiting for 2205 lb — the compaction
/// is about magnitude, not about which unit is displayed.
String formatVolume(double kg, WeightUnit unit) {
  if (kg.abs() >= 1000) {
    return '${(kg / 1000).toStringAsFixed(1)} t';
  }
  return '${formatWeightValue(kg, unit)} ${weightUnitLabel(unit)}';
}
