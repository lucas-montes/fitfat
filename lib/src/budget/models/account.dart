import 'package:uuid/uuid.dart';

enum AccountType {
  savings,
  investment,
  cash,
  bank,
  credit,
  other;

  static AccountType fromName(String? name) => switch (name) {
    'savings' => AccountType.savings,
    'investment' => AccountType.investment,
    'cash' => AccountType.cash,
    'bank' => AccountType.bank,
    'credit' => AccountType.credit,
    _ => AccountType.other,
  };
}

final class Account {
  final String id;
  final String name;
  final AccountType type;
  final double openingBalance;
  final String? note;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    this.note,
    required this.createdAt,
  });

  Account copyWith({
    String? name,
    AccountType? type,
    double? openingBalance,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) => Account(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    openingBalance: openingBalance ?? this.openingBalance,
    note: clearNote ? null : (note ?? this.note),
    createdAt: createdAt ?? this.createdAt,
  );
}

/// Creates a new [Account] with a fresh UUID v7 and the current timestamp.
Account newAccount({
  required String name,
  required AccountType type,
  double openingBalance = 0,
  String? note,
}) => Account(
  id: const Uuid().v7(),
  name: name,
  type: type,
  openingBalance: openingBalance,
  note: note,
  createdAt: DateTime.now(),
);
