import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/app_database.dart';
import '../../models/dashboard_models.dart';
import '../interfaces/goal_repository.dart';

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<void> upsertBodyWeight(BodyWeightGoal goal) async {
    // Delete any existing bodyweight goal, then insert the new one
    await (_db.delete(
      _db.goals,
    )..where((t) => t.type.equals('bodyweight'))).go();
    await _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            id: _uuid.v4(),
            type: 'bodyweight',
            targetWeightKg: goal.targetWeightKg,
            direction: Value(_directionToString(goal.direction)),
            targetDate: Value(goal.targetDate),
          ),
        );
  }

  @override
  Future<void> clearBodyWeight() async {
    await (_db.delete(
      _db.goals,
    )..where((t) => t.type.equals('bodyweight'))).go();
  }

  @override
  Future<void> addStrength(StrengthGoal goal) async {
    // Enforce one per exercise — delete existing with same name first
    await (_db.delete(_db.goals)..where(
          (t) =>
              t.type.equals('strength') &
              t.exerciseName.equals(goal.exerciseName),
        ))
        .go();
    await _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            id: _uuid.v4(),
            type: 'strength',
            exerciseName: Value(goal.exerciseName),
            targetWeightKg: goal.targetWeightKg,
            targetDate: Value(goal.targetDate),
          ),
        );
  }

  @override
  Future<void> updateStrength(String exerciseName, StrengthGoal goal) async {
    await (_db.delete(_db.goals)..where(
          (t) =>
              t.type.equals('strength') & t.exerciseName.equals(exerciseName),
        ))
        .go();
    await _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            id: _uuid.v4(),
            type: 'strength',
            exerciseName: Value(goal.exerciseName),
            targetWeightKg: goal.targetWeightKg,
            targetDate: Value(goal.targetDate),
          ),
        );
  }

  @override
  Future<void> removeStrength(String exerciseName) async {
    await (_db.delete(_db.goals)..where(
          (t) =>
              t.type.equals('strength') & t.exerciseName.equals(exerciseName),
        ))
        .go();
  }

  @override
  Future<GoalsData> loadAll() async {
    final rows = await _db.select(_db.goals).get();
    BodyWeightGoal? bwGoal;
    final strengthGoals = <StrengthGoal>[];

    for (final row in rows) {
      if (row.type == 'bodyweight') {
        bwGoal = BodyWeightGoal(
          targetWeightKg: row.targetWeightKg,
          direction: _parseDirection(row.direction),
          targetDate: row.targetDate,
        );
      } else if (row.type == 'strength' && row.exerciseName != null) {
        strengthGoals.add(
          StrengthGoal(
            exerciseName: row.exerciseName!,
            targetWeightKg: row.targetWeightKg,
            targetDate: row.targetDate,
          ),
        );
      }
    }

    return GoalsData(bodyWeightGoal: bwGoal, strengthGoals: strengthGoals);
  }

  BodyWeightDirection _parseDirection(String? value) {
    switch (value) {
      case 'gain':
        return BodyWeightDirection.gain;
      case 'lose':
        return BodyWeightDirection.lose;
      case 'maintain':
        return BodyWeightDirection.maintain;
      default:
        return BodyWeightDirection.maintain;
    }
  }

  String _directionToString(BodyWeightDirection d) => d.name;
}
