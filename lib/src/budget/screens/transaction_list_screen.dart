import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../format.dart' as bf;
import '../models/transaction.dart';
import '../providers/budget_overview.dart';
import '../providers/transactions.dart';

/// Global, filterable transaction list. Tapping a row opens the editor.
final class TransactionListScreen extends ConsumerWidget {
  final String? accountId;

  const TransactionListScreen({super.key, this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    final txnsAsync = accountId != null
        ? ref.watch(transactionByAccountProvider(accountId!))
        : ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionListAppBar)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.budgetFabExpense,
        onPressed: () async {
          await context.push('/budget/transaction/new?type=expense');
          ref.invalidate(transactionListProvider);
          ref.invalidate(budgetOverviewProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (txns) {
          if (txns.isEmpty) {
            return Center(
              child: Text(l10n.budgetNoTransactions),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: txns.length,
            itemBuilder: (context, i) {
              final txn = txns[i];
              final isIncome = txn.type == TransactionType.income;
              final isTransfer = txn.type == TransactionType.transfer;
              final sign = isIncome ? '+' : (isTransfer ? '' : '−');
              final color = isIncome
                  ? Colors.green
                  : (isTransfer
                      ? Theme.of(context).colorScheme.primary
                      : Colors.red);
              final title = txn.category ??
                  (isTransfer
                      ? l10n.transactionTypeTransfer
                      : (isIncome
                          ? l10n.transactionTypeIncome
                          : l10n.transactionTypeExpense));
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isIncome
                        ? Icons.arrow_downward
                        : (isTransfer ? Icons.swap_horiz : Icons.arrow_upward),
                    color: color,
                  ),
                  title: Text(title),
                  subtitle: txn.isDraft
                      ? Text(l10n.transactionDraft)
                      : (txn.receiptId != null
                          ? Text(l10n.transactionHasReceipt)
                          : null),
                  trailing: Text(
                    '$sign${bf.formatMoney(txn.amountBase, base)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  onTap: () async {
                    await context.push('/budget/transaction/${txn.id}');
                    ref.invalidate(transactionListProvider);
                    ref.invalidate(budgetOverviewProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
