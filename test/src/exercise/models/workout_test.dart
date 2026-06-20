import 'package:flutter_test/flutter_test.dart';
import 'package:fitfat/src/models/workout.dart';

void main() {
  group('ExerciseType', () {
    test('has weightlifting and cardio values', () {
      expect(ExerciseType.values, contains(ExerciseType.weightlifting));
      expect(ExerciseType.values, contains(ExerciseType.cardio));
    });
  });

  group('Workout', () {
    test('isFreeform returns true when scheduledDate is null', () {
      final workout = Workout(
        id: '1',
        name: 'Quick Workout',
        startedAt: DateTime.now(),
      );
      expect(workout.isFreeform, isTrue);
      expect(workout.isScheduled, isFalse);
    });

    test('isScheduled returns true when scheduledDate is set', () {
      final workout = Workout(
        id: '1',
        name: 'Push Day',
        scheduledDate: DateTime.now(),
      );
      expect(workout.isScheduled, isTrue);
      expect(workout.isFreeform, isFalse);
    });

    test('isPending when scheduled but not started', () {
      final workout = Workout(
        id: '1',
        name: 'Push Day',
        scheduledDate: DateTime.now(),
        startedAt: null,
      );
      expect(workout.isPending, isTrue);
      expect(workout.isActive, isFalse);
    });

    test('isActive when started but not completed', () {
      final workout = Workout(
        id: '1',
        name: 'Workout',
        startedAt: DateTime.now(),
        completedAt: null,
      );
      expect(workout.isActive, isTrue);
      expect(workout.isCompleted, isFalse);
    });

    test('isCompleted when completedAt is set', () {
      final workout = Workout(
        id: '1',
        name: 'Done',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      expect(workout.isCompleted, isTrue);
    });

    test('duration returns zero for not started', () {
      final workout = Workout(id: '1', name: 'Never started');
      expect(workout.duration, Duration.zero);
    });

    test('duration returns elapsed for active workout', () {
      final now = DateTime.now();
      final workout = Workout(
        id: '1',
        name: 'Active',
        startedAt: now.subtract(const Duration(minutes: 30)),
      );
      expect(workout.duration.inMinutes, greaterThanOrEqualTo(30));
    });

    test('duration returns fixed value for completed workout', () {
      final start = DateTime(2026, 6, 17, 10, 0);
      final end = DateTime(2026, 6, 17, 10, 45);
      final workout = Workout(
        id: '1',
        name: 'Done',
        startedAt: start,
        completedAt: end,
      );
      expect(workout.duration.inMinutes, 45);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Workout(
        id: '1',
        name: 'Test',
        scheduledDate: DateTime(2026, 6, 17),
        startedAt: null,
        completedAt: null,
        source: WorkoutSource.manual,
      );
      final copy = original.copyWith(name: 'Updated');
      expect(copy.id, '1');
      expect(copy.name, 'Updated');
      expect(copy.scheduledDate, original.scheduledDate);
    });

    test('copyWith clear flags work', () {
      final original = Workout(
        id: '1',
        name: 'Test',
        scheduledDate: DateTime(2026, 6, 17),
        notes: 'Some notes',
      );
      final cleared = original.copyWith(
        clearScheduledDate: true,
        clearNotes: true,
      );
      expect(cleared.scheduledDate, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.name, 'Test');
    });
  });

  group('WeightSet', () {
    test('isCompleted returns false when completedAt is null', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
      );
      expect(set.isCompleted, isFalse);
    });

    test('isCompleted returns true when completedAt is set', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
        actualReps: 10,
        actualWeightKg: 50,
        completedAt: DateTime.now(),
      );
      expect(set.isCompleted, isTrue);
    });

    test('effectiveReps uses actual when available', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
        actualReps: 12,
        actualWeightKg: 52.5,
      );
      expect(set.effectiveReps, 12);
      expect(set.effectiveWeightKg, 52.5);
    });

    test('effectiveReps falls back to planned when actual is null', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
      );
      expect(set.effectiveReps, 10);
      expect(set.effectiveWeightKg, 50);
    });

    test('totalWeight calculates effectiveReps * effectiveWeightKg', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
        actualReps: 12,
        actualWeightKg: 55,
      );
      expect(set.totalWeight, 660);
    });

    test('repsDelta is null when not completed', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
      );
      expect(set.repsDelta, isNull);
      expect(set.weightDelta, isNull);
    });

    test('repsDelta is computed when actual is set', () {
      final set = WeightSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedReps: 10,
        plannedWeightKg: 50,
        actualReps: 12,
        actualWeightKg: 52.5,
      );
      expect(set.repsDelta, 2);
      expect(set.weightDelta, 2.5);
    });
  });

  group('CardioSet', () {
    test('isCompleted returns false initially', () {
      final set = CardioSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedDurationMinutes: 30,
      );
      expect(set.isCompleted, isFalse);
    });

    test('effectiveDurationMinutes uses actual when available', () {
      final set = CardioSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedDurationMinutes: 30,
        actualDurationMinutes: 35,
      );
      expect(set.effectiveDurationMinutes, 35);
    });

    test('effectiveDurationMinutes falls back to planned', () {
      final set = CardioSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedDurationMinutes: 30,
      );
      expect(set.effectiveDurationMinutes, 30);
    });

    test('durationDelta is null when not completed', () {
      final set = CardioSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedDurationMinutes: 30,
      );
      expect(set.durationDelta, isNull);
    });

    test('durationDelta is computed when actual is set', () {
      final set = CardioSet(
        id: '1',
        workoutId: 'w1',
        exerciseId: 'e1',
        plannedDurationMinutes: 30,
        actualDurationMinutes: 35,
      );
      expect(set.durationDelta, 5);
    });
  });

  group('ExerciseDefinition', () {
    test('default type is weightlifting', () {
      final exercise = const ExerciseDefinition(id: '1', name: 'Bench');
      expect(exercise.type, ExerciseType.weightlifting);
    });

    test('copyWith preserves unchanged fields', () {
      final original = const ExerciseDefinition(
        id: '1',
        name: 'Bench Press',
        description: 'Chest exercise',
      );
      final copy = original.copyWith(name: 'Incline Bench Press');
      expect(copy.id, '1');
      expect(copy.name, 'Incline Bench Press');
      expect(copy.description, 'Chest exercise');
    });
  });
}
