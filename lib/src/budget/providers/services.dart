import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../services/budget_sync.dart';
import '../services/remote_receipt_ocr.dart';

/// Remote OCR backend. Mock for now; swap for a real implementation later.
final remoteReceiptOcrProvider = Provider<RemoteReceiptOcrService>((ref) {
  return MockRemoteReceiptOcrService();
});

final budgetSyncServiceProvider = Provider<BudgetSyncService>((ref) {
  return BudgetSyncService(
    ref.watch(databaseProvider),
    ref.watch(remoteReceiptOcrProvider),
  );
});
