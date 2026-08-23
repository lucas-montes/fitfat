import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../models/receipt.dart';
import '../models/transaction.dart';
import 'currency.dart';
import 'remote_receipt_ocr.dart';

/// Orchestrates the remote lifecycle of a receipt: upload the local image,
/// persist the remote path, fetch the parsed OCR result, and — when no
/// transaction is linked yet — create a draft expense pre-filled from the
/// parsed data for the user to review, link an account, and confirm.
final class BudgetSyncService {
  final db.AppDatabase _database;
  final RemoteReceiptOcrService _ocr;

  const BudgetSyncService(this._database, this._ocr);

  /// Uploads [receiptId] and, once uploaded, fetches + stores the parsed
  /// result. If the receipt has no linked transaction yet, a draft expense is
  /// created from the parsed fields. [baseCurrency] and [ratesToBase] are used
  /// to convert the parsed amount to the base currency.
  Future<void> uploadAndParse(
    String receiptId, {
    required String baseCurrency,
    required Map<String, double> ratesToBase,
  }) async {
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
      final uploaded = await _ocr.upload(receipt.localPath);
      await (_database.update(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).write(
        db.ReceiptsCompanion(
          remotePath: Value(uploaded.remotePath),
          uploadStatus: Value(ReceiptStatus.uploaded.code),
        ),
      );

      final parsed = await _ocr.fetchParse(uploaded.remotePath);
      final json = parsed.data;
      final jsonString = jsonEncode(json);

      // If a transaction was already created from this receipt, just store JSON.
      final existing = await (_database.select(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).getSingleOrNull();

      await (_database.update(
        _database.receipts,
      )..where((t) => t.id.equals(receiptId))).write(
        db.ReceiptsCompanion(
          parsed: const Value(true),
          parsedJson: Value(jsonString),
        ),
      );

      if (existing?.transactionId == null) {
        await _createDraftFromParsed(
          receiptId,
          json,
          baseCurrency: baseCurrency,
          ratesToBase: ratesToBase,
        );
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

  Future<void> _createDraftFromParsed(
    String receiptId,
    Map<String, Object?> json, {
    required String baseCurrency,
    required Map<String, double> ratesToBase,
  }) async {
    final total = (json['total'] is num)
        ? (json['total'] as num).toDouble()
        : 0.0;
    final currency = (json['currency'] as String?) ?? baseCurrency;
    final (amountBase, rateUsed) = convertToBase(
      total,
      currency,
      baseCurrency,
      ratesToBase,
    );
    final date = _parseDate(json['date'] as String?);

    final txnId = const Uuid().v7();
    await _database
        .into(_database.transactions)
        .insert(
          db.TransactionsCompanion.insert(
            id: txnId,
            type: TransactionType.expense.name,
            amount: total,
            currencyCode: currency,
            amountBase: amountBase,
            rateUsed: rateUsed,
            accountId: const Value<String?>(null),
            category: Value(json['merchant'] as String?),
            date: date.millisecondsSinceEpoch,
            note: const Value('Parsed from receipt'),
            receiptId: Value(receiptId),
            isDraft: const Value(true),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

    await (_database.update(_database.receipts)
          ..where((t) => t.id.equals(receiptId)))
        .write(db.ReceiptsCompanion(transactionId: Value(txnId)));
  }

  DateTime _parseDate(String? raw) {
    if (raw == null) return DateTime.now();
    final parsed = DateTime.tryParse(raw);
    return parsed ?? DateTime.now();
  }
}
