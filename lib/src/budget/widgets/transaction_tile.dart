import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/format.dart' as uform;
import '../format.dart' as bf;
import '../models/transaction.dart';

/// Shared transaction row tile. Shows the amount in the base currency and,
/// when the transaction's currency differs from [baseCode], the rate that was
/// applied at conversion time.
final class TransactionTile extends StatelessWidget {
  final Transaction txn;
  final String baseCode;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.txn,
    required this.baseCode,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = txn.type == TransactionType.income;
    final isTransfer = txn.type == TransactionType.transfer;
    final sign = isIncome ? '+' : (isTransfer ? '' : '−');
    final color = isIncome
        ? Colors.green
        : (isTransfer ? Theme.of(context).colorScheme.primary : Colors.red);
    final title =
        txn.category ??
        (isTransfer
            ? l10n.transactionTypeTransfer
            : (isIncome
                  ? l10n.transactionTypeIncome
                  : l10n.transactionTypeExpense));

    final subtexts = <String>[
      if (txn.isDraft) l10n.transactionDraft,
      if (txn.receiptId != null) l10n.transactionHasReceipt,
      if (txn.currencyCode != baseCode && txn.rateUsed > 0)
        l10n.transactionRateUsed(
          uform.formatFxRate(txn.rateUsed),
          baseCode,
          txn.currencyCode,
        ),
    ];

    return Card(
      margin: margin,
      child: ListTile(
        leading: Icon(
          isIncome
              ? Icons.arrow_downward
              : (isTransfer ? Icons.swap_horiz : Icons.arrow_upward),
          color: color,
        ),
        title: Text(title),
        subtitle: subtexts.isEmpty ? null : Text(subtexts.join(' • ')),
        trailing: Text(
          '$sign${bf.formatMoney(txn.amountBase, baseCode)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
