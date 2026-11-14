import 'package:uuid/uuid.dart';

/// What an account holds. The server owns the type: the pull sends it down
/// and the phone never pushes it. The server's vocabulary is [cash],
/// [savings] and [securities] (a broker's positions); [credit] is a card the server
/// leaves alone, and the rest are the old vocabulary, kept only so a row that
/// still holds one reads as itself until the server's renamed type arrives.
enum AccountType {
  cash,
  savings,
  securities,
  investment,
  bank,
  credit,
  other;

  /// The types an account can be given: the ones the server knows.
  static const choosable = [cash, savings, securities];

  static AccountType fromName(String? name) => switch (name) {
    'savings' => AccountType.savings,
    'securities' => AccountType.securities,
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
