import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/accounts.dart';
import '../providers/transactions.dart';
import '../services/balance.dart';

/// Aggregate figures for the Budget overview screen.
final class BudgetOverview {
  final List<AccountBalance> accounts;
  final double netWorth;
  final double monthIncome;
  final double monthExpense;
  final List<Transaction> recent;

  const BudgetOverview({
    required this.accounts,
    required this.netWorth,
    required this.monthIncome,
    required this.monthExpense,
    required this.recent,
  });
}

final class AccountBalance {
  final String id;
  final String name;
  final double balance;

  const AccountBalance({
    required this.id,
    required this.name,
    required this.balance,
  });
}

final budgetOverviewProvider = FutureProvider<BudgetOverview>((ref) async {
  final accounts = await ref.watch(accountRepositoryProvider).getAll();
  final transactions = await ref
      .watch(transactionRepositoryProvider)
      .getAll(includeDrafts: false);
  final recent = await ref.watch(transactionRepositoryProvider).getRecent(5);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  var monthIncome = 0.0;
  var monthExpense = 0.0;
  for (final txn in transactions) {
    if (txn.date.isBefore(startOfMonth)) continue;
    if (txn.type == TransactionType.income) {
      monthIncome += txn.amountBase;
    } else if (txn.type == TransactionType.expense) {
      monthExpense += txn.amountBase;
    }
  }

  final accountBalances = accounts
      .map(
        (a) => AccountBalance(
          id: a.id,
          name: a.name,
          balance: accountBalance(a, transactions),
        ),
      )
      .toList();

  return BudgetOverview(
    accounts: accountBalances,
    netWorth: computeNetWorth(accounts, transactions),
    monthIncome: monthIncome,
    monthExpense: monthExpense,
    recent: recent,
  );
});
