import '../../database/app_database.dart';
import '../../dashboard/repositories/profile.dart';
import '../../models/dashboard_models.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db);

  final AppDatabase _db;

  @override
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

  @override
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
