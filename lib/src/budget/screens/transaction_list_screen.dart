import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/date_filter_chips.dart';
import '../../ui/widgets/empty_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/accounts.dart';
import '../providers/transactions.dart';
import '../services/money_data.dart';
import '../widgets/money_widgets.dart';

/// Every transaction, one card per day with its net, compact rows. A transfer
/// shows twice: out of one account, into the other. One Filters button opens
/// every filter; the ones set show as removable chips beside it.
final class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key, this.autofocusSearch = false});

  final bool autofocusSearch;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

final class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  late bool _searching = widget.autofocusSearch;
  MoneyFilter _filter = const MoneyFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    final accounts = ref.watch(accountListProvider).value ?? const <Account>[];
    final txns =
        ref.watch(liveTransactionsProvider).value ?? const <Transaction>[];
    final byId = {for (final a in accounts) a.id: a};
    final all = historyEntries(txns);
    final shown = [
      for (final e in all)
        if (_filter.matches(e)) e,
    ];
    final days = groupMoneyDays(shown);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.moneySearch,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) =>
                    setState(() => _filter = _filter.copyWith(query: v)),
              )
            : Text(l10n.transactionListAppBar),
        actions: [
          IconButton(
            tooltip: l10n.commonSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _filter = _filter.copyWith(query: '');
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterLine(
            filter: _filter,
            accounts: byId,
            onOpen: () async {
              final picked = await showMoneyFilterSheet(
                context,
                initial: _filter,
                entries: all,
                accounts: accounts,
              );
              if (picked != null) setState(() => _filter = picked);
            },
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: days.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.moneyNoMatchTitle,
                    description: txns.isEmpty
                        ? l10n.budgetNoTransactions
                        : l10n.moneyNoMatchBody,
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: FitFatTokens.kContentMaxWidth,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          FitFatTokens.spaceL,
                          FitFatTokens.spaceXs,
                          FitFatTokens.spaceL,
                          FitFatTokens.spaceXl,
                        ),
                        itemCount: days.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: FitFatTokens.spaceM),
                        itemBuilder: (_, i) => MoneyDayCard(
                          day: days[i],
                          baseCode: base,
                          children: [
                            for (final e in days[i].entries)
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
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String _kindLabel(AppLocalizations l10n, MoneyKind k) => switch (k) {
  MoneyKind.income => l10n.moneyKindIn,
  MoneyKind.expense => l10n.moneyKindOut,
  MoneyKind.transfer => l10n.moneyKindTransfers,
};

String _dateLabel(BuildContext context, DateFilter f) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  if (f.range != null) {
    return '${DateFormat.MMMd(locale).format(f.range!.start)} – '
        '${DateFormat.MMMd(locale).format(f.range!.end)}';
  }
  final m = f.month!;
  return m.year == DateTime.now().year
      ? DateFormat.MMM(locale).format(m)
      : DateFormat.yMMM(locale).format(m);
}

/// "Filters · N" and one removable chip per filter that is set.
class _FilterLine extends StatelessWidget {
  const _FilterLine({
    required this.filter,
    required this.accounts,
    required this.onOpen,
    required this.onChanged,
  });

  final MoneyFilter filter;
  final Map<String, Account> accounts;
  final VoidCallback onOpen;
  final ValueChanged<MoneyFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = filter;
    final chips = <Widget>[
      if (!f.date.isAll)
        InputChip(
          label: Text(_dateLabel(context, f.date)),
          onDeleted: () => onChanged(f.copyWith(date: DateFilter.all)),
        ),
      for (final id in f.accounts)
        InputChip(
          label: Text(accounts[id]?.name ?? '?'),
          onDeleted: () =>
              onChanged(f.copyWith(accounts: {...f.accounts}..remove(id))),
        ),
      for (final c in f.categories)
        InputChip(
          label: Text(c),
          onDeleted: () =>
              onChanged(f.copyWith(categories: {...f.categories}..remove(c))),
        ),
      for (final k in f.kinds)
        InputChip(
          label: Text(_kindLabel(l10n, k)),
          onDeleted: () =>
              onChanged(f.copyWith(kinds: {...f.kinds}..remove(k))),
        ),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceL,
          vertical: FitFatTokens.spaceXs,
        ),
        children: [
          ActionChip(
            key: const ValueKey('moneyFilters'),
            avatar: const Icon(Icons.filter_list, size: 18),
            label: Text(
              f.count == 0
                  ? l10n.moneyFilters
                  : l10n.moneyFiltersCount(f.count),
            ),
            onPressed: onOpen,
          ),
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(left: FitFatTokens.spaceS),
              child: c,
            ),
        ],
      ),
    );
  }
}

