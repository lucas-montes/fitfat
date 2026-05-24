import '../../models/food_models.dart';

abstract class MealRepository {
  Future<List<MealEntry>> getByDate(DateTime date);
  Stream<List<MealEntry>> watchMealsForDay(DateTime date);
  Future<List<MealEntry>> getAll();
  Stream<List<MealEntry>> watchAll();
  Future<void> insert(MealEntry meal);
  Future<void> upsert(MealEntry meal);
  Future<void> delete(String id);
}
