import 'dart:io';

import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../models/receipt.dart';
import 'remote_receipt_ocr.dart';

/// Orchestrates the remote lifecycle of a receipt: upload the local image,
/// persist the remote path, and wait for the server to parse it. Once parsed, the
/// server holds the picture and the parse, so the phone drops its own copy: the
/// image file and the row. Neither is sent as a deletion, which would remove
/// the server's copy too. The phone makes no transaction from a receipt.
final class BudgetSyncService {
  final db.AppDatabase _database;
  final RemoteReceiptOcrService _ocr;

  const BudgetSyncService(this._database, this._ocr);

  /// Uploads [receiptId], waits for the server's parse, then forgets the
  /// receipt locally. On a failure the row stays, marked `error`, to be retried.
  Future<void> uploadAndParse(String receiptId) async {
    final receipt = await (_database.select(
      _database.receipts,
    )..where((t) => t.id.equals(receiptId))).getSingleOrNull();
    if (receipt == null) return;

    // Mark uploading.
    await (_database.update(
      _database.receipts,
    )..where((t) => t.id.equals(receiptId))).write(
      db.ReceiptsCompanion(uploadStatus: Value(ReceiptStatus.uploading.code)),
    );

    try {
      final uploaded = await _ocr.upload(receiptId, receipt.localPath);
      // The server answers 202 immediately and parses in the background, so the
      // row is `parsing` until the poll returns.
      await (_database.update(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).write(
        db.ReceiptsCompanion(
          remotePath: Value(uploaded.remotePath),
          uploadStatus: Value(ReceiptStatus.parsing.code),
        ),
      );

      await _ocr.fetchParse(uploaded.remotePath);

      // The server has it now. A hard delete, never a tombstone: a tombstone
      // is pushed, and would delete the server's copy.
      await (_database.delete(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).go();
      try {
        await File(receipt.localPath).delete();
      } on FileSystemException {
        // Already gone; the row was what mattered.
      }
    } catch (_) {
      await (_database.update(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).write(
        db.ReceiptsCompanion(uploadStatus: Value(ReceiptStatus.error.code)),
      );
      rethrow;
    }
  }
}
