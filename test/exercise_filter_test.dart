import 'package:fitfat/src/exercise/exercise_filter.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _exercise({
  required String id,
  required String name,
  String exerciseType = 'weightlifting',
  String? bodyPart,
  String? equipment,
  String? primaryMuscle,
  String? secondaryMuscle,
  List<String>? keywords,
}) => Exercise(
  id: id,
  name: name,
  exerciseType: exerciseType,
  bodyPart: bodyPart,
  equipment: equipment,
  primaryMuscle: primaryMuscle,
  secondaryMuscle: secondaryMuscle,
  keywords: keywords,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('splitTags', () {
    test('returns empty list for null', () {
      expect(splitTags(null), isEmpty);
    });

    test('splits and trims comma-separated values', () {
      expect(
        splitTags('Quadriceps, Thighs'),
        containsAll(['Quadriceps', 'Thighs']),
      );
    });

    test('deduplicates and drops empty segments', () {
      expect(
        splitTags('Chest,  , chest, Shoulders'),
        containsAll(['Chest', 'Shoulders']),
      );
    });

    test('handles single value', () {
      expect(splitTags('Back'), ['Back']);
    });
  });

  group('canonicalEquipmentTag', () {
    test('maps synonyms to canonical labels', () {
      expect(canonicalEquipmentTag('Band'), 'Resistance Band');
      expect(canonicalEquipmentTag('Olympic barbell'), 'Barbell');
      expect(canonicalEquipmentTag('Dumbbell'), 'Dumbbell');
    });
  });

  group('exerciseFilterOptions', () {
    test('collects distinct, sorted options from exercises', () {
      final exercises = [
        _exercise(
          id: 'a',
          name: 'Squat',
          bodyPart: 'Quadriceps',
          equipment: 'Barbell',
          primaryMuscle: 'Quadriceps',
          secondaryMuscle: 'Glutes',
        ),
        _exercise(
          id: 'b',
          name: 'Push Up',
          bodyPart: 'Chest, Triceps',
          equipment: 'Bodyweight',
          primaryMuscle: 'Pecs',
          secondaryMuscle: 'Triceps',
        ),
      ];

      final options = exerciseFilterOptions(exercises);

      expect(options.types, ['weightlifting']);
      expect(
        options.bodyParts,
        containsAll(['Quadriceps', 'Chest', 'Triceps']),
      );
      expect(options.equipments, containsAll(['Barbell', 'Bodyweight']));
      expect(
        options.muscles,
        containsAll(['Quadriceps', 'Glutes', 'Pecs', 'Triceps']),
      );
    });

    test('canonicalizes equipment in options', () {
      final options = exerciseFilterOptions([
        _exercise(id: 'a', name: 'A', equipment: 'Band'),
        _exercise(id: 'b', name: 'B', equipment: 'Resistance Band'),
      ]);
      expect(options.equipments, ['Resistance Band']);
    });
  });

  group('filterExercises', () {
    final exercises = [
      _exercise(
        id: 'squat',
        name: 'Barbell Squat',
        bodyPart: 'Quadriceps',
        equipment: 'Barbell',
        primaryMuscle: 'Quadriceps',
        secondaryMuscle: 'Glutes',
        keywords: ['legs', 'lower body'],
      ),
      _exercise(
        id: 'pushup',
        name: 'Push Up',
        bodyPart: 'Chest',
        equipment: 'Bodyweight',
        primaryMuscle: 'Pecs',
        keywords: ['upper body'],
      ),
      _exercise(
        id: 'situps',
        name: 'Sit Ups',
        bodyPart: 'Abs',
        equipment: 'Bodyweight',
        primaryMuscle: 'Abdominals',
      ),
    ];

    test('empty query and no filters returns everything', () {
      expect(filterExercises(exercises).length, 3);
    });

    test('query matches name case-insensitively', () {
      expect(filterExercises(exercises, query: 'squat').single.id, 'squat');
    });

    test('query matches keywords (hidden from display)', () {
      expect(
        filterExercises(exercises, query: 'lower body').single.id,
        'squat',
      );
    });

    test('query matches muscles', () {
      expect(
        filterExercises(exercises, query: 'abdominals').single.id,
        'situps',
      );
    });

    test('type filter narrows to matching exercises', () {
      final cardio = _exercise(
        id: 'run',
        name: 'Run',
        exerciseType: 'cardio',
        bodyPart: 'Cardio',
      );
      final all = [...exercises, cardio];
      expect(filterExercises(all, types: {'cardio'}).single.id, 'run');
    });

    test('body part filter matches split multi-tags', () {
      expect(
        filterExercises(exercises, bodyParts: {'Quadriceps'}).single.id,
        'squat',
      );
    });

    test('equipment filter matches canonicalized tags', () {
      expect(
        filterExercises(exercises, equipments: {'Resistance Band'}).isEmpty,
        isTrue,
      );
    });

    test('equipment filter matches raw-equivalent canonical tag', () {
      final withBand = [
        ...exercises,
        _exercise(id: 'band', name: 'Band Row', equipment: 'Band'),
      ];
      expect(
        filterExercises(withBand, equipments: {'Resistance Band'}).single.id,
        'band',
      );
    });

    test('muscle filter matches primary or secondary', () {
      expect(
        filterExercises(exercises, muscles: {'Glutes'}).single.id,
        'squat',
      );
    });

    test('filters are AND-ed together', () {
      expect(
        filterExercises(exercises, query: 'squat', bodyParts: {'Chest'}),
        isEmpty,
      );
      expect(
        filterExercises(
          exercises,
          query: 'squat',
          bodyParts: {'Quadriceps'},
        ).single.id,
        'squat',
      );
    });

    test('combined tags intersect (multi-tag body part)', () {
      final combined = _exercise(
        id: 'combo',
        name: 'Combo',
        bodyPart: 'Chest, Back',
        equipment: 'Bodyweight',
      );
      expect(
        filterExercises(
          [...exercises, combined],
          bodyParts: {'Back'},
        ).single.id,
        'combo',
      );
    });
  });
}
