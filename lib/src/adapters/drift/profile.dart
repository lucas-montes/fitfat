import '../../database/app_database.dart';
import '../../models/dashboard.dart';

class DriftProfileRepository {
  DriftProfileRepository(this._db);

  final AppDatabase _db;

  Future<UserProfile?> get() async {
    final row = await _db.watchProfile().first;
    if (row == null) return null;
    return UserProfile(
      birthDate: row.birthDate,
      sex: row.sex == 'male' ? Sex.male : Sex.female,
      heightCm: row.heightCm,
      weightKg: row.weightKg,
      activityLevel: _parseActivity(row.activityLevel),
    );
  }

  Future<void> upsert(UserProfile profile) async {
    await _db.upsertProfile(
      UserProfileCompanion.insert(
        id: 'default',
        birthDate: profile.birthDate,
        sex: profile.sex == Sex.male ? 'male' : 'female',
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
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
