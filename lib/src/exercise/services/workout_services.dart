import '../../models/exercise.dart';

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
  /// Default bundled exercises organized by muscle group.
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

  /// Calculate progression trend: percentage improvement from [start] to [end].
  double progressionPercent(double start, double end) {
    if (start <= 0) return end > 0 ? 100 : 0;
    return ((end - start) / start) * 100;
  }
}
