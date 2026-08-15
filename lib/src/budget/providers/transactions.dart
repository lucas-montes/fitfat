import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final transactionListProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getAll();
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getRecent(10);
});

final transactionByAccountProvider =
    FutureProvider.family<List<Transaction>, String>((ref, accountId) async {
  return ref.watch(transactionRepositoryProvider).getByAccount(accountId);
});
