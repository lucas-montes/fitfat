import 'dart:io';

import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../models/receipt.dart';
import 'remote_receipt_ocr.dart';

/// Sends a receipt to the server, then forgets it.
///
/// The phone only photographs and sends. Once the server has accepted the
/// upload it holds the picture, and reads, matches and keeps the receipt on
/// its own, so the phone drops its copy: the image file and the row. Neither is
/// sent as a deletion, which would remove the server's copy too. The phone
/// never waits for the reading and makes nothing from a receipt.
final class BudgetSyncService {
  final db.AppDatabase _database;
  final RemoteReceiptOcrService _ocr;

  const BudgetSyncService(this._database, this._ocr);

  /// Uploads [receiptId], then forgets the receipt locally. On a failure the
  /// row stays, marked `error`, to be sent again.
  Future<void> send(String receiptId) async {
    final receipt = await (_database.select(
      _database.receipts,
    )..where((t) => t.id.equals(receiptId))).getSingleOrNull();
    if (receipt == null) return;

    await (_database.update(
      _database.receipts,
    )..where((t) => t.id.equals(receiptId))).write(
      db.ReceiptsCompanion(uploadStatus: Value(ReceiptStatus.uploading.code)),
    );

    try {
      await _ocr.upload(receiptId, receipt.localPath);
    } catch (_) {
      await (_database.update(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).write(
        db.ReceiptsCompanion(uploadStatus: Value(ReceiptStatus.error.code)),
      );
      rethrow;
    }

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
  }
}
