import '../../models/dashboard_models.dart';

abstract class GoalRepository {
  Future<void> upsertBodyWeight(BodyWeightGoal goal);
  Future<void> addStrength(StrengthGoal goal);
  Future<void> updateStrength(String exerciseName, StrengthGoal goal);
  Future<void> removeStrength(String exerciseName);
  Future<void> clearBodyWeight();
  Future<GoalsData> loadAll();
}
