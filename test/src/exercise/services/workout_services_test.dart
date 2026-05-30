import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/exercise/services/workout_services.dart';
import 'package:fitfat/src/models/exercise.dart';

void main() {
  group('WorkoutSessionService', () {
    late WorkoutSessionService sessionService;
    const uuid = Uuid();

    setUp(() {
      sessionService = WorkoutSessionService();
    });

    test('totalReps sums all exercise reps', () {
      final seance = Seance(
        id: uuid.v7(),
        startedAt: DateTime.now(),
        exercises: [
          ExerciseEntry(
            id: uuid.v7(),
            exercise: const ExerciseDefinition(id: 'e1', name: 'Bench Press'),
            sets: [
              const ExerciseSet(reps: 10, weight: 60),
              const ExerciseSet(reps: 8, weight: 70),
            ],
            startedAt: DateTime.now(),
          ),
        ],
      );
      expect(sessionService.totalReps(seance), 18);
    });

    test('totalVolume sums all set volumes', () {
      final seance = Seance(
        id: uuid.v7(),
        startedAt: DateTime.now(),
        exercises: [
          ExerciseEntry(
            id: uuid.v7(),
            exercise: const ExerciseDefinition(id: 'e1', name: 'Bench Press'),
            sets: [
              const ExerciseSet(reps: 10, weight: 60),
              const ExerciseSet(reps: 8, weight: 70),
            ],
            startedAt: DateTime.now(),
          ),
        ],
      );
      // 10*60 + 8*70 = 600 + 560 = 1160
      expect(sessionService.totalVolume(seance), 1160);
    });

    test('formatDuration formats minutes and seconds', () {
      expect(
        sessionService.formatDuration(const Duration(seconds: 90)),
        '01:30',
      );
      expect(
        sessionService.formatDuration(const Duration(seconds: 0)),
        '00:00',
      );
      expect(
        sessionService.formatDuration(const Duration(seconds: 3600)),
        '60:00',
      );
    });

    test('estimateOneRM returns correct Epley value', () {
      // Epley: weight * (1 + reps/30)
      // 100kg * (1 + 5/30) = 100 * 1.167 = 116.67
      final rm = sessionService.estimateOneRM(100, 5);
      expect(rm, closeTo(116.67, 0.1));
    });

    test('estimateOneRM returns null for zero weight', () {
      expect(sessionService.estimateOneRM(0, 5), isNull);
    });

    test('estimateOneRM returns weight for single rep', () {
      expect(sessionService.estimateOneRM(100, 1), 100);
    });

    test('isPersonalRecord returns true for first set', () {
      expect(
        sessionService.isPersonalRecord(
          const ExerciseSet(reps: 10, weight: 100),
          [],
        ),
        isTrue,
      );
    });

    test('isPersonalRecord returns true for new best', () {
      final history = [const ExerciseSet(reps: 10, weight: 80)];
      expect(
        sessionService.isPersonalRecord(
          const ExerciseSet(reps: 10, weight: 100),
          history,
        ),
        isTrue,
      );
    });

    test('isPersonalRecord returns false for worse or equal set', () {
      final history = [const ExerciseSet(reps: 10, weight: 100)];
      expect(
        sessionService.isPersonalRecord(
          const ExerciseSet(reps: 10, weight: 80),
          history,
        ),
        isFalse,
      );
    });

    test('getRestSeconds uses configured value when provided', () {
      expect(sessionService.getRestSeconds(configuredRestSeconds: 90), 90);
    });

    test('getRestSeconds falls back to default when not provided', () {
      expect(sessionService.getRestSeconds(), 60);
    });
  });

  group('ExerciseLibraryService', () {
    test('bundled exercises contains 6 muscle groups', () {
      expect(ExerciseLibraryService.bundledExercises.keys.length, 6);
    });

    test('all bundled exercise categories are present', () {
      final categories = ExerciseLibraryService.bundledExercises.keys.toSet();
      expect(
        categories,
        containsAll(['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core']),
      );
    });

    test('total bundled exercises count is reasonable', () {
      final all = ExerciseLibraryService.getAllBundled();
      expect(all.length, greaterThan(30));
      expect(all.length, lessThan(50));
    });

    test('search filters by name', () {
      final exercises = [
        const ExerciseDefinition(
          id: '1',
          name: 'Bench Press',
          category: 'Chest',
        ),
        const ExerciseDefinition(id: '2', name: 'Squat', category: 'Legs'),
        const ExerciseDefinition(id: '3', name: 'Deadlift', category: 'Back'),
      ];

      final service = ExerciseLibraryService();
      final results = service.search(exercises, 'bench');
      expect(results, hasLength(1));
      expect(results.single.name, 'Bench Press');
    });

    test('search returns all exercises for empty query', () {
      final exercises = [
        const ExerciseDefinition(
          id: '1',
          name: 'Bench Press',
          category: 'Chest',
        ),
        const ExerciseDefinition(id: '2', name: 'Squat', category: 'Legs'),
      ];

      final service = ExerciseLibraryService();
      expect(service.search(exercises, ''), hasLength(2));
    });

    test('filterByCategory returns only matching exercises', () {
      final exercises = [
        const ExerciseDefinition(
          id: '1',
          name: 'Bench Press',
          category: 'Chest',
        ),
        const ExerciseDefinition(id: '2', name: 'Squat', category: 'Legs'),
        const ExerciseDefinition(
          id: '3',
          name: 'Incline Press',
          category: 'Chest',
        ),
      ];

      final service = ExerciseLibraryService();
      final chest = service.filterByCategory(exercises, 'Chest');
      expect(chest, hasLength(2));
    });

    test('isDuplicate detects duplicate names case-insensitively', () {
      final existing = [const ExerciseDefinition(id: '1', name: 'Bench Press')];
      final service = ExerciseLibraryService();
      expect(service.isDuplicate('bench press', existing), isTrue);
      expect(service.isDuplicate('Squat', existing), isFalse);
    });

    test('getCategories returns sorted unique categories', () {
      final exercises = [
        const ExerciseDefinition(
          id: '1',
          name: 'Bench Press',
          category: 'Chest',
        ),
        const ExerciseDefinition(id: '2', name: 'Squat', category: 'Legs'),
        const ExerciseDefinition(id: '3', name: 'Deadlift', category: 'Back'),
      ];

      final service = ExerciseLibraryService();
      expect(service.getCategories(exercises), ['Back', 'Chest', 'Legs']);
    });
  });

  group('ProgressionService', () {
    late ProgressionService progressionService;

    setUp(() {
      progressionService = ProgressionService();
    });

    test('epleyOneRM calculates correctly', () {
      // 100kg * (1 + 5/30) = 116.67
      final rm = progressionService.epleyOneRM(100, 5);
      expect(rm, closeTo(116.67, 0.1));
    });

    test('epleyOneRM returns weight for single rep', () {
      expect(progressionService.epleyOneRM(100, 1), 100);
    });

    test('epleyOneRM returns null for zero inputs', () {
      expect(progressionService.epleyOneRM(0, 5), isNull);
      expect(progressionService.epleyOneRM(100, 0), isNull);
    });

    test('brzyckiOneRM calculates differently than Epley', () {
      // Brzycki: 100 * (36 / (37-10)) = 100 * 36/27 = 133.33
      final brzycki = progressionService.brzyckiOneRM(100, 10);
      final epley = progressionService.epleyOneRM(100, 10);
      expect(brzycki, closeTo(133.33, 0.1));
      expect(epley, closeTo(133.33, 0.1)); // Same for 10 reps
    });

    test('setVolume calculates reps × weight', () {
      expect(progressionService.setVolume(10, 60), 600);
    });

    test('totalVolume sums across sets', () {
      final sets = [
        const ExerciseSet(reps: 10, weight: 60),
        const ExerciseSet(reps: 8, weight: 70),
      ];
      // 600 + 560 = 1160
      expect(progressionService.totalVolume(sets), 1160);
    });

    test('totalVolume returns 0 for empty sets', () {
      expect(progressionService.totalVolume([]), 0);
    });

    test('seanceVolume sums across all exercises', () {
      final seance = Seance(
        id: 'test',
        startedAt: DateTime.now(),
        exercises: [
          ExerciseEntry(
            id: 'e1',
            exercise: const ExerciseDefinition(id: 'ex1', name: 'Bench'),
            sets: [const ExerciseSet(reps: 10, weight: 60)],
            startedAt: DateTime.now(),
          ),
          ExerciseEntry(
            id: 'e2',
            exercise: const ExerciseDefinition(id: 'ex2', name: 'Squat'),
            sets: [const ExerciseSet(reps: 5, weight: 100)],
            startedAt: DateTime.now(),
          ),
        ],
      );
      // 600 + 500 = 1100
      expect(progressionService.seanceVolume(seance), 1100);
    });

    test('findBestSet returns set with highest e1RM', () {
      final sets = [
        const ExerciseSet(reps: 10, weight: 60), // e1RM = 80
        const ExerciseSet(reps: 5, weight: 80), // e1RM = 93.33
        const ExerciseSet(reps: 3, weight: 90), // e1RM = 99
      ];
      final best = progressionService.findBestSet(sets);
      expect(best!.weight, 90);
      expect(best.reps, 3);
    });

    test('findBestSet returns null for empty sets', () {
      expect(progressionService.findBestSet([]), isNull);
    });

    test('findMaxWeight returns heaviest set', () {
      final sets = [
        const ExerciseSet(reps: 10, weight: 60),
        const ExerciseSet(reps: 5, weight: 100),
        const ExerciseSet(reps: 8, weight: 80),
      ];
      final max = progressionService.findMaxWeight(sets);
      expect(max!.weight, 100);
    });

    test('progressionPercent calculates correctly', () {
      expect(progressionService.progressionPercent(100, 120), 20);
      expect(progressionService.progressionPercent(100, 100), 0);
      expect(progressionService.progressionPercent(100, 80), -20);
    });
  });
}
