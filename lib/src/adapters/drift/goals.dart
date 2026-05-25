import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../models/dashboard.dart';

class DriftGoalRepository {
  DriftGoalRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<void> upsertBodyWeight(BodyWeightGoal goal) async {
    await (_db.delete(_db.goals)..where((table) => table.type.equals('bodyweight'))).go();
    await _db.into(_db.goals).insert(
      GoalsCompanion.insert(
        id: _uuid.v7(),
        type: 'bodyweight',
        targetWeightKg: goal.targetWeightKg,
        direction: Value(_directionToString(goal.direction)),
        targetDate: Value(goal.targetDate),
      ),
    );
  }

  Future<void> clearBodyWeight() async {
    await (_db.delete(_db.goals)..where((table) => table.type.equals('bodyweight'))).go();
  }

  Future<void> addStrength(StrengthGoal goal) async {
    await (_db.delete(_db.goals)..where(
      (table) => table.type.equals('strength') & table.exerciseName.equals(goal.exerciseName),
    )).go();
    await _db.into(_db.goals).insert(
      GoalsCompanion.insert(
        id: _uuid.v7(),
        type: 'strength',
        exerciseName: Value(goal.exerciseName),
        targetWeightKg: goal.targetWeightKg,
        targetDate: Value(goal.targetDate),
      ),
    );
  }

  Future<void> updateStrength(String exerciseName, StrengthGoal goal) async {
    await (_db.delete(_db.goals)..where(
      (table) => table.type.equals('strength') & table.exerciseName.equals(exerciseName),
    )).go();
    await _db.into(_db.goals).insert(
      GoalsCompanion.insert(
        id: _uuid.v7(),
        type: 'strength',
        exerciseName: Value(goal.exerciseName),
        targetWeightKg: goal.targetWeightKg,
        targetDate: Value(goal.targetDate),
      ),
    );
  }

  Future<void> removeStrength(String exerciseName) async {
    await (_db.delete(_db.goals)..where(
      (table) => table.type.equals('strength') & table.exerciseName.equals(exerciseName),
    )).go();
  }

  Future<GoalsData> loadAll() async {
    final rows = await _db.select(_db.goals).get();
    BodyWeightGoal? bodyWeightGoal;
    final strengthGoals = <StrengthGoal>[];

    for (final row in rows) {
      if (row.type == 'bodyweight') {
        bodyWeightGoal = BodyWeightGoal(
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

    return GoalsData(bodyWeightGoal: bodyWeightGoal, strengthGoals: strengthGoals);
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

  String _directionToString(BodyWeightDirection direction) => direction.name;
}
