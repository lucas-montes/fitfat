import '../../models/exercise.dart';
import '../../models/workout.dart' as domain;

/// Pure Dart service for workout session state management and rest timer logic.
/// No Flutter, no DB, no UI dependencies — fully testable.
class WorkoutSessionService {
  /// Whether the session is guided (template-based) or free-form.
  bool get isGuided => _isGuided;
  final bool _isGuided = false;

  /// The elapsed duration since the session started.
  Duration elapsed(DateTime startedAt) => DateTime.now().difference(startedAt);

  /// Total rep count across all exercises in a seance.
  int totalReps(Seance seance) =>
      seance.exercises.fold(0, (sum, entry) => sum + entry.totalReps);

  /// Total weight volume (reps × weight) across all exercises.
  double totalVolume(Seance seance) =>
      seance.exercises.fold(0.0, (sum, entry) => sum + entry.totalWeight);

  /// Whether a set is a "personal record" compared to previous best.
  bool isPersonalRecord(ExerciseSet set, List<ExerciseSet> history) {
    if (history.isEmpty) return true;
    final best = history.fold<double>(
      0,
      (max, s) => max > (s.weight * s.reps) ? max : (s.weight * s.reps),
    );
    return (set.weight * set.reps) > best;
  }

  /// Calculate rest timer duration in seconds.
  /// If [configuredRestSeconds] is provided, uses that.
  /// Otherwise falls back to [defaultRestSeconds] (default 60s).
  int getRestSeconds({
    int? configuredRestSeconds,
    int defaultRestSeconds = 60,
  }) {
    return configuredRestSeconds ?? defaultRestSeconds;
  }

  /// Format a duration as mm:ss for display.
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Estimated 1RM using the Epley formula: weight × (1 + reps/30).
  /// Returns null if reps or weight is 0.
  double? estimateOneRM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return null;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Calculate volume load (reps × weight) for a single set.
  double setVolume(int reps, double weight) => reps * weight;
}

/// Pure Dart service for exercise library management and bundled data seeding.
/// No Flutter, no DB, no UI dependencies.
class ExerciseLibraryService {
  /// Default bundled exercises organized by category.
  static const Map<String, List<String>> bundledExercises = {
    'Chest': [
      'Bench Press',
      'Incline Bench Press',
      'Decline Bench Press',
      'Dumbbell Flyes',
      'Cable Crossovers',
      'Push-ups',
      'Chest Dips',
    ],
    'Back': [
      'Deadlift',
      'Pull-ups',
      'Barbell Row',
      'Lat Pulldown',
      'Seated Cable Row',
      'Face Pull',
      'Dumbbell Row',
    ],
    'Legs': [
      'Squat',
      'Front Squat',
      'Leg Press',
      'Romanian Deadlift',
      'Leg Curl',
      'Leg Extension',
      'Calf Raises',
      'Bulgarian Split Squat',
    ],
    'Shoulders': [
      'Overhead Press',
      'Arnold Press',
      'Lateral Raise',
      'Front Raise',
      'Reverse Flyes',
      'Upright Row',
    ],
    'Arms': [
      'Barbell Curl',
      'Dumbbell Curl',
      'Hammer Curl',
      'Tricep Pushdown',
      'Skull Crushers',
      'Tricep Dips',
      'Preacher Curl',
    ],
    'Core': [
      'Plank',
      'Crunches',
      'Russian Twists',
      'Hanging Leg Raises',
      'Ab Wheel Rollout',
      'Cable Crunch',
    ],
    'Cardio': [
      'Swimming',
      'Running',
      'Cycling',
      'Skateboarding',
      'Football',
      'Yoga',
      'Walking',
      'Hiking',
      'Rowing',
      'Jump Rope',
    ],
  };

