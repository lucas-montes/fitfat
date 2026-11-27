import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart' as uform;
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/money_data.dart';
import 'account_type_meta.dart';

/// "1,234.50 €" in the locale's style; [signed] adds + or − in front.
String formatMoneyIn(
  BuildContext context,
  double v,
  String code, {
  bool signed = false,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final f = NumberFormat.simpleCurrency(locale: locale, name: code);
  final s = f.format(v.abs());
  if (!signed || v == 0) return v < 0 ? '−$s' : s;
  return v < 0 ? '−$s' : '+$s';
}

const _categoryPalette = [
  Color(0xFF5E9FE0),
  Color(0xFFE0A15E),
  Color(0xFFB48CE0),
  Color(0xFF6CC08B),
  Color(0xFFE07A8C),
  Color(0xFF5EC7C7),
  Color(0xFFD7C25A),
  Color(0xFF9AA5E6),
];

/// A stable color per category name (grey when there is none).
Color categoryColor(BuildContext context, String? category) {
  if (category == null || category.isEmpty) {
    return Theme.of(context).colorScheme.outline;
  }
  var h = 0;
  for (final c in category.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _categoryPalette[h % _categoryPalette.length];
}

/// The row title: "Transfer to Savings" / "Transfer from BBVA", else the
/// note, else the category, else the type.
String entryTitle(
  AppLocalizations l10n,
  MoneyEntry e,
  Map<String, Account> accounts,
) {
  final t = e.txn;
  if (e.isTransfer) {
    final other = accounts[e.counterpartId]?.name ?? '?';
    return e.isTransferOut
        ? l10n.moneyTransferTo(other)
        : l10n.moneyTransferFrom(other);
  }
  final note = t.note?.trim();
  if (note != null && note.isNotEmpty) return note;
  if (t.category != null && t.category!.isNotEmpty) return t.category!;
  return t.type == TransactionType.income
      ? l10n.transactionTypeIncome
      : l10n.transactionTypeExpense;
}

/// One compact line: category dot, title and account, the signed amount (the
/// original currency under it when foreign).
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.entry,
    required this.accounts,
    required this.baseCode,
    this.showAccount = true,
    this.onTap,
  });

  final MoneyEntry entry;
  final Map<String, Account> accounts;
  final String baseCode;
  final bool showAccount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;
    final t = entry.txn;
    final sub = [
      if (showAccount) accounts[entry.accountId]?.name,
      if (!entry.isTransfer && t.note != null && t.note!.trim().isNotEmpty)
        t.category,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    const tabular = [FontFeature.tabularFigures()];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceL,
          vertical: FitFatTokens.spaceS,
        ),
        child: Row(
          spacing: FitFatTokens.spaceS + 2,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: entry.isTransfer
                    ? scheme.outline
                    : categoryColor(context, t.category),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entryTitle(l10n, entry, accounts),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoneyIn(
                    context,
                    entry.signedBase,
                    baseCode,
                    signed: true,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: tabular,
                    color: entry.signedBase > 0 ? success : scheme.onSurface,
                  ),
                ),
                if (t.currencyCode != baseCode)
                  Text(
                    formatMoneyIn(
                      context,
                      entry.signedOriginal,
                      t.currencyCode,
                      signed: true,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: tabular,
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

/// A day: tinted header with the date and the net (transfers excluded), then
/// the rows.
class MoneyDayCard extends StatelessWidget {
  const MoneyDayCard({
    super.key,
    required this.day,
    required this.baseCode,
    required this.children,
  });

  final MoneyDay day;
  final String baseCode;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(
              horizontal: FitFatTokens.spaceL,
              vertical: FitFatTokens.spaceS + 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat.MMMEd(locale).format(day.day),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatMoneyIn(context, day.net, baseCode, signed: true),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: day.net > 0 ? success : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: FitFatTokens.spaceL,
                endIndent: FitFatTokens.spaceL,
                color: scheme.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Read-only details of one line, with a way to the account's statement.
Future<void> showTransactionSheet(
  BuildContext context, {
  required MoneyEntry entry,
  required Map<String, Account> accounts,
  required String baseCode,
  bool offerStatement = true,
}) {
  final l10n = AppLocalizations.of(context)!;
  final t = entry.txn;
  final account = accounts[entry.accountId];
  final success =
      Theme.of(context).extension<FitFatColors>()?.success ??
      Theme.of(context).colorScheme.primary;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      Widget field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFatTokens.spaceS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceXl,
            0,
            FitFatTokens.spaceXl,
            FitFatTokens.spaceL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entryTitle(l10n, entry, accounts),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: FitFatTokens.spaceXs),
              Text(
                formatMoneyIn(ctx, entry.signedBase, baseCode, signed: true),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: entry.signedBase > 0 ? success : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (t.currencyCode != baseCode)
                Text(
                  l10n.moneyOriginalAt(
                    formatMoneyIn(ctx, entry.signedOriginal, t.currencyCode),
                    uform.formatFxRate(t.rateUsed),
                    baseCode,
                    t.currencyCode,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: FitFatTokens.spaceM),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FitFatTokens.spaceM,
                    vertical: FitFatTokens.spaceXs,
                  ),
                  child: Column(
                    children: [
                      if (entry.isTransfer)
                        field(
                          l10n.moneyFieldAccounts,
                          '${accounts[t.accountId]?.name ?? '?'} → '
                          '${accounts[t.toAccountId]?.name ?? '?'}',
                        )
                      else
                        field(l10n.moneyFieldAccount, account?.name ?? '—'),
                      if (!entry.isTransfer)
                        field(l10n.moneyFieldCategory, t.category ?? '—'),
                      field(
                        l10n.moneyFieldDate,
                        DateFormats.formatDate(ctx, t.date),
                      ),
                      field(l10n.moneyFieldNote, t.note ?? '—'),
                    ],
                  ),
                ),
              ),
              if (offerStatement && account != null) ...[
                const SizedBox(height: FitFatTokens.spaceM),
                FilledButton.tonalIcon(
                  icon: Icon(accountTypeIcon(account.type)),
                  label: Text(l10n.moneyOpenStatement(account.name)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/budget/account/${account.id}');
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
