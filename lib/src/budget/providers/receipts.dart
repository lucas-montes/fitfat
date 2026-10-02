import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(ref.watch(databaseProvider));
});

final receiptListProvider = FutureProvider<List<Receipt>>((ref) async {
  return ref.watch(receiptRepositoryProvider).getAll();
});

final receiptByIdProvider = FutureProvider.family<Receipt?, String>((
  ref,
  id,
) async {
  return ref.watch(receiptRepositoryProvider).getById(id);
});

final receiptsByAccountProvider = FutureProvider.family<List<Receipt>, String>((
  ref,
  accountId,
) async {
  return ref.watch(receiptRepositoryProvider).getByAccount(accountId);
});

/// Receipts whose upload/parse never finished.
///
/// A receipt gets stranded here whenever the app is backgrounded or the network
/// drops mid-upload: capture kicks off `BudgetSyncService.uploadAndParse` as a
/// detached task whose errors are swallowed. `resumePendingReceipts` retries
/// them, so this is the query that decides what needs another attempt.
final receiptPendingProvider = FutureProvider<List<Receipt>>((ref) async {
  final database = ref.watch(databaseProvider);
  final rows = await (database.select(database.receipts)..where(
        (t) =>
            t.parsed.equals(false) &
            t.uploadStatus.isIn([
              ReceiptStatus.uploading.code,
              ReceiptStatus.parsing.code,
              ReceiptStatus.error.code,
            ]),
      ))
      .get();
  return rows
      .map(
        (r) => Receipt(
          id: r.id,
          localPath: r.localPath,
          remotePath: r.remotePath,
          status: ReceiptStatus.fromCode(r.uploadStatus),
          parsed: r.parsed,
          parsedJson: r.parsedJson,
          transactionId: r.transactionId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        ),
      )
      .toList();
});
