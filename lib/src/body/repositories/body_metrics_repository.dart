import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/body_metrics_entry.dart';

final class BodyMetricsRepository {
  final db.AppDatabase _database;
  const BodyMetricsRepository(this._database);

  /// All entries ordered chronologically by day (oldest first) — chart-ready.
  Future<List<BodyMetricsEntry>> getAll() async {
    final rows = await (_database.select(
      _database.bodyMetrics,
    )..orderBy([(t) => OrderingTerm(expression: t.date)])).get();
    return rows.map(_toDomain).toList();
  }

  /// The most recent entry by day, or `null` when no entries exist.
  Future<BodyMetricsEntry?> getLatest() async {
    final row =
        await (_database.select(_database.bodyMetrics)
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  /// Upserts the entry for [day]: a non-null `weightKg`/`heightCm` writes that
  /// metric for the day; a null argument leaves that metric unchanged (so
  /// adding height never wipes an existing weight and vice versa).
  Future<void> upsert(
    DateTime day, {
    double? weightKg,
    double? heightCm,
  }) async {
    final startOfDay = _startOfDay(day);
    final existing =
        await (_database.select(_database.bodyMetrics)
              ..where((t) => t.date.equals(startOfDay.millisecondsSinceEpoch)))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.bodyMetrics)
          .insert(
            db.BodyMetricsCompanion.insert(
              id: const Uuid().v7(),
              date: startOfDay.millisecondsSinceEpoch,
              weightKg: Value(weightKg),
              heightCm: Value(heightCm),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      return;
    }

    await (_database.update(
      _database.bodyMetrics,
    )..where((t) => t.id.equals(existing.id))).write(
      db.BodyMetricsCompanion(
        weightKg: weightKg == null ? const Value.absent() : Value(weightKg),
        heightCm: heightCm == null ? const Value.absent() : Value(heightCm),
      ),
    );
  }

  BodyMetricsEntry _toDomain(db.BodyMetric row) => BodyMetricsEntry(
    id: row.id,
    day: DateTime.fromMillisecondsSinceEpoch(row.date),
    weightKg: row.weightKg,
    heightCm: row.heightCm,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  /// Normalizes any [DateTime] to the start of its day so every day is a
  /// stable key, matching how `date` is stored.
  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);
}
