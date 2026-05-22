import '../../models/dashboard_models.dart';

abstract class ProfileRepository {
  Future<UserProfile?> get();
  Future<void> upsert(UserProfile profile);
}
