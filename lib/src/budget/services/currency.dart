/// Converts [amount] from [fromCode] to [baseCode] using [ratesToBase],
/// a map of non-base currency code -> rate to one unit of base.
/// Returns the converted amount and the rate applied (1.0 when from == base
/// or no rate is available).
(double amountBase, double rateUsed) convertToBase(
  double amount,
  String fromCode,
  String baseCode,
  Map<String, double> ratesToBase,
) {
  if (fromCode == baseCode) return (amount, 1.0);
  final rate = ratesToBase[fromCode];
  if (rate == null || rate <= 0) return (amount, 1.0);
  return (amount * rate, rate);
}
