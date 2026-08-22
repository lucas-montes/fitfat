import '../budget/services/currency.dart';

/// Plain domain model for an observed ingredient price at a store.
///
/// One row per (ingredient, store, day): re-recording a price for the same
/// store on the same day overwrites the previous one.
final class IngredientPrice {
  final String id;
  final String ingredientId;
  final String storeId;
  // Price in the currency it was observed in.
  final double price;
  // ISO-4217-ish currency code, e.g. 'USD'.
  final String currencyCode;
  // Package weight the price refers to; null when unknown, in which case
  // cost-per-100g cannot be computed.
  final double? packageGrams;
  final DateTime recordedAt;

  const IngredientPrice({
    required this.id,
    required this.ingredientId,
    required this.storeId,
    required this.price,
    required this.currencyCode,
    required this.recordedAt,
    this.packageGrams,
  });

  /// Cost per 100g converted to [baseCode] using [ratesToBase] — null when
  /// the package weight is unknown or zero.
  double? costPer100gInBase({
    required String baseCode,
    required Map<String, double> ratesToBase,
  }) {
    final grams = packageGrams;
    if (grams == null || grams <= 0) return null;
    final (base, _) = convertToBase(price, currencyCode, baseCode, ratesToBase);
    return base * 100 / grams;
  }
}
