import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../models/account.dart';
import '../models/receipt.dart';
import '../models/transaction.dart';
import '../providers/accounts.dart';
import '../providers/receipts.dart';
import '../providers/transactions.dart';
import '../services/balance.dart';
import '../services/money_data.dart';
import '../widgets/account_type_meta.dart';
import '../widgets/money_widgets.dart';
import 'transaction_list_screen.dart';

/// The Money tab: net worth, the accounts grouped by type as rows of cards,
/// and the last days of transactions. Everything here comes from the server
/// and is read-only; receipts (the phone's upload queue) sit behind the
/// receipt icon.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const _recentDays = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;
    final base = ref.watch(settingsProvider).baseCurrency;
    final accounts = ref.watch(accountListProvider).value ?? const <Account>[];
    final txns =
        ref.watch(liveTransactionsProvider).value ?? const <Transaction>[];
    final waiting =
        ref
            .watch(receiptListProvider)
            .value
            ?.where((r) => r.status != ReceiptStatus.uploaded)
            .length ??
        0;
    final byId = {for (final a in accounts) a.id: a};
    final balances = {for (final a in accounts) a.id: accountBalance(a, txns)};
    final netWorth = balances.values.fold(0.0, (a, b) => a + b);
    final now = DateTime.now();
    final change = netChangeSince(txns, DateTime(now.year, now.month));
    final days = groupMoneyDays(historyEntries(txns)).take(_recentDays);

    void openHistory({bool search = false}) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionListScreen(autofocusSearch: search),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetAppBar),
        actions: [
          IconButton(
            tooltip: l10n.receiptListTitle,
            icon: Badge(
              isLabelVisible: waiting > 0,
              label: Text('$waiting'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            onPressed: () => context.push('/budget/receipts'),
          ),
          IconButton(
            tooltip: l10n.commonSearch,
            icon: const Icon(Icons.search),
            onPressed: () => openHistory(search: true),
          ),
        ],
      ),
      body: accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_outlined,
              title: l10n.budgetAccounts,
              description: l10n.budgetEmptyAccounts,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FitFatTokens.kContentMaxWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    FitFatTokens.spaceXs,
                    0,
                    FitFatTokens.spaceXl,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FitFatTokens.spaceL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.budgetTotalBalance,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            formatMoneyIn(context, netWorth, base),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (change != 0)
                            Text(
                              l10n.moneyThisMonth(
                                formatMoneyIn(
                                  context,
                                  change,
                                  base,
                                  signed: true,
                                ),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: change > 0
                                    ? success
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final group in AccountGroup.values)
                      if (accounts
                              .where((a) => accountGroupOf(a.type) == group)
                              .toList()
                          case final list when list.isNotEmpty) ...[
                        _GroupHeader(
                          label: switch (group) {
                            AccountGroup.everyday => l10n.moneyGroupEveryday,
                            AccountGroup.savings => l10n.moneyGroupSavings,
                            AccountGroup.other => l10n.moneyGroupOther,
                          },
                          total: formatMoneyIn(
                            context,
                            list.fold(0.0, (a, x) => a + balances[x.id]!),
                            base,
                          ),
                        ),
                        SizedBox(
                          height: 124,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: FitFatTokens.spaceL,
                            ),
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: FitFatTokens.spaceS),
                            itemBuilder: (_, i) => AccountCard(
                              account: list[i],
                              balance: formatMoneyIn(
                                context,
                                balances[list[i].id]!,
                                base,
                              ),
                              onTap: () =>
                                  context.push('/budget/account/${list[i].id}'),
                            ),
                          ),
                        ),
                      ],
                    _GroupHeader(
                      label: l10n.moneyRecent,
                      trailing: TextButton(
                        onPressed: openHistory,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(l10n.trainingAll),
                      ),
                    ),
                    if (days.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FitFatTokens.spaceL,
                        ),
                        child: Text(l10n.budgetNoTransactions),
                      ),
                    for (final day in days)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FitFatTokens.spaceL,
                          0,
                          FitFatTokens.spaceL,
                          FitFatTokens.spaceS,
                        ),
                        child: MoneyDayCard(
                          day: day,
                          baseCode: base,
                          children: [
                            for (final e in day.entries)
                              MoneyRow(
                                entry: e,
                                accounts: byId,
                                baseCode: base,
                                onTap: () => showTransactionSheet(
                                  context,
                                  entry: e,
                                  accounts: byId,
                                  baseCode: base,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, this.total, this.trailing});

  final String label;
  final String? total;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL + FitFatTokens.spaceXs,
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        FitFatTokens.spaceXs,
      ),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: style)),
            if (total != null)
              Text(
                total!,
                style: style?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Icon, name, balance and type; tap for the statement.
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.balance,
    required this.onTap,
  });

  final Account account;
  final String balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      width: 148,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
                  ),
                  child: Icon(
                    accountTypeIcon(account.type),
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    balance,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  accountTypeLabel(l10n, account.type),
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
