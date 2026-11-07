import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../models/account.dart';
import '../repositories/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(databaseProvider));
});

final accountListProvider = FutureProvider<List<Account>>((ref) async {
  return ref.watch(accountRepositoryProvider).getAll();
});
