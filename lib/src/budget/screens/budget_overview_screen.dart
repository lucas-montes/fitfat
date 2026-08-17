import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../format.dart' as bf;
import '../providers/budget_overview.dart';
import '../providers/receipts.dart';
import '../models/transaction.dart';
import '../models/receipt.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) => const BudgetScreen();
}

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    final overviewAsync = ref.watch(budgetOverviewProvider);
    final receiptsAsync = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetAppBar)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/budget/transaction/new'),
        tooltip: l10n.budgetAddTransaction,
        child: const Icon(Icons.add),
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString()),
              TextButton(
                onPressed: () => ref.invalidate(budgetOverviewProvider),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (overview) {
            final pendingReceipts = receiptsAsync.value
                  ?.where((r) => r.status != ReceiptStatus.uploaded)
                  .length ??
              0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                base: base,
                netWorth: overview.netWorth,
                monthIncome: overview.monthIncome,
                monthExpense: overview.monthExpense,
              ),
              const SizedBox(height: 16),
              if (pendingReceipts > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => context.push('/budget/receipts'),
                  child: Chip(
                    avatar: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text(l10n.budgetPendingReceipts(pendingReceipts)),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.budgetAccounts,
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.push('/budget/account/new'),
                    child: Text(l10n.budgetAddAccount),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (overview.accounts.isEmpty)
                _EmptyAccounts(l10n: l10n)
              else
                ...overview.accounts.map(
                  (a) => ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(a.name),
                    trailing: Text(bf.formatMoney(a.balance, base)),
                    onTap: () => context.push('/budget/account/${a.id}'),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.budgetRecentTransactions,
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.push('/budget/transactions'),
                    child: Text(l10n.budgetViewAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (overview.recent.isEmpty)
                Text(l10n.budgetNoTransactions)
              else
                ...overview.recent.map((t) => _TransactionTile(t: t, base: base)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.base,
    required this.netWorth,
    required this.monthIncome,
    required this.monthExpense,
  });

  final String base;
  final double netWorth;
  final double monthIncome;
  final double monthExpense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.budgetTotalBalance,
                style: Theme.of(context).textTheme.labelMedium),
            Text(bf.formatMoney(netWorth, base),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.budgetMonthIncome,
                    value: bf.formatMoney(monthIncome, base),
                    positive: true,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: l10n.budgetMonthExpense,
                    value: bf.formatMoney(monthExpense, base),
                    positive: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.positive,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme.titleMedium
                ?.copyWith(color: color)),
      ],
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.budgetEmptyAccounts),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/budget/account/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.budgetAddAccount),
            ),
          ],
        ),
      );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.t, required this.base});
  final Transaction t;
  final String base;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = switch (t.type) {
      TransactionType.income => l10n.transactionTypeIncome,
      TransactionType.transfer => l10n.transactionTypeTransfer,
      TransactionType.expense => l10n.transactionTypeExpense,
    };
    return ListTile(
      leading: Icon(switch (t.type) {
        TransactionType.income => Icons.attach_money_outlined,
        TransactionType.transfer => Icons.swap_horiz_outlined,
        TransactionType.expense => Icons.money_off_outlined,
      }),
      title: Text(typeLabel),
      subtitle: Text(DateFormat.yMd().format(t.date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (t.isDraft)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(label: Text(l10n.transactionDraftBadge)),
            ),
          Text(bf.formatMoney(t.amountBase, base)),
        ],
      ),
      onTap: () => context.push('/budget/transaction/${t.id}'),
    );
  }
}
