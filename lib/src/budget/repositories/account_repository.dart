import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../models/account.dart';

final class AccountRepository {
  final db.AppDatabase _database;
  const AccountRepository(this._database);

  Future<List<Account>> getAll() async {
    final rows =
        await (_database.select(_database.accounts)..orderBy([
              (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<Account?> getById(String id) async {
    final row = await (_database.select(
      _database.accounts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Number of transactions referencing this account (source or destination).
  Future<int> usageCount(String id) async {
    final source = await (_database.select(
      _database.transactions,
    )..where((t) => t.accountId.equals(id))).get();
    final dest = await (_database.select(
      _database.transactions,
    )..where((t) => t.toAccountId.equals(id))).get();
    return source.length + dest.length;
  }

  Future<void> insert(Account account) async {
    await _database
        .into(_database.accounts)
        .insert(
          db.AccountsCompanion.insert(
            id: account.id,
            name: account.name,
            type: account.type.name,
            openingBalance: Value(account.openingBalance),
            note: Value(account.note),
            createdAt: account.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(Account account) async {
    await (_database.update(
      _database.accounts,
    )..where((t) => t.id.equals(account.id))).write(
      db.AccountsCompanion(
        name: Value(account.name),
        type: Value(account.type.name),
        openingBalance: Value(account.openingBalance),
        note: Value(account.note),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.accounts,
    )..where((t) => t.id.equals(id))).go();
  }

  Account _toDomain(db.Account row) => Account(
    id: row.id,
    name: row.name,
    type: AccountType.fromName(row.type),
    openingBalance: row.openingBalance,
    note: row.note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

Account newAccountFrom({
  required String name,
  required AccountType type,
  double openingBalance = 0,
  String? note,
}) => Account(
  id: const Uuid().v7(),
  name: name,
  type: type,
  openingBalance: openingBalance,
  note: note,
  createdAt: DateTime.now(),
);
