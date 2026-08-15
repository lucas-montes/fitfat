import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../format.dart' as bf;
import '../models/receipt.dart';
import '../models/transaction.dart';
import '../providers/accounts.dart';
import '../providers/receipts.dart';
import '../providers/transactions.dart';
import '../services/balance.dart';
import '../widgets/account_type_meta.dart';

/// Account detail: balance resume + transactions + receipts for this account.
final class AccountDetailScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    final accountAsync = ref.watch(accountListProvider);
    final txnsAsync = ref.watch(transactionByAccountProvider(accountId));
    final receiptsAsync = ref.watch(receiptsByAccountProvider(accountId));

    final account = accountAsync.when(
      data: (list) {
        final matches = list.where((a) => a.id == accountId);
        return matches.isEmpty ? null : matches.first;
      },
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(account?.name ?? l10n.budgetAppBar),
        actions: [
          if (account != null)
            IconButton(
              tooltip: l10n.commonEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/budget/account/$accountId'),
            ),
        ],
      ),
      body: account == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(accountTypeIcon(account.type)),
                            const SizedBox(width: 8),
                            Text(
                              accountTypeLabel(l10n, account.type),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bf.formatMoney(
                            accountBalance(account, txnsAsync.value ?? []),
                            base,
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.accountOpeningLabel(
                            bf.formatMoney(account.openingBalance, base),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.accountTransactions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._txnTiles(context, l10n, base, txnsAsync.value ?? []),
                const SizedBox(height: 24),
                Text(
                  l10n.accountReceipts,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._receiptTiles(context, l10n, receiptsAsync.value ?? []),
              ],
            ),
    );
  }

  List<Widget> _txnTiles(
    BuildContext context,
    AppLocalizations l10n,
    String base,
    List<Transaction> txns,
  ) {
    if (txns.isEmpty) return [Text(l10n.budgetNoTransactions)];
    return txns.map((txn) {
      final isIncome = txn.type == TransactionType.income;
      final isTransfer = txn.type == TransactionType.transfer;
      final sign = isIncome ? '+' : (isTransfer ? '' : '−');
      final color = isIncome
          ? Colors.green
          : (isTransfer ? Theme.of(context).colorScheme.primary : Colors.red);
      final title = txn.category ??
          (isTransfer
              ? l10n.transactionTypeTransfer
              : (isIncome
                  ? l10n.transactionTypeIncome
                  : l10n.transactionTypeExpense));
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(
            isIncome
                ? Icons.arrow_downward
                : (isTransfer ? Icons.swap_horiz : Icons.arrow_upward),
            color: color,
          ),
          title: Text(title),
          subtitle: txn.isDraft ? Text(l10n.transactionDraft) : null,
          trailing: Text(
            '$sign${bf.formatMoney(txn.amountBase, base)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          onTap: () => context.push('/budget/transaction/${txn.id}'),
        ),
      );
    }).toList();
  }

  List<Widget> _receiptTiles(
    BuildContext context,
    AppLocalizations l10n,
    List<Receipt> receipts,
  ) {
    if (receipts.isEmpty) return [Text(l10n.budgetNoReceipts)];
    return receipts.map((r) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(l10n.receiptStatusLabel(r.status.name)),
          subtitle: r.parsed ? Text(l10n.receiptParsed) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/budget/receipt/${r.id}'),
        ),
      );
    }).toList();
  }
}
