import '../../ui/widgets/date_filter_chips.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'balance.dart';

/// One line in a history or statement: a transaction as seen from one
/// account. A transfer gives two entries (out of the source, into the
/// destination); everything else gives one.
final class MoneyEntry {
  const MoneyEntry({
    required this.txn,
    required this.accountId,
    required this.signedBase,
    this.counterpartId,
  });

  final Transaction txn;

  /// The account this line belongs to.
  final String? accountId;

  /// Base-currency amount signed for [accountId]: income and transfers in are
  /// positive, expenses and transfers out negative.
  final double signedBase;

  /// For a transfer: the other account.
  final String? counterpartId;

  bool get isTransfer => txn.type == TransactionType.transfer;

  /// For a transfer: true when money leaves [accountId].
  bool get isTransferOut => isTransfer && signedBase < 0;

  /// Original-currency amount, signed like [signedBase].
  double get signedOriginal => signedBase < 0 ? -txn.amount : txn.amount;
}

/// Lines for every account: transfers split into an out and an in line.
/// Newest first (date, then creation); within a transfer, out before in.
List<MoneyEntry> historyEntries(List<Transaction> txns) {
  final out = <MoneyEntry>[];
  for (final t in txns) {
    if (t.isDraft) continue;
    switch (t.type) {
      case TransactionType.transfer:
        out.add(
          MoneyEntry(
            txn: t,
            accountId: t.accountId,
            signedBase: -t.amountBase,
            counterpartId: t.toAccountId,
          ),
        );
        out.add(
          MoneyEntry(
            txn: t,
            accountId: t.toAccountId,
            signedBase: t.amountBase,
            counterpartId: t.accountId,
          ),
        );
      case TransactionType.income:
        out.add(
          MoneyEntry(txn: t, accountId: t.accountId, signedBase: t.amountBase),
        );
      case TransactionType.expense:
        out.add(
          MoneyEntry(txn: t, accountId: t.accountId, signedBase: -t.amountBase),
        );
    }
  }
  out.sort((a, b) {
    final d = b.txn.date.compareTo(a.txn.date);
    if (d != 0) return d;
    return b.txn.createdAt.compareTo(a.txn.createdAt);
  });
  return out;
}

/// The lines of one account (its side of each transfer only).
List<MoneyEntry> statementEntries(List<Transaction> txns, String accountId) => [
  for (final e in historyEntries(txns))
    if (e.accountId == accountId) e,
];

/// Kinds the Type filter knows.
enum MoneyKind { income, expense, transfer }

/// Everything the history can be filtered by. Empty sets mean "any".
final class MoneyFilter {
  const MoneyFilter({
    this.date = DateFilter.all,
    this.accounts = const {},
    this.categories = const {},
    this.kinds = const {},
    this.query = '',
  });

  final DateFilter date;
  final Set<String> accounts;
  final Set<String> categories;
  final Set<MoneyKind> kinds;
  final String query;

  /// How many filters are set (the search is not counted).
  int get count =>
      (date.isAll ? 0 : 1) +
      (accounts.isEmpty ? 0 : 1) +
      (categories.isEmpty ? 0 : 1) +
      (kinds.isEmpty ? 0 : 1);

  MoneyFilter copyWith({
    DateFilter? date,
    Set<String>? accounts,
    Set<String>? categories,
    Set<MoneyKind>? kinds,
    String? query,
  }) => MoneyFilter(
    date: date ?? this.date,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    kinds: kinds ?? this.kinds,
    query: query ?? this.query,
  );

  bool matches(MoneyEntry e) {
    final t = e.txn;
    if (!date.contains(t.date)) return false;
    if (accounts.isNotEmpty && !accounts.contains(e.accountId)) return false;
    if (categories.isNotEmpty && !categories.contains(t.category)) {
      return false;
    }
    if (kinds.isNotEmpty) {
      final kind = switch (t.type) {
        TransactionType.income => MoneyKind.income,
        TransactionType.expense => MoneyKind.expense,
        TransactionType.transfer => MoneyKind.transfer,
      };
      if (!kinds.contains(kind)) return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !(t.note?.toLowerCase().contains(q) ?? false) &&
        !(t.category?.toLowerCase().contains(q) ?? false)) {
      return false;
    }
    return true;
  }
}

/// One day of lines and its net. Across all accounts transfers never count in
/// the net (the money stays yours); in one account's statement they do
/// ([countTransfers]).
typedef MoneyDay = ({DateTime day, List<MoneyEntry> entries, double net});

List<MoneyDay> groupMoneyDays(
  List<MoneyEntry> entries, {
  bool countTransfers = false,
}) {
  final byDay = <DateTime, List<MoneyEntry>>{};
  for (final e in entries) {
    final d = DateTime(e.txn.date.year, e.txn.date.month, e.txn.date.day);
    (byDay[d] ??= []).add(e);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in days)
      (
        day: d,
        entries: byDay[d]!,
        net: byDay[d]!
            .where((e) => countTransfers || !e.isTransfer)
            .fold(0.0, (a, e) => a + e.signedBase),
      ),
  ];
}

/// Account groups on the Money tab.
enum AccountGroup { everyday, savings, other }

AccountGroup accountGroupOf(AccountType t) => switch (t) {
  AccountType.bank ||
  AccountType.cash ||
  AccountType.credit => AccountGroup.everyday,
  AccountType.savings ||
  AccountType.investment ||
  AccountType.securities => AccountGroup.savings,
  AccountType.other => AccountGroup.other,
};

/// Income and spending (base currency) since [from], transfers excluded,
/// optionally for one account.
({double income, double expense}) inOut(
  List<Transaction> txns,
  DateTime from, {
  String? accountId,
}) {
  var income = 0.0, expense = 0.0;
  for (final t in txns) {
    if (t.isDraft || t.date.isBefore(from)) continue;
    if (accountId != null && t.accountId != accountId) continue;
    if (t.type == TransactionType.income) income += t.amountBase;
    if (t.type == TransactionType.expense) expense += t.amountBase;
  }
  return (income: income, expense: expense);
}

/// Change in net worth since [from] (income − spending; transfers cancel).
double netChangeSince(List<Transaction> txns, DateTime from) {
  final r = inOut(txns, from);
  return r.income - r.expense;
}

/// End-of-day balances of [account] from [from] to [to] (inclusive), one per
/// day.
List<({DateTime day, double balance})> balanceSeries(
  Account account,
  List<Transaction> txns, {
  required DateTime from,
  required DateTime to,
}) {
  final live = [
    for (final t in txns)
      if (!t.isDraft) t,
  ];
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  // Balance at the start: everything before it.
  var balance = accountBalance(account, [
    for (final t in live)
      if (t.date.isBefore(start)) t,
  ]);
  final byDay = <DateTime, List<Transaction>>{};
  for (final t in live) {
    if (t.date.isBefore(start)) continue;
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    (byDay[d] ??= []).add(t);
  }
  final out = <({DateTime day, double balance})>[];
  for (
    var d = start;
    !d.isAfter(end);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    for (final t in byDay[d] ?? const <Transaction>[]) {
      if (t.type == TransactionType.transfer) {
        if (t.accountId == account.id) balance -= t.amountBase;
        if (t.toAccountId == account.id) balance += t.amountBase;
      } else if (t.accountId == account.id) {
        balance += t.type == TransactionType.income
            ? t.amountBase
            : -t.amountBase;
      }
    }
    out.add((day: d, balance: balance));
  }
  return out;
}
