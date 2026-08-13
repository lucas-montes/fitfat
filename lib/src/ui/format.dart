/// Formats a decimal value with no decimals when whole, one decimal when
/// fractional ("12" / "12.5") — shared by set weight/distance displays and
/// workout summary metrics. Matches the precision the actuals dialog accepts.
String formatDecimal(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
