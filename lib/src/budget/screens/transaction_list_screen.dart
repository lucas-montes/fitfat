import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../providers/transactions.dart';
import '../widgets/transaction_tile.dart';

/// Global, filterable transaction list. Read-only: transactions come from the server.
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
      body: txnsAsync.when(
        // Local data: never a spinner; the first frame is blank for a few ms.
        loading: () => const SizedBox.shrink(),
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
              );
            },
          );
        },
      ),
    );
  }
}
