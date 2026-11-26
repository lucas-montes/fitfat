import 'package:intl/intl.dart';

/// Formats [amount] as money in [currencyCode] (e.g. 'USD').
String formatMoney(double amount, String currencyCode) {
  final formatter = NumberFormat.currency(name: currencyCode, decimalDigits: 2);
  return formatter.format(amount);
}
