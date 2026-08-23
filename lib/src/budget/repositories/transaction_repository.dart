import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../models/transaction.dart';

final class TransactionRepository {
  final db.AppDatabase _database;
  const TransactionRepository(this._database);

  /// All transactions, newest first. [accountId] filters by source account and
  /// [type] filters by transaction type when provided.
  Future<List<Transaction>> getAll({
    String? accountId,
    TransactionType? type,
    bool includeDrafts = true,
  }) async {
    final query = _database.select(_database.transactions);
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
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Transactions for a specific account (source or destination), newest first.
  Future<List<Transaction>> getByAccount(String accountId) async {
    final source = await (_database.select(
      _database.transactions,
    )..where((t) => t.accountId.equals(accountId))).get();
    final dest = await (_database.select(
      _database.transactions,
    )..where((t) => t.toAccountId.equals(accountId))).get();
    final merged = [...source, ...dest];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged.map(_toDomain).toList();
  }

  Future<List<Transaction>> getRecent(int limit) async {
    final rows =
        await (_database.select(_database.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> insert(Transaction txn) async {
    await _database
        .into(_database.transactions)
        .insert(
          db.TransactionsCompanion.insert(
            id: txn.id,
            type: txn.type.name,
            amount: txn.amount,
            currencyCode: txn.currencyCode,
            amountBase: txn.amountBase,
            rateUsed: txn.rateUsed,
            accountId: Value(txn.accountId),
            toAccountId: Value(txn.toAccountId),
            category: Value(txn.category),
            date: txn.date.millisecondsSinceEpoch,
            note: Value(txn.note),
            receiptId: Value(txn.receiptId),
            isDraft: Value(txn.isDraft),
            createdAt: txn.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(Transaction txn) async {
    await (_database.update(
      _database.transactions,
    )..where((t) => t.id.equals(txn.id))).write(
      db.TransactionsCompanion(
        type: Value(txn.type.name),
        amount: Value(txn.amount),
        currencyCode: Value(txn.currencyCode),
        amountBase: Value(txn.amountBase),
        rateUsed: Value(txn.rateUsed),
        accountId: Value(txn.accountId),
        toAccountId: Value(txn.toAccountId),
        category: Value(txn.category),
        date: Value(txn.date.millisecondsSinceEpoch),
        note: Value(txn.note),
        receiptId: Value(txn.receiptId),
        isDraft: Value(txn.isDraft),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.transactions,
    )..where((t) => t.id.equals(id))).go();
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
