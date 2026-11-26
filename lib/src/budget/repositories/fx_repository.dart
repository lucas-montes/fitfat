import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;

/// One cached rate with provenance for display in the FX settings section.
/// [rateDate] is the day the rate applies to ('YYYY-MM-DD'); with daily
/// snapshots the "latest" rate for a currency is the row with the max date.
final class FxRateEntry {
  const FxRateEntry({
    required this.code,
    required this.rateToBase,
    required this.updatedAt,
    required this.manual,
    required this.baseCode,
    required this.rateDate,
  });

  final String code;
  final double rateToBase;
  final DateTime updatedAt;
  final bool manual;
  final String baseCode;
  final String rateDate;
}

final class FxRepository {
  final db.AppDatabase _database;
  const FxRepository(this._database);

  /// Reduces a set of rows to the latest per currency code (max [db.FxRate.
  /// rateDate]).
  static Map<String, db.FxRate> _latestByCode(List<db.FxRate> rows) {
    final map = <String, db.FxRate>{};
    for (final r in rows) {
      final cur = map[r.code];
      if (cur == null || r.rateDate.compareTo(cur.rateDate) > 0) {
        map[r.code] = r;
      }
    }
    return map;
  }

  /// Latest cached rate per code for [baseCode], as a code -> rate map.
  Future<Map<String, double>> getRates(String baseCode) async {
    final rows = await (_database.select(
      _database.fxRates,
    )..where((t) => t.baseCode.equals(baseCode))).get();
    final latest = _latestByCode(rows);
    return {for (final e in latest.entries) e.key: e.value.rateToBase};
  }

  /// Latest cached rates for [baseCode] with full provenance, for display: the
  /// rate, the day it applies to, when it was last updated, and whether it was
  /// set by hand.
  Future<List<FxRateEntry>> getRateEntries(String baseCode) async {
    final rows = await (_database.select(
      _database.fxRates,
    )..where((t) => t.baseCode.equals(baseCode))).get();
    final latest = _latestByCode(rows);
    return [
      for (final r in latest.values)
        FxRateEntry(
          code: r.code,
          rateToBase: r.rateToBase,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
          manual: r.manual,
          baseCode: baseCode,
          rateDate: r.rateDate,
        ),
    ];
  }

  /// Upserts a single synced rate for its [FxRateEntry.rateDate]. The server is
  /// the only source of rates, so what it sends always replaces the local copy
  /// (including a hand-edited row left over from when rates were editable).
  Future<void> upsertRate(FxRateEntry rate) async {
    final existing =
        await (_database.select(_database.fxRates)..where(
              (t) =>
                  t.code.equals(rate.code) &
                  t.baseCode.equals(rate.baseCode) &
                  t.rateDate.equals(rate.rateDate),
            ))
            .getSingleOrNull();
    final companion = db.FxRatesCompanion(
      code: Value(rate.code),
      rateToBase: Value(rate.rateToBase),
      baseCode: Value(rate.baseCode),
      updatedAt: Value(rate.updatedAt.millisecondsSinceEpoch),
      manual: const Value(false),
      rateDate: Value(rate.rateDate),
    );
    if (existing == null) {
      await _database.into(_database.fxRates).insert(companion);
    } else {
      await (_database.update(_database.fxRates)..where(
            (t) =>
                t.code.equals(rate.code) &
                t.baseCode.equals(rate.baseCode) &
                t.rateDate.equals(rate.rateDate),
          ))
          .write(companion);
    }
  }
}
