import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food.dart';
import '../../database/providers.dart';
import '../../adapters/drift/meal_repository.dart';
import '../repositories/meals.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftMealRepository(db);
});

enum MealsStatus { idle, loading, data, error }

class MealsState {
  final MealsStatus status;
  final DateTime selectedMonth;
  final List<MealEntry> meals;
  final String? errorMessage;

  MealsState({
    required this.status,
    required this.selectedMonth,
    this.meals = const [],
    this.errorMessage,
  });

  MealsState copyWith({
    MealsStatus? status,
    DateTime? selectedMonth,
    List<MealEntry>? meals,
    String? errorMessage,
  }) {
    return MealsState(
      status: status ?? this.status,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      meals: meals ?? this.meals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MealsController extends Notifier<MealsState> {
  late final MealRepository _repo;
  StreamSubscription<List<MealEntry>>? _repoSub;

  @override
  MealsState build() {
    _repo = ref.read(mealRepositoryProvider);
    ref.onDispose(() => _repoSub?.cancel());
    return MealsState(
      status: MealsStatus.idle,
      selectedMonth: DateTime.now(),
    );
  }

  Future<void> loadMonth(DateTime month) async {
    state = state.copyWith(
      status: MealsStatus.loading,
      selectedMonth: month,
    );
    try {
      final monthStart = DateTime(month.year, month.month, 1);
      _subscribeToRepo(monthStart);
      final mealsList = await _repo.getByDate(monthStart);
      if (ref.mounted) {
        state = state.copyWith(
          status: MealsStatus.data,
          meals: mealsList,
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          status: MealsStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  void _subscribeToRepo(DateTime monthStart) {
    _repoSub?.cancel();
    _repoSub = _repo.watchMealsForDay(monthStart).listen(
      (mealsList) {
        if (ref.mounted) {
          state = state.copyWith(
            status: MealsStatus.data,
            meals: mealsList,
          );
        }
      },
      onError: (e) {
        if (ref.mounted) {
          state = state.copyWith(
            status: MealsStatus.error,
            errorMessage: e.toString(),
          );
        }
      },
    );
  }

  Future<void> addMeal(MealEntry meal) async {
    await _repo.insert(meal);
    state = state.copyWith(meals: [...state.meals, meal]);
  }

  Future<void> updateMeal(String id, MealEntry meal) async {
    await _repo.upsert(meal);
    state = state.copyWith(
      meals: [
        for (final existing in state.meals)
          if (existing.id == id) meal else existing,
      ],
    );
  }

  Future<void> deleteMeal(String id) async {
    await _repo.delete(id);
    state = state.copyWith(
      meals: state.meals.where((meal) => meal.id != id).toList(),
    );
  }
}

final mealsProvider = NotifierProvider<MealsController, MealsState>(
  MealsController.new,
);
