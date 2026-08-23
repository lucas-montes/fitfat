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
