import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;

/// One cached rate with provenance for display in the FX settings section.
final class FxRateEntry {
  const FxRateEntry({
    required this.code,
    required this.rateToBase,
    required this.updatedAt,
    required this.manual,
  });

  final String code;
  final double rateToBase;
  final DateTime updatedAt;
  final bool manual;
}

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

  /// Cached rates for [baseCode] with full provenance, for display: the
  /// rate, when it was last updated, and whether it was set by hand.
  Future<List<FxRateEntry>> getRateEntries(String baseCode) async {
    final rows = await (_database.select(
      _database.fxRates,
    )..where((t) => t.baseCode.equals(baseCode))).get();
    return [
      for (final r in rows)
        FxRateEntry(
          code: r.code,
          rateToBase: r.rateToBase,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
          manual: r.manual,
        ),
    ];
  }

  Future<double?> getRate(String code, String baseCode) async {
    final row =
        await (_database.select(_database.fxRates)
              ..where((t) => t.code.equals(code) & t.baseCode.equals(baseCode)))
            .getSingleOrNull();
    return row?.rateToBase;
  }

  /// Replaces the full rate set for [baseCode] with [rates], stamping now and
  /// clearing the manual flag (a fresh fetch supersedes hand-edited values).
  Future<void> replaceAll(String baseCode, Map<String, double> rates) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.fxRates,
      )..where((t) => t.baseCode.equals(baseCode))).go();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in rates.entries) {
        await _database
            .into(_database.fxRates)
            .insert(
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

  /// Updates a single cached rate (keeps the existing base code) and stamps
  /// it as hand-edited (v19).
  Future<void> setRate(String code, double rate, String baseCode) async {
    final existing = await getRate(code, baseCode);
    final companion = db.FxRatesCompanion(
      code: Value(code),
      rateToBase: Value(rate),
      baseCode: Value(baseCode),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      manual: const Value(true),
    );
    if (existing == null) {
      await _database.into(_database.fxRates).insert(companion);
    } else {
      await (_database.update(_database.fxRates)
            ..where((t) => t.code.equals(code) & t.baseCode.equals(baseCode)))
          .write(companion);
    }
  }
}
