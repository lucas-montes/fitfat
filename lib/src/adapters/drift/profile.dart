import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../models/dashboard.dart';

class DriftProfileRepository {
  DriftProfileRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<UserProfile?> get() async {
    final row = await _db.watchProfile().first;
    if (row == null) return null;

    // Compute average weight from last 7 body weight entries
    final allWeights = await _db.watchBodyWeight().first;
    final sorted = List<BodyWeightEntry>.from(allWeights)
      ..sort((a, b) => b.date.compareTo(a.date));
    final last7 = sorted.take(7).toList();
    final avgWeight = last7.isEmpty
        ? 0.0
        : last7.fold<double>(0, (sum, e) => sum + e.weightKg) / last7.length;

    return UserProfile(
      birthDate: row.birthDate,
      gender: row.gender,
      heightCm: row.heightCm,
      weightKg: avgWeight,
      activityLevel: _parseActivity(row.activityLevel),
    );
  }

  Future<void> upsert(UserProfile profile) async {
    // Reuse existing ID if profile already exists; otherwise generate UUID v7
    final existing = await _db.watchProfile().first;
    final id = existing?.id ?? _uuid.v7();
    await _db.upsertProfile(
      UserProfileCompanion.insert(
        id: id,
        birthDate: profile.birthDate,
        gender: profile.gender,
        heightCm: profile.heightCm,
        activityLevel: profile.activityLevel.name,
      ),
    );
  }

  ActivityLevel _parseActivity(String value) {
    return ActivityLevel.values.firstWhere(
      (activity) => activity.name == value,
      orElse: () => ActivityLevel.moderate,
    );
  }
}
