import '../../models/exercise_models.dart';

abstract class FullSeanceRepository {
  Future<void> insertSeance(Seance seance);
  Future<List<Seance>> getAll();
  Future<void> delete(String id);
}
