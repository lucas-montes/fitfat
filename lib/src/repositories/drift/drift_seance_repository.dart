import '../../database/app_database.dart'
    hide Seance, ExerciseEntry, ExerciseSet;
import '../../models/exercise_models.dart';
import '../interfaces/seance_repository.dart';

class DriftSeanceRepository implements FullSeanceRepository {
  DriftSeanceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Seance>> getAll() async {
    // TODO: full implementation with joins once providers are migrated
    return [];
  }

  @override
  Future<void> insertSeance(Seance seance) async {
    // TODO: transactional insert with entries + sets once providers are migrated
  }

  @override
  Future<void> delete(String id) async {
    await _db.deleteExerciseEntriesBySeance(id);
    await _db.deleteMeal(id);
  }
}
