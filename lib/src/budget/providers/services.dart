import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../database/database_provider.dart';
import '../../network/api_client.dart';
import '../../settings/providers/settings.dart';
import '../models/receipt.dart';
import '../services/budget_sync.dart';
import '../services/http_remote_receipt_ocr.dart';
import '../services/remote_receipt_ocr.dart';
import 'fx_rates.dart';
import 'receipts.dart';

/// Server-side receipt OCR backend.
///
/// Built from the active sync-server profile, so it follows the same URL and
/// API key as the rest of the sync layer. The base URL is read from settings at
/// construction time (not the compile-time `API_BASE_URL` used by
/// `apiClientProvider`), matching how `sync_service.dart` builds its clients.
///
/// When no server is configured the service still resolves, but every call fails
/// fast with a clear message rather than hanging.
final remoteReceiptOcrProvider = Provider<RemoteReceiptOcrService>((ref) {
  final settings = ref.watch(settingsProvider);
  final baseUrl = settings.remoteSyncBaseUrl.trim().replaceAll(
    RegExp(r'/+$'),
    '',
  );
  final timeout = Duration(seconds: settings.apiTimeoutSeconds);

  return HttpRemoteReceiptOcrService(
    client: HttpApiClient(
      http.Client(),
      baseUrl: baseUrl,
      timeout: timeout,
    ),
    apiKey: settings.remoteSyncApiKey,
    baseEndpoint: settings.endpointReceiptPictures,
    requestTimeout: timeout,
  );
});

final budgetSyncServiceProvider = Provider<BudgetSyncService>((ref) {
  return BudgetSyncService(
    ref.watch(databaseProvider),
    ref.watch(remoteReceiptOcrProvider),
  );
});

/// Receipt ids with an upload/parse currently in flight, so the list sweep and
/// the viewer sweep cannot both retry the same receipt.
final _inFlightReceipts = <String>{};

/// Retries every receipt left mid-flight by an interrupted upload.
///
/// Capture starts `uploadAndParse` as a detached task and swallows its errors,
/// so a receipt can be stranded in `uploading`/`parsing`/`error` indefinitely.
/// Watching this provider recovers those without the user re-picking the photo.
/// Failures stay recorded on the row; the next sweep tries again.
///
/// The returned int is the number of receipts attempted on the last run, so the
/// UI can invalidate its list when work actually happened.
class ReceiptResumeController extends Notifier<int> {
  @override
  int build() {
    // Defer so `build` can return synchronously; the sweep needs the database.
    Future.microtask(_resume);
    return 0;
  }

  Future<void> _resume() async {
    final pending = await ref.read(receiptPendingProvider.future);
    final settings = ref.read(settingsProvider);
    final rates = Map<String, double>.from(ref.read(fxRatesProvider).value ?? {});
    rates[settings.baseCurrency] = 1.0;
    final sync = ref.read(budgetSyncServiceProvider);

    var attempted = 0;
    for (final receipt in pending) {
      if (_inFlightReceipts.contains(receipt.id)) continue;
      _inFlightReceipts.add(receipt.id);
      attempted++;
      try {
        await sync.uploadAndParse(
          receipt.id,
          baseCurrency: settings.baseCurrency,
          ratesToBase: rates,
        );
      } catch (_) {
        // The error is already persisted on the row as `error` status; the next
        // sweep will pick it up again.
      } finally {
        _inFlightReceipts.remove(receipt.id);
      }
    }

    if (attempted == 0) return;
    state = attempted;
    ref.invalidate(receiptListProvider);
    ref.invalidate(receiptPendingProvider);
  }
}

final receiptResumeProvider =
    NotifierProvider<ReceiptResumeController, int>(ReceiptResumeController.new);