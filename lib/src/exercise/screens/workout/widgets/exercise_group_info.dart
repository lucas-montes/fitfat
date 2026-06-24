import '../../../../models/workout.dart';

/// Describes one exercise's group of sets in the active workout overview.
///
/// Used by exercise cards showing the exercise name, icon, and completion
/// progress (e.g. "3/5 sets").
class ExerciseGroupInfo {
  final ExerciseDefinition exercise;
  final int totalSets;
  final int completedSets;

  const ExerciseGroupInfo({
    required this.exercise,
    required this.totalSets,
    required this.completedSets,
  });
}