  /// MET (Metabolic Equivalent of Task) values for bundled exercises.
  /// Used for calorie estimation. Falls back to 5.0 if not listed.
  static const Map<String, double> bundledExerciseMet = {
    // Weightlifting defaults
    'Bench Press': 5.5,
    'Incline Bench Press': 5.5,
    'Decline Bench Press': 5.5,
    'Dumbbell Flyes': 5.0,
    'Cable Crossovers': 5.0,
    'Push-ups': 4.0,
    'Chest Dips': 5.0,
    'Deadlift': 6.0,
    'Pull-ups': 5.0,
    'Barbell Row': 5.0,
    'Lat Pulldown': 5.0,
    'Seated Cable Row': 5.0,
    'Face Pull': 4.5,
    'Dumbbell Row': 5.0,
    'Squat': 6.0,
    'Front Squat': 6.0,
    'Leg Press': 5.0,
    'Romanian Deadlift': 5.5,
    'Leg Curl': 4.5,
    'Leg Extension': 4.5,
    'Calf Raises': 4.0,
    'Bulgarian Split Squat': 5.5,
    'Overhead Press': 5.0,
    'Arnold Press': 5.0,
    'Lateral Raise': 4.0,
    'Front Raise': 4.0,
    'Reverse Flyes': 4.0,
    'Upright Row': 5.0,
    'Barbell Curl': 4.0,
    'Dumbbell Curl': 4.0,
    'Hammer Curl': 4.0,
    'Tricep Pushdown': 4.0,
    'Skull Crushers': 4.0,
    'Tricep Dips': 5.0,
    'Preacher Curl': 4.0,
    'Plank': 3.0,
    'Crunches': 3.0,
    'Russian Twists': 3.5,
    'Hanging Leg Raises': 4.0,
    'Ab Wheel Rollout': 4.0,
    'Cable Crunch': 4.0,
    // Cardio
    'Swimming': 6.0,
    'Running': 8.0,
    'Cycling': 7.0,
    'Skateboarding': 5.0,
    'Football': 7.0,
    'Yoga': 3.0,
    'Walking': 3.5,
    'Hiking': 5.5,
    'Rowing': 6.0,
    'Jump Rope': 10.0,
  };

  /// Returns all bundled exercises as a flat list of (name, category) pairs.
  static List<(String, String)> getAllBundled() {
    final result = <(String, String)>[];
    for (final entry in bundledExercises.entries) {
      for (final name in entry.value) {
        result.add((name, entry.key));
      }
    }
    return result;
  }

  /// Returns all bundled exercises with MET values as (name, category, met).
  static List<(String, String, double)> getAllBundledWithMet() {
    final result = <(String, String, double)>[];
    for (final entry in bundledExercises.entries) {
      for (final name in entry.value) {
        result.add((name, entry.key, bundledExerciseMet[name] ?? 5.0));
      }
    }
    return result;
  }

