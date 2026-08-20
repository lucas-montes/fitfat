import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../providers/budget_overview.dart';
import '../providers/transactions.dart';
import '../widgets/transaction_tile.dart';

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
            return Center(child: Text(l10n.budgetNoTransactions));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: txns.length,
            itemBuilder: (context, i) {
              final txn = txns[i];
              return TransactionTile(
                txn: txn,
                baseCode: base,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () async {
                  await context.push('/budget/transaction/${txn.id}');
                  ref.invalidate(transactionListProvider);
                  ref.invalidate(budgetOverviewProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}
