import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../models/transaction.dart';

/// Reads the transactions the pull brought down. The server owns them: the
/// desktop and the statement imports make them, and the phone never pushes one,
/// so there is nothing here that writes.
final class TransactionRepository {
  final db.AppDatabase _database;
  const TransactionRepository(this._database);

  /// All alive transactions, newest first. [accountId] filters by source
  /// account and [type] filters by transaction type when provided.
  Future<List<Transaction>> getAll({
    String? accountId,
    TransactionType? type,
    bool includeDrafts = true,
  }) async {
    final query = _database.select(_database.transactions);
    query.where((t) => t.deletedAt.isNull());
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }
    if (type != null) {
      query.where((t) => t.type.equals(type.name));
    }
    if (!includeDrafts) {
      query.where((t) => t.isDraft.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<Transaction?> getById(String id) async {
    final row = await (_database.select(
      _database.transactions,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Transactions for a specific account (source or destination), newest first.
  Future<List<Transaction>> getByAccount(String accountId) async {
    final source =
        await (_database.select(_database.transactions)..where(
              (t) => t.accountId.equals(accountId) & t.deletedAt.isNull(),
            ))
            .get();
    final dest =
        await (_database.select(_database.transactions)..where(
              (t) => t.toAccountId.equals(accountId) & t.deletedAt.isNull(),
            ))
            .get();
    final merged = [...source, ...dest];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged.map(_toDomain).toList();
  }

  Future<List<Transaction>> getRecent(int limit) async {
    final rows =
        await (_database.select(_database.transactions)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList();
  }

  Transaction _toDomain(db.Transaction row) => Transaction(
    id: row.id,
    type: TransactionType.fromName(row.type),
    amount: row.amount,
    currencyCode: row.currencyCode,
    amountBase: row.amountBase,
    rateUsed: row.rateUsed,
    accountId: row.accountId,
    toAccountId: row.toAccountId,
    category: row.category,
    date: DateTime.fromMillisecondsSinceEpoch(row.date),
    note: row.note,
    receiptId: row.receiptId,
    isDraft: row.isDraft,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}
