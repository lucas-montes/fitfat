import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;

final class FxRepository {
  final db.AppDatabase _database;
  const FxRepository(this._database);

  /// All cached rates for a given base currency, as a code -> rate map.
  Future<Map<String, double>> getRates(String baseCode) async {
    final rows = await (_database.select(
      _database.fxRates,
    )..where((t) => t.baseCode.equals(baseCode))).get();
    return {for (final r in rows) r.code: r.rateToBase};
  }

  Future<double?> getRate(String code, String baseCode) async {
    final row = await (_database.select(
      _database.fxRates,
    )..where((t) => t.code.equals(code) & t.baseCode.equals(baseCode)))
        .getSingleOrNull();
    return row?.rateToBase;
  }

  /// Replaces the full rate set for [baseCode] with [rates], stamping now.
  Future<void> replaceAll(String baseCode, Map<String, double> rates) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.fxRates,
      )..where((t) => t.baseCode.equals(baseCode))).go();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in rates.entries) {
        await _database.into(_database.fxRates).insert(
              db.FxRatesCompanion.insert(
                code: entry.key,
                rateToBase: entry.value,
                baseCode: baseCode,
                updatedAt: now,
              ),
            );
      }
    });
  }

  /// Updates a single cached rate (keeps the existing base code).
  Future<void> setRate(String code, double rate, String baseCode) async {
    final existing = await getRate(code, baseCode);
    final companion = db.FxRatesCompanion(
      code: Value(code),
      rateToBase: Value(rate),
      baseCode: Value(baseCode),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    if (existing == null) {
      await _database.into(_database.fxRates).insert(companion);
    } else {
      await (_database.update(
        _database.fxRates,
      )..where((t) => t.code.equals(code) & t.baseCode.equals(baseCode)))
          .write(companion);
    }
  }
}
