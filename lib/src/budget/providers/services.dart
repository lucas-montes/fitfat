import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../database/app_database.dart' as db;
import '../../database/database_provider.dart';
import '../../network/api_client.dart';
import '../../settings/providers/settings.dart';
import '../services/budget_sync.dart';
import '../services/http_remote_receipt_ocr.dart';
import '../services/remote_receipt_ocr.dart';
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
    client: HttpApiClient(http.Client(), baseUrl: baseUrl, timeout: timeout),
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
/// Capture starts `send` as a detached task and swallows its errors,
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
    final sync = ref.read(budgetSyncServiceProvider);

    var attempted = 0;
    for (final receipt in pending) {
      if (_inFlightReceipts.contains(receipt.id)) continue;
      _inFlightReceipts.add(receipt.id);
      attempted++;
      try {
        await sync.send(receipt.id);
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

final receiptResumeProvider = NotifierProvider<ReceiptResumeController, int>(
  ReceiptResumeController.new,
);

/// What sending every receipt on the phone did.
final class ReceiptSendOutcome {
  const ReceiptSendOutcome({
    required this.sent,
    required this.failed,
    required this.noPicture,
    this.firstError,
  });

  final int sent;
  final int failed;

  /// Receipts whose picture is not on the phone, so there is nothing to send.
  final int noPicture;
  final String? firstError;
}

/// Sends every receipt still on the phone, each forgotten once the server
/// accepts it (see [BudgetSyncService.send]). Shares the in-flight guard with
/// the resume sweep, so a receipt is never uploaded twice at once.
///
/// [onProgress] is called once with `(0, total)` and then after every receipt,
/// so a screen can show "sending 2 of 5" without guessing.
Future<ReceiptSendOutcome> sendAllReceipts(
  db.AppDatabase database,
  BudgetSyncService sync, {
  void Function(int done, int total)? onProgress,
}) async {
  final rows = await (database.select(
    database.receipts,
  )..where((t) => t.deletedAt.isNull())).get();
  return _sendRows(sync, rows, onProgress: onProgress);
}

/// Sends only [ids], leaving every other receipt alone.
///
/// Used by the receipts screen when the user picks a subset (or captures a new
/// batch). Unknown, tombstoned and already-sent ids are simply skipped.
Future<ReceiptSendOutcome> sendReceipts(
  db.AppDatabase database,
  BudgetSyncService sync,
  Iterable<String> ids, {
  void Function(int done, int total)? onProgress,
}) async {
  final wanted = ids.toSet();
  if (wanted.isEmpty) {
    onProgress?.call(0, 0);
    return const ReceiptSendOutcome(sent: 0, failed: 0, noPicture: 0);
  }
  final rows = await (database.select(
    database.receipts,
  )..where((t) => t.deletedAt.isNull() & t.id.isIn(wanted))).get();
  return _sendRows(sync, rows, onProgress: onProgress);
}

Future<ReceiptSendOutcome> _sendRows(
  BudgetSyncService sync,
  List<db.Receipt> rows, {
  void Function(int done, int total)? onProgress,
}) async {
  var sent = 0;
  var failed = 0;
  var noPicture = 0;
  String? firstError;
  final total = rows.length;
  var done = 0;
  onProgress?.call(0, total);
  for (final row in rows) {
    if (row.localPath.isEmpty || !await File(row.localPath).exists()) {
      noPicture++;
    } else if (_inFlightReceipts.add(row.id)) {
      try {
        await sync.send(row.id);
        sent++;
      } catch (e) {
        failed++;
        firstError ??= '$e';
      } finally {
        _inFlightReceipts.remove(row.id);
      }
    }
    done++;
    onProgress?.call(done, total);
  }
  return ReceiptSendOutcome(
    sent: sent,
    failed: failed,
    noPicture: noPicture,
    firstError: firstError,
  );
}
