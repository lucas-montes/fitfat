import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/body_metrics_entry.dart';
import '../repositories/body_metrics_repository.dart';

final bodyMetricsRepositoryProvider = Provider<BodyMetricsRepository>((ref) {
  return BodyMetricsRepository(ref.watch(databaseProvider));
});

/// All body metrics entries ordered chronologically by day (chart-ready).
final bodyMetricsProvider = FutureProvider<List<BodyMetricsEntry>>((ref) {
  return ref.watch(bodyMetricsRepositoryProvider).getAll();
});

/// The most recent body metrics entry, or `null` when none exist.
final latestBodyMetricsProvider = FutureProvider<BodyMetricsEntry?>((ref) {
  return ref.watch(bodyMetricsRepositoryProvider).getLatest();
});
