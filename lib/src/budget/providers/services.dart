import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../network/api_client.dart';
import '../services/budget_sync.dart';
import '../services/remote_fx.dart';
import '../services/remote_receipt_ocr.dart';

/// Remote OCR backend. Mock for now; swap for a real implementation later.
final remoteReceiptOcrProvider = Provider<RemoteReceiptOcrService>((ref) {
  return MockRemoteReceiptOcrService();
});

/// Remote FX-rates backend: a real service on top of the (overridable)
/// [apiClientProvider], behind the configurable `FX_API_BASE_URL` seam.
/// `MockRemoteFxService` remains available for tests.
final remoteFxProvider = Provider<RemoteFxService>((ref) {
  return FxRateRemoteService(
    ref.watch(apiClientProvider),
    baseUrl: fxRatesApiBaseUrl,
  );
});

final budgetSyncServiceProvider = Provider<BudgetSyncService>((ref) {
  return BudgetSyncService(
    ref.watch(databaseProvider),
    ref.watch(remoteReceiptOcrProvider),
  );
});
