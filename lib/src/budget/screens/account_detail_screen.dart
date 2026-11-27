import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/date_filter_chips.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/accounts.dart';
import '../providers/transactions.dart';
import '../services/balance.dart';
import '../services/money_data.dart';
import '../widgets/account_type_meta.dart';
import '../widgets/money_widgets.dart';

/// One account's statement: balance, this month in and out, the balance over
/// the last three months, then its lines by day (transfers signed by
/// direction), filtered by month or range. Read-only.
final class AccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

final class _AccountDetailScreenState
    extends ConsumerState<AccountDetailScreen> {
  DateFilter _filter = DateFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final base = ref.watch(settingsProvider).baseCurrency;
    final accounts = ref.watch(accountListProvider).value ?? const <Account>[];
    final txns =
        ref.watch(liveTransactionsProvider).value ?? const <Transaction>[];
    final account = accounts.where((a) => a.id == widget.accountId).firstOrNull;
    if (account == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final byId = {for (final a in accounts) a.id: a};
    final entries = statementEntries(txns, account.id);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    var monthIn = 0.0, monthOut = 0.0;
    for (final e in entries) {
      if (e.txn.date.isBefore(monthStart)) continue;
      if (e.signedBase > 0) monthIn += e.signedBase;
      if (e.signedBase < 0) monthOut += e.signedBase;
    }
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(today.year, today.month - 3, today.day);
    final series = balanceSeries(account, txns, from: from, to: today);
    final months = <DateTime>{
      for (final e in entries) DateTime(e.txn.date.year, e.txn.date.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final days = groupMoneyDays([
      for (final e in entries)
        if (_filter.contains(e.txn.date)) e,
    ], countTransfers: true);
    const tabular = [FontFeature.tabularFigures()];

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FitFatTokens.kContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: FitFatTokens.spaceXl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FitFatTokens.spaceL,
                  FitFatTokens.spaceXs,
                  FitFatTokens.spaceL,
                  FitFatTokens.spaceS,
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(FitFatTokens.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: FitFatTokens.spaceXs,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Icon(
                              accountTypeIcon(account.type),
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            Text(
                              '${accountTypeLabel(l10n, account.type)} · $base',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formatMoneyIn(
                            context,
                            accountBalance(account, txns),
                            base,
                          ),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: tabular,
                          ),
                        ),
                        Wrap(
                          spacing: FitFatTokens.spaceM,
                          children: [
                            Text(
                              l10n.moneyIn(
                                formatMoneyIn(
                                  context,
                                  monthIn,
                                  base,
                                  signed: true,
                                ),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: success,
                                fontFeatures: tabular,
                              ),
                            ),
                            Text(
                              l10n.moneyOut(
                                formatMoneyIn(
                                  context,
                                  monthOut,
                                  base,
                                  signed: true,
                                ),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFeatures: tabular,
                              ),
                            ),
                            Text(
                              DateFormat.MMMM(locale).format(now),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (series.length > 1) ...[
                          const SizedBox(height: FitFatTokens.spaceS),
                          SizedBox(
                            height: 72,
                            child: _BalanceChart(series: series),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var m = 2; m >= 0; m--)
                                Text(
                                  DateFormat.MMM(
                                    locale,
                                  ).format(DateTime(now.year, now.month - m)),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              DateFilterChips(
                months: months,
                value: _filter,
                earliest: entries.isEmpty
                    ? now
                    : entries
                          .map((e) => e.txn.date)
                          .reduce((a, b) => a.isBefore(b) ? a : b),
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(FitFatTokens.spaceL),
                  child: Text(
                    l10n.budgetNoTransactions,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final day in days)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FitFatTokens.spaceL,
                    0,
                    FitFatTokens.spaceL,
                    FitFatTokens.spaceM,
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
                          showAccount: false,
                          onTap: () => showTransactionSheet(
                            context,
                            entry: e,
                            accounts: byId,
                            baseCode: base,
                            offerStatement: false,
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

/// The end-of-day balance as a filled line, no axes.
final class _BalanceChart extends StatelessWidget {
  const _BalanceChart({required this.series});

  final List<({DateTime day, double balance})> series;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final values = series.map((s) => s.balance);
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo).abs() < 1 ? 1.0 : (hi - lo) * 0.1;
    return LineChart(
      LineChartData(
        minY: lo - pad,
        maxY: hi + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].balance),
            ],
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}
