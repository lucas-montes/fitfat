import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../models/account.dart';

/// Reads the accounts the pull brought down. The server owns them: the
/// desktop and the statement imports make them, and the phone never pushes one
/// back, so there is nothing here that writes.
final class AccountRepository {
  final db.AppDatabase _database;
  const AccountRepository(this._database);

  Future<List<Account>> getAll() async {
    final rows =
        await (_database.select(_database.accounts)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
              ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<Account?> getById(String id) async {
    final row = await (_database.select(
      _database.accounts,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : _toDomain(row);
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
