import 'package:intl/intl.dart';

/// Formats [amount] as money in [currencyCode] (e.g. 'USD').
String formatMoney(double amount, String currencyCode) {
  final formatter = NumberFormat.currency(name: currencyCode, decimalDigits: 2);
  return formatter.format(amount);
}

/// Formats a signed base-currency delta with an explicit + / − sign.
String formatSigned(double amountBase, String baseCode) {
  final sign = amountBase < 0 ? '−' : '+';
  return '$sign${formatMoney(amountBase.abs(), baseCode)}';
}
