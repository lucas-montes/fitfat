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

  /// Today's date as 'YYYY-MM-DD', used as the snapshot key for new rows.
  static String _today() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

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

  /// Latest rate value for a single code/base (max date), or null.
  Future<double?> getRate(String code, String baseCode) async {
    final rows = await (_database.select(
      _database.fxRates,
    )..where((t) => t.code.equals(code) & t.baseCode.equals(baseCode))).get();
    return _latestByCode(rows)[code]?.rateToBase;
  }

  /// Replaces today's rate set for [baseCode] with [rates], stamping now and
  /// clearing the manual flag (a fresh fetch supersedes hand-edited values).
  /// Historical snapshots are left untouched.
  Future<void> replaceAll(String baseCode, Map<String, double> rates) async {
    final today = _today();
    await _database.transaction(() async {
      await (_database.delete(_database.fxRates)..where(
            (t) => t.baseCode.equals(baseCode) & t.rateDate.equals(today),
          ))
          .go();
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
                rateDate: Value(today),
              ),
            );
      }
    });
  }

  /// Hand-edits today's rate for [code]/[baseCode] and marks it manual so a
  /// sync never overwrites the user's override on that day.
  Future<void> setRate(String code, double rate, String baseCode) async {
    final today = _today();
    final existing =
        await (_database.select(_database.fxRates)..where(
              (t) =>
                  t.code.equals(code) &
                  t.baseCode.equals(baseCode) &
                  t.rateDate.equals(today),
            ))
            .getSingleOrNull();
    final companion = db.FxRatesCompanion(
      code: Value(code),
      rateToBase: Value(rate),
      baseCode: Value(baseCode),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      manual: const Value(true),
      rateDate: Value(today),
    );
    if (existing == null) {
      await _database.into(_database.fxRates).insert(companion);
    } else {
      await (_database.update(_database.fxRates)..where(
            (t) =>
                t.code.equals(code) &
                t.baseCode.equals(baseCode) &
                t.rateDate.equals(today),
          ))
          .write(companion);
    }
  }

  /// Upserts a single synced rate for its [FxRateEntry.rateDate], preserving
  /// any locally hand-edited (manual) row for that exact day so a sync never
  /// clobbers a user override.
  Future<void> upsertRate(FxRateEntry rate) async {
    final existing =
        await (_database.select(_database.fxRates)..where(
              (t) =>
                  t.code.equals(rate.code) &
                  t.baseCode.equals(rate.baseCode) &
                  t.rateDate.equals(rate.rateDate),
            ))
            .getSingleOrNull();
    final manual = existing?.manual ?? false;
    final companion = db.FxRatesCompanion(
      code: Value(rate.code),
      rateToBase: Value(rate.rateToBase),
      baseCode: Value(rate.baseCode),
      updatedAt: Value(rate.updatedAt.millisecondsSinceEpoch),
      manual: Value(manual),
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