  /// Filter exercises by name query.
  List<ExerciseDefinition> search(
    List<ExerciseDefinition> exercises,
    String query,
  ) {
    if (query.trim().isEmpty) return exercises;
    final lowerQuery = query.trim().toLowerCase();
    return exercises.where((e) {
      return e.name.toLowerCase().contains(lowerQuery) ||
          e.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter exercises by category.
  List<ExerciseDefinition> filterByCategory(
    List<ExerciseDefinition> exercises,
    String category,
  ) {
    return exercises.where((e) => e.category == category).toList();
  }

  /// Check if two exercises are likely duplicates by normalized name.
  bool isDuplicate(String name, List<ExerciseDefinition> existing) {
    final normalized = name.trim().toLowerCase();
    return existing.any((e) => e.name.trim().toLowerCase() == normalized);
  }

  /// Get unique categories from a list of exercises, sorted.
  List<String> getCategories(List<ExerciseDefinition> exercises) {
    final categories = exercises.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }
}

/// Pure Dart service for 1RM calculation, volume computation, and PR detection.
/// No Flutter, no DB, no UI dependencies.
class ProgressionService {
  /// Estimated 1RM using the Epley formula: weight × (1 + reps/30).
  /// More accurate for reps in the 1-10 range.
  /// Returns null if reps or weight is 0.
  double? epleyOneRM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return null;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Estimated 1RM using the Brzycki formula: weight × (36 / (37 - reps)).
  /// More conservative for higher rep ranges.
  /// Returns null if reps or weight is 0, or reps >= 37.
  double? brzyckiOneRM(double weight, int reps) {
    if (weight <= 0 || reps <= 0 || reps >= 37) return null;
    if (reps == 1) return weight;
    return weight * (36 / (37 - reps));
  }

  /// Volume load for a single set (reps × weight).
  double setVolume(int reps, double weight) => reps * weight;

  /// Total volume for a list of sets.
  double totalVolume(List<ExerciseSet> sets) {
    return sets.fold(0.0, (sum, set) => sum + (set.reps * set.weight));
  }

  /// Total volume for a complete seance.
  double seanceVolume(Seance seance) {
    return seance.exercises.fold(
      0.0,
      (sum, entry) => sum + totalVolume(entry.sets),
    );
  }

  /// Find the best set (highest estimated 1RM) across all sets.
  ExerciseSet? findBestSet(List<ExerciseSet> sets) {
    if (sets.isEmpty) return null;
    return sets.fold<ExerciseSet?>(null, (best, set) {
      final current = epleyOneRM(set.weight, set.reps) ?? 0;
      final bestVal = best != null
          ? (epleyOneRM(best.weight, best.reps) ?? 0)
          : 0;
      return current > bestVal ? set : best;
    });
  }

  /// Find the maximum weight lifted across all sets.
  ExerciseSet? findMaxWeight(List<ExerciseSet> sets) {
    if (sets.isEmpty) return null;
    return sets.fold<ExerciseSet?>(null, (max, set) {
      return (max == null || set.weight > max.weight) ? set : max;
    });
  }

  /// Find the maximum volume set (reps × weight).
  ExerciseSet? findMaxVolumeSet(List<ExerciseSet> sets) {
    if (sets.isEmpty) return null;
    return sets.fold<ExerciseSet?>(null, (max, set) {
      final currentVol = set.reps * set.weight;
      final maxVol = max != null ? max.reps * max.weight : 0.0;
      return currentVol > maxVol ? set : max;
    });
  }

  // ---------------------------------------------------------------------------
  // WeightSet overloads (new model)
  // ---------------------------------------------------------------------------

  /// Volume load for a single [domain.WeightSet] (reps × weightKg).
  double setVolumeFromWeightSet(domain.WeightSet set) =>
      set.reps * set.weightKg;

  /// Estimated 1RM for a [domain.WeightSet] using the Epley formula.
  double? epleyOneRMFromWeightSet(domain.WeightSet set) =>
      epleyOneRM(set.weightKg, set.reps);

  /// Find the best set (highest estimated 1RM) across a list of [domain.WeightSet].
  domain.WeightSet? findBestSetFromWeightSets(List<domain.WeightSet> sets) {
    if (sets.isEmpty) return null;
    return sets.fold<domain.WeightSet?>(null, (best, set) {
      final current = epleyOneRMFromWeightSet(set) ?? 0;
      final bestVal = best != null ? (epleyOneRMFromWeightSet(best) ?? 0) : 0;
      return current > bestVal ? set : best;
    });
  }

  /// Find the maximum weight lifted across a list of [domain.WeightSet].
  domain.WeightSet? findMaxWeightFromWeightSets(List<domain.WeightSet> sets) {
    if (sets.isEmpty) return null;
    return sets.fold<domain.WeightSet?>(null, (max, set) {
      return (max == null || set.weightKg > max.weightKg) ? set : max;
    });
  }

  /// Find the maximum volume set (reps × weightKg) in a list of [domain.WeightSet].
  domain.WeightSet? findMaxVolumeSetFromWeightSets(
    List<domain.WeightSet> sets,
  ) {
    if (sets.isEmpty) return null;
    return sets.fold<domain.WeightSet?>(null, (max, set) {
      final currentVol = set.reps * set.weightKg;
      final maxVol = max != null ? max.reps * max.weightKg : 0.0;
      return currentVol > maxVol ? set : max;
    });
  }

  /// Calculate progression trend: percentage improvement from [start] to [end].
  double progressionPercent(double start, double end) {
    if (start <= 0) return end > 0 ? 100 : 0;
    return ((end - start) / start) * 100;
  }
}
