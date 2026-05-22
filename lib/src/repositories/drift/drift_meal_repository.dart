import '../../database/app_database.dart';
import '../../models/food_models.dart';
import '../interfaces/meal_repository.dart';

class DriftMealRepository implements MealRepository {
  DriftMealRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<MealEntry>> getByDate(DateTime date) async {
    // TODO: implement with proper joining once food providers are migrated
    return [];
  }

  @override
  Future<void> insert(MealEntry meal) async {
    // TODO: implement with transaction once providers are migrated
  }

  @override
  Future<void> delete(String id) async {
    await _db.deleteMeal(id);
  }
}
