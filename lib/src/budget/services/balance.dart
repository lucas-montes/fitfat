import '../models/account.dart';
import '../models/transaction.dart';

/// Net worth across every account (in the base currency), summing each
/// account's opening balance with the signed base-currency value of its
/// transactions.
double computeNetWorth(
  List<Account> accounts,
  List<Transaction> transactions,
) => accounts.fold(0.0, (sum, acc) {
  return sum + accountBalance(acc, transactions);
});

/// Balance of a single account (opening + signed base-currency transactions).
double accountBalance(
  Account account,
  List<Transaction> transactions,
) {
  var balance = account.openingBalance;
  for (final txn in transactions) {
    if (txn.type == TransactionType.transfer) {
      if (txn.accountId == account.id) balance -= txn.amountBase;
      if (txn.toAccountId == account.id) balance += txn.amountBase;
    } else if (txn.accountId == account.id) {
      balance += txn.type == TransactionType.income
          ? txn.amountBase
          : -txn.amountBase;
    }
  }
  return balance;
}

/// Signed effect of a single transaction on its source account's balance,
/// in base currency (income +, expense/transfer −).
double signedEffect(Transaction txn) {
  if (txn.type == TransactionType.income) return txn.amountBase;
  return -txn.amountBase;
}