/// Every filter in one sheet — when, account, category, type — with a live
/// count on the button. Returns the new filter, or null when dismissed.
Future<MoneyFilter?> showMoneyFilterSheet(
  BuildContext context, {
  required MoneyFilter initial,
  required List<MoneyEntry> entries,
  required List<Account> accounts,
}) {
  final months = <DateTime>{
    for (final e in entries) DateTime(e.txn.date.year, e.txn.date.month),
  }.toList()..sort((a, b) => b.compareTo(a));
  final categories = <String>{
    for (final e in entries)
      if (e.txn.category case final c? when c.isNotEmpty) c,
  }.toList()..sort();
  final earliest = entries.isEmpty
      ? DateTime.now()
      : entries.map((e) => e.txn.date).reduce((a, b) => a.isBefore(b) ? a : b);
  return showModalBottomSheet<MoneyFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      var f = initial;
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final l10n = AppLocalizations.of(ctx)!;
          final theme = Theme.of(ctx);
          final count = entries.where(f.matches).length;
          Widget label(String text) => Padding(
            padding: const EdgeInsets.only(
              top: FitFatTokens.spaceM,
              bottom: FitFatTokens.spaceXs,
            ),
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
          Widget wrap(List<Widget> children) => Wrap(
            spacing: FitFatTokens.spaceS,
            runSpacing: FitFatTokens.spaceXs,
            children: children,
          );
          Set<T> toggled<T>(Set<T> s, T v) =>
              s.contains(v) ? ({...s}..remove(v)) : {...s, v};
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  FitFatTokens.spaceL,
                  0,
                  FitFatTokens.spaceL,
                  FitFatTokens.spaceL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.moneyFilters,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (f.count > 0)
                          TextButton(
                            onPressed: () =>
                                setSheet(() => f = MoneyFilter(query: f.query)),
                            child: Text(l10n.moneyClearFilters),
                          ),
                      ],
                    ),
                    label(l10n.moneyWhen),
                    wrap([
                      ChoiceChip(
                        label: Text(l10n.trainingAllTime),
                        selected: f.date.isAll,
                        onSelected: (_) => setSheet(
                          () => f = f.copyWith(date: DateFilter.all),
                        ),
                      ),
                      for (final m in months.take(12))
                        ChoiceChip(
                          label: Text(_dateLabel(ctx, DateFilter(month: m))),
                          selected: f.date.month == m && f.date.range == null,
                          onSelected: (_) => setSheet(
                            () => f = f.copyWith(date: DateFilter(month: m)),
                          ),
                        ),
                      ChoiceChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          f.date.range == null
                              ? l10n.trainingRange
                              : _dateLabel(ctx, f.date),
                        ),
                        selected: f.date.range != null,
                        onSelected: (_) async {
                          final r = await pickDateRange(
                            ctx,
                            earliest: earliest,
                            current: f.date.range,
                          );
                          if (r != null) {
                            setSheet(
                              () => f = f.copyWith(date: DateFilter(range: r)),
                            );
                          }
                        },
                      ),
                    ]),
                    if (accounts.isNotEmpty) ...[
                      label(l10n.moneyFieldAccount),
                      wrap([
                        for (final a in accounts)
                          FilterChip(
                            label: Text(a.name),
                            selected: f.accounts.contains(a.id),
                            onSelected: (_) => setSheet(
                              () => f = f.copyWith(
                                accounts: toggled(f.accounts, a.id),
                              ),
                            ),
                          ),
                      ]),
                    ],
                    if (categories.isNotEmpty) ...[
                      label(l10n.moneyFieldCategory),
                      wrap([
                        for (final c in categories)
                          FilterChip(
                            avatar: CircleAvatar(
                              radius: 5,
                              backgroundColor: categoryColor(ctx, c),
                            ),
                            label: Text(c),
                            selected: f.categories.contains(c),
                            onSelected: (_) => setSheet(
                              () => f = f.copyWith(
                                categories: toggled(f.categories, c),
                              ),
                            ),
                          ),
                      ]),
                    ],
                    label(l10n.moneyType),
                    wrap([
                      for (final k in MoneyKind.values)
                        FilterChip(
                          label: Text(_kindLabel(l10n, k)),
                          selected: f.kinds.contains(k),
                          onSelected: (_) => setSheet(
                            () => f = f.copyWith(kinds: toggled(f.kinds, k)),
                          ),
                        ),
                    ]),
                    const SizedBox(height: FitFatTokens.spaceL),
                    FilledButton(
                      key: const ValueKey('moneyFilterApply'),
                      onPressed: () => Navigator.of(ctx).pop(f),
                      child: Text(l10n.moneyShowCount(count)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
