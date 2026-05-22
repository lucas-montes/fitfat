import '../../database/app_database.dart';
import '../../models/dashboard_models.dart';
import '../interfaces/goal_repository.dart';

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  // ignore: unused_field - will be used when full goal DB migration is done
  final AppDatabase _db;

  @override
  Future<void> upsertBodyWeight(BodyWeightGoal goal) async {
    // TODO: implement when goals tables are connected to providers
  }

  @override
  Future<void> addStrength(StrengthGoal goal) async {}

  @override
  Future<void> updateStrength(String exerciseName, StrengthGoal goal) async {}

  @override
  Future<void> removeStrength(String exerciseName) async {}

  @override
  Future<void> clearBodyWeight() async {}

  @override
  Future<GoalsData> loadAll() async => const GoalsData();
}
