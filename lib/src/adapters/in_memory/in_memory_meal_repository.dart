import 'dart:async';

import '../../models/food_models.dart';
import '../../repositories/interfaces/meal_repository.dart';

class InMemoryMealRepository implements MealRepository {
  final Map<String, MealEntry> _store = {};
  final _controller = StreamController<List<MealEntry>>.broadcast();
  InMemoryMealRepository([List<MealEntry>? seed]) {
    if (seed != null) {
      for (final m in seed) {
        _store[m.id] = m;
      }
    }
    // emit initial
    _controller.add(_store.values.toList());
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _controller.add(_store.values.toList());
  }

  @override
  Future<List<MealEntry>> getAll() async => _store.values.toList();

  @override
  Future<List<MealEntry>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _store.values.where((m) => m.eatenAt.isAfter(start) && m.eatenAt.isBefore(end)).toList();
  }

  @override
  Stream<List<MealEntry>> watchAll() => _controller.stream;

  @override
  Stream<List<MealEntry>> watchMealsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _controller.stream.map((list) => list.where((m) => m.eatenAt.isAfter(start) && m.eatenAt.isBefore(end)).toList());
  }

  @override
  Future<void> insert(MealEntry meal) async {
    _store[meal.id] = meal;
    _controller.add(_store.values.toList());
  }

  @override
  Future<void> upsert(MealEntry meal) async {
    _store[meal.id] = meal;
    _controller.add(_store.values.toList());
  }
}
