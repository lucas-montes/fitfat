import '../../database/app_database.dart';
import '../../models/exercise_models.dart';
import '../interfaces/exercise_repository.dart';

class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ExerciseDefinition>> getAll() async {
    final rows = await _db.getAllExercises();
    return rows
        .map(
          (e) =>
              ExerciseDefinition(id: e.id, name: e.name, category: e.category),
        )
        .toList();
  }
}
