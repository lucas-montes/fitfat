final class FxRate {
  final String code; // non-base currency, e.g. 'EUR'
  final double rateToBase; // 1 unit of `code` = rateToBase units of base
  final String baseCode; // base currency this rate is expressed against
  final DateTime updatedAt;

  const FxRate({
    required this.code,
    required this.rateToBase,
    required this.baseCode,
    required this.updatedAt,
  });
}
