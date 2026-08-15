import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../models/receipt.dart';

final class ReceiptRepository {
  final db.AppDatabase _database;
  const ReceiptRepository(this._database);

  Future<List<Receipt>> getAll() async {
    final rows = await (_database.select(_database.receipts)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<Receipt?> getById(String id) async {
    final row = await (_database.select(
      _database.receipts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Receipts whose linked transaction belongs to [accountId] (source or
  /// destination) — used by the account detail screen.
  Future<List<Receipt>> getByAccount(String accountId) async {
    final txns = await (_database.select(_database.transactions)
          ..where(
            (t) =>
                t.accountId.equals(accountId) |
                t.toAccountId.equals(accountId),
          ))
        .get();
    if (txns.isEmpty) return const [];
    final ids = txns.map((t) => t.receiptId).whereType<String>().toList();
    if (ids.isEmpty) return const [];
    final rows = await (_database.select(_database.receipts)
          ..where((t) => t.id.isIn(ids)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<Receipt> insert(Receipt receipt) async {
    await _database.into(_database.receipts).insert(
          db.ReceiptsCompanion.insert(
            id: receipt.id,
            localPath: receipt.localPath,
            remotePath: Value(receipt.remotePath),
            uploadStatus: Value(receipt.status.code),
            parsed: Value(receipt.parsed),
            parsedJson: Value(receipt.parsedJson),
            transactionId: Value(receipt.transactionId),
            createdAt: receipt.createdAt.millisecondsSinceEpoch,
          ),
        );
    return receipt;
  }

  Future<void> update(Receipt receipt) async {
    await (_database.update(
      _database.receipts,
    )..where((t) => t.id.equals(receipt.id))).write(
      db.ReceiptsCompanion(
        localPath: Value(receipt.localPath),
        remotePath: Value(receipt.remotePath),
        uploadStatus: Value(receipt.status.code),
        parsed: Value(receipt.parsed),
        parsedJson: Value(receipt.parsedJson),
        transactionId: Value(receipt.transactionId),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.receipts,
    )..where((t) => t.id.equals(id))).go();
  }

  Receipt _toDomain(db.Receipt row) => Receipt(
        id: row.id,
        localPath: row.localPath,
        remotePath: row.remotePath,
        status: ReceiptStatus.fromCode(row.uploadStatus),
        parsed: row.parsed,
        parsedJson: row.parsedJson,
        transactionId: row.transactionId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );
}
