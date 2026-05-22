import '../../models/exercise_models.dart';

abstract class ExerciseRepository {
  Future<List<ExerciseDefinition>> getAll();
}
