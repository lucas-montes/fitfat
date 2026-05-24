import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_models.dart';
import 'repositories.dart';

enum MealListStatus { idle, loading, data, error }

class MealListState {
  final MealListStatus status;
  final DateTime selectedMonth;
  final List<MealEntry> meals;
  final String? errorMessage;

  MealListState({
    required this.status,
    required this.selectedMonth,
    this.meals = const [],
    this.errorMessage,
  });

  MealListState copyWith({
    MealListStatus? status,
    DateTime? selectedMonth,
    List<MealEntry>? meals,
    String? errorMessage,
  }) {
    return MealListState(
      status: status ?? this.status,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      meals: meals ?? this.meals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MealListController extends Notifier<MealListState> {
  StreamSubscription<List<MealEntry>>? _repoSub;

  @override
  MealListState build() =>
      MealListState(status: MealListStatus.idle, selectedMonth: DateTime.now());

  Future<void> loadMonth(DateTime month) async {
    state = state.copyWith(
      status: MealListStatus.loading,
      selectedMonth: month,
    );
    try {
      final repo = ref.read(mealRepositoryProvider);
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 1);
      final meals = await repo.getByDate(monthStart);
      final endMeals = await repo.getByDate(monthEnd);
      final combined = <MealEntry>[...meals, ...endMeals];
      state = state.copyWith(status: MealListStatus.data, meals: combined);
      _subscribeToRepo(month);
    } catch (e) {
      state = state.copyWith(
        status: MealListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async => loadMonth(state.selectedMonth);

  Future<void> addMeal(MealEntry meal) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final repo = ref.read(mealRepositoryProvider);
      await repo.upsert(meal);
      await refresh();
    } catch (e) {
      state = state.copyWith(
        status: MealListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateMeal(String id, MealEntry meal) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final repo = ref.read(mealRepositoryProvider);
      await repo.upsert(meal);
      await refresh();
    } catch (e) {
      state = state.copyWith(
        status: MealListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteMeal(String id) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final repo = ref.read(mealRepositoryProvider);
      await repo.delete(id);
      await refresh();
    } catch (e) {
      state = state.copyWith(
        status: MealListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> nextMonth() async {
    try {
      final nextMonth = state.selectedMonth.add(const Duration(days: 32));
      await loadMonth(nextMonth);
    } catch (e) {
      state = state.copyWith(
        status: MealListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> previousMonth() async {
    try {
      final prevMonth = state.selectedMonth.subtract(const Duration(days: 30));
      await loadMonth(prevMonth);
    } catch (e) {
      state = state.copyWith(
        status: MealListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _subscribeToRepo(DateTime month) {
    _repoSub?.cancel();
    final repo = ref.read(mealRepositoryProvider);
    final monthStart = DateTime(month.year, month.month, 1);
    _repoSub = repo.watchMealsForDay(monthStart).listen((meals) {
      state = state.copyWith(status: MealListStatus.data, meals: meals);
    });
    ref.onDispose(() => _repoSub?.cancel());
  }

  void disposeController() {
    _repoSub?.cancel();
  }
}

final mealControllerProvider =
    NotifierProvider<MealListController, MealListState>(MealListController.new);
