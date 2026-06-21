import 'package:flutter_test/flutter_test.dart';
import 'package:fitfat/src/exercise/services/workout_services.dart';
import 'package:fitfat/src/models/workout.dart';

void main() {
  group('WorkoutSessionService', () {
    late WorkoutSessionService service;

    setUp(() {
      service = WorkoutSessionService();
    });

    test('formatDuration returns mm:ss for under one hour', () {
      const duration = Duration(minutes: 5, seconds: 30);
      expect(service.formatDuration(duration), '05:30');
    });

    test('formatDuration returns mm:ss for zero', () {
      expect(service.formatDuration(Duration.zero), '00:00');
    });

    test('getRestSeconds uses configured value when provided', () {
      expect(service.getRestSeconds(configuredRestSeconds: 90), 90);
    });

    test('getRestSeconds falls back to default when not provided', () {
      expect(service.getRestSeconds(), 60);
    });

    test('estimateOneRM returns null for zero reps', () {
      expect(service.estimateOneRM(50, 0), isNull);
    });

    test('estimateOneRM returns null for zero weight', () {
      expect(service.estimateOneRM(0, 5), isNull);
    });

    test('estimateOneRM returns weight for single rep', () {
      expect(service.estimateOneRM(100, 1), 100);
    });

    test('estimateOneRM uses Epley formula for multiple reps', () {
      // Epley: weight * (1 + reps / 30)
      // 50 * (1 + 10/30) = 50 * 1.333 = 66.67
      final result = service.estimateOneRM(50, 10);
      expect(result, closeTo(66.67, 0.01));
    });

    test('setVolume calculates reps * weight', () {
      expect(service.setVolume(10, 50), 500);
    });
  });

  group('ExerciseLibraryService', () {
    test('bundledExercises contains 7 categories', () {
      expect(ExerciseLibraryService.bundledExercises.length, 7);
    });

    test('getAllBundled returns flat list with categories', () {
      final all = ExerciseLibraryService.getAllBundled();
      expect(all.isNotEmpty, isTrue);
      for (final (name, category) in all) {
        expect(name, isA<String>());
        expect(category, isA<String>());
      }
    });

    test('getAllBundledWithMet returns flat list with MET', () {
      final all = ExerciseLibraryService.getAllBundledWithMet();
      expect(all.isNotEmpty, isTrue);
      for (final (name, category, met) in all) {
        expect(name, isA<String>());
        expect(category, isA<String>());
        expect(met, greaterThan(0));
      }
    });

    group('search', () {
      late ExerciseLibraryService service;
      late List<ExerciseDefinition> exercises;

      setUp(() {
        service = ExerciseLibraryService();
        exercises = [
          const ExerciseDefinition(id: '1', name: 'Bench Press'),
          const ExerciseDefinition(id: '2', name: 'Squat'),
          const ExerciseDefinition(id: '3', name: 'Overhead Press'),
        ];
      });

      test('returns all exercises for empty query', () {
        expect(service.search(exercises, '').length, 3);
      });

      test('filters by name', () {
        final result = service.search(exercises, 'bench');
        expect(result.length, 1);
        expect(result.first.name, 'Bench Press');
      });

      test('is case-insensitive', () {
        final result = service.search(exercises, 'BENCH');
        expect(result.length, 1);
      });
    });

    group('isDuplicate', () {
      late ExerciseLibraryService service;
      late List<ExerciseDefinition> exercises;

      setUp(() {
        service = ExerciseLibraryService();
        exercises = [const ExerciseDefinition(id: '1', name: 'Bench Press')];
      });

      test('returns true for duplicate name', () {
        expect(service.isDuplicate('Bench Press', exercises), isTrue);
      });

      test('returns false for new name', () {
        expect(service.isDuplicate('Squat', exercises), isFalse);
      });

      test('is case-insensitive', () {
        expect(service.isDuplicate('bench press', exercises), isTrue);
      });
    });
  });

  group('ProgressionService', () {
    late ProgressionService service;

    setUp(() {
      service = ProgressionService();
    });

    group('epleyOneRM', () {
      test('returns null for zero reps', () {
        expect(service.epleyOneRM(50, 0), isNull);
      });

      test('returns null for zero weight', () {
        expect(service.epleyOneRM(0, 5), isNull);
      });

      test('returns weight for single rep', () {
        expect(service.epleyOneRM(100, 1), 100);
      });

      test('applies Epley formula', () {
        // 80 * (1 + 8/30) = 80 * 1.267 = 101.33
        expect(service.epleyOneRM(80, 8), closeTo(101.33, 0.01));
      });
    });

    group('brzyckiOneRM', () {
      test('returns null for zero reps', () {
        expect(service.brzyckiOneRM(50, 0), isNull);
      });

      test('returns null for 37+ reps', () {
        expect(service.brzyckiOneRM(50, 37), isNull);
      });

      test('returns weight for single rep', () {
        expect(service.brzyckiOneRM(100, 1), 100);
      });

      test('applies Brzycki formula', () {
        // 80 * (36 / (37-8)) = 80 * 1.241 = 99.31
        expect(service.brzyckiOneRM(80, 8), closeTo(99.31, 0.01));
      });
    });

    test('setVolume returns reps * weight', () {
      expect(service.setVolume(10, 50), 500);
    });

    group('WeightSet overloads', () {
      late WeightSet set1;
      late WeightSet set2;
      late WeightSet set3;

      setUp(() {
        set1 = WeightSet(
          id: '1',
          workoutId: 'w1',
          exerciseId: 'e1',
          plannedReps: 10,
          plannedWeightKg: 50,
        );
        set2 = WeightSet(
          id: '2',
          workoutId: 'w1',
          exerciseId: 'e1',
          plannedReps: 8,
          plannedWeightKg: 60,
        );
        set3 = WeightSet(
          id: '3',
          workoutId: 'w1',
          exerciseId: 'e1',
          // No actual values — uses planned defaults
          plannedReps: 12,
          plannedWeightKg: 40,
        );
      });

      test('setVolumeFromWeightSet uses effective values', () {
        expect(service.setVolumeFromWeightSet(set1), 500);
      });

      test('epleyOneRMFromWeightSet delegates to epleyOneRM', () {
        // 50 * (1 + 10/30) = 66.67
        expect(service.epleyOneRMFromWeightSet(set1), closeTo(66.67, 0.01));
      });

      test('totalVolumeFromWeightSets sums all sets', () {
        final sets = [set1, set2, set3];
        // 500 + 480 + 480 = 1460
        expect(service.totalVolumeFromWeightSets(sets), 1460);
      });

      test('findBestSetFromWeightSets returns highest e1RM', () {
        final sets = [set1, set2, set3];
        final best = service.findBestSetFromWeightSets(sets);
        expect(best, isNotNull);
        expect(best!.plannedWeightKg, 60);
      });

      test('findBestSetFromWeightSets returns null for empty list', () {
        expect(service.findBestSetFromWeightSets([]), isNull);
      });

      test('findMaxWeightFromWeightSets returns heaviest set', () {
        final sets = [set1, set2, set3];
        final max = service.findMaxWeightFromWeightSets(sets);
        expect(max, isNotNull);
        expect(max!.plannedWeightKg, 60);
      });

      test('findMaxVolumeSetFromWeightSets returns highest volume', () {
        final sets = [set1, set2, set3];
        final max = service.findMaxVolumeSetFromWeightSets(sets);
        expect(max, isNotNull);
        expect(max!.plannedReps * max.plannedWeightKg, 500);
      });
    });

    group('progressionPercent', () {
      test('returns 0 when start is 0', () {
        expect(service.progressionPercent(0, 100), 100);
      });

      test('returns positive percentage for improvement', () {
        expect(service.progressionPercent(50, 60), closeTo(20, 0.01));
      });

      test('returns negative percentage for decline', () {
        expect(service.progressionPercent(60, 50), closeTo(-16.67, 0.01));
      });
    });
  });
}
