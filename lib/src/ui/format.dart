/// Formats a decimal value with no decimals when whole, one decimal when
/// fractional ("12" / "12.5") — shared by set weight/distance displays and
/// workout summary metrics. Matches the precision the actuals dialog accepts.
String formatDecimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

/// Formats an FX rate for display: up to 4 decimals with trailing zeros and
/// trailing decimal point stripped ("0.92", "1.25", "149"). Rates are tiny
/// (inverses ~0.009) so one decimal (as [formatDecimal]) would lose them.
String formatFxRate(double value) {
  var text = value.toStringAsFixed(4);
  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return text;
}
