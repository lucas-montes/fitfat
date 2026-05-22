import '../../models/food_models.dart';

abstract class MealRepository {
  Future<List<MealEntry>> getByDate(DateTime date);
  Future<void> insert(MealEntry meal);
  Future<void> delete(String id);
}
