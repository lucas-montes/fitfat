import '../../models/dashboard.dart';

abstract class ProfileRepository {
  Future<UserProfile?> get();
  Future<void> upsert(UserProfile profile);
}
