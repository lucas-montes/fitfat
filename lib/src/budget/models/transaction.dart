import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense,
  transfer;

  static TransactionType fromName(String? name) => switch (name) {
        'income' => TransactionType.income,
        'expense' => TransactionType.expense,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      };

  bool get isTransfer => this == TransactionType.transfer;
}

final class Transaction {
  final String id;
  final TransactionType type;
  final double amount; // in currencyCode
  final String currencyCode;
  final double amountBase; // converted to base currency
  final double rateUsed;
  final String? accountId; // source account (null while draft)
  final String? toAccountId; // transfer destination
  final String? category;
  final DateTime date;
  final String? note;
  final String? receiptId;
  final bool isDraft;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.amountBase,
    required this.rateUsed,
    this.accountId,
    this.toAccountId,
    this.category,
    required this.date,
    this.note,
    this.receiptId,
    required this.isDraft,
    required this.createdAt,
  });

  Transaction copyWith({
    TransactionType? type,
    double? amount,
    String? currencyCode,
    double? amountBase,
    double? rateUsed,
    String? accountId,
    String? toAccountId,
    bool clearToAccountId = false,
    String? category,
    bool clearCategory = false,
    DateTime? date,
    String? note,
    bool clearNote = false,
    String? receiptId,
    bool clearReceiptId = false,
    bool? isDraft,
    DateTime? createdAt,
  }) => Transaction(
    id: id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    currencyCode: currencyCode ?? this.currencyCode,
    amountBase: amountBase ?? this.amountBase,
    rateUsed: rateUsed ?? this.rateUsed,
    accountId: accountId ?? this.accountId,
    toAccountId: clearToAccountId
        ? null
        : (toAccountId ?? this.toAccountId),
    category: clearCategory ? null : (category ?? this.category),
    date: date ?? this.date,
    note: clearNote ? null : (note ?? this.note),
    receiptId: clearReceiptId ? null : (receiptId ?? this.receiptId),
    isDraft: isDraft ?? this.isDraft,
    createdAt: createdAt ?? this.createdAt,
  );
}

Transaction newTransaction({
  required TransactionType type,
  required double amount,
  required String currencyCode,
  required double amountBase,
  required double rateUsed,
  String? accountId,
  String? toAccountId,
  String? category,
  required DateTime date,
  String? note,
  String? receiptId,
  bool isDraft = false,
}) => Transaction(
  id: const Uuid().v7(),
  type: type,
  amount: amount,
  currencyCode: currencyCode,
  amountBase: amountBase,
  rateUsed: rateUsed,
  accountId: accountId,
  toAccountId: toAccountId,
  category: category,
  date: date,
  note: note,
  receiptId: receiptId,
  isDraft: isDraft,
  createdAt: DateTime.now(),
);
