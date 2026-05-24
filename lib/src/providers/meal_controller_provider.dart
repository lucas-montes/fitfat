import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_models.dart';
// repository interface accessed via provider when needed
import 'repositories.dart';

enum MealListStatus { idle, loading, data, error }

class MealListState {
  final MealListStatus status;
  final DateTime day;
  final List<MealEntry> meals;
  final String? errorMessage;

  MealListState({
    required this.status,
    required this.day,
    this.meals = const [],
    this.errorMessage,
  });

  MealListState copyWith({MealListStatus? status, DateTime? day, List<MealEntry>? meals, String? errorMessage}) {
    return MealListState(
      status: status ?? this.status,
      day: day ?? this.day,
      meals: meals ?? this.meals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MealListController extends Notifier<MealListState> {
  StreamSubscription<List<MealEntry>>? _repoSub;

  @override
  MealListState build() => MealListState(status: MealListStatus.idle, day: DateTime.now());

  Future<void> load(DateTime day) async {
    state = state.copyWith(status: MealListStatus.loading, day: day);
    try {
      final repo = ref.read(mealRepositoryProvider);
      final meals = await repo.getByDate(day);
      state = state.copyWith(
        status: MealListStatus.data,
        meals: meals,
      );
      _subscribeToRepo(day);
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async => load(state.day);

  Future<void> addMeal(MealEntry meal) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final repo = ref.read(mealRepositoryProvider);
      await repo.upsert(meal);
      await refresh();
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> updateMeal(String id, MealEntry meal) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final repo = ref.read(mealRepositoryProvider);
      await repo.upsert(meal);
      await refresh();
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> deleteMeal(String id) async {
    state = state.copyWith(status: MealListStatus.loading);
    try {
      final repo = ref.read(mealRepositoryProvider);
      await repo.delete(id);
      await refresh();
    } catch (e) {
      state = state.copyWith(status: MealListStatus.error, errorMessage: e.toString());
    }
  }

  void _subscribeToRepo(DateTime day) {
    _repoSub?.cancel();
    final repo = ref.read(mealRepositoryProvider);
    _repoSub = repo.watchMealsForDay(day).listen((meals) {
      state = state.copyWith(status: MealListStatus.data, meals: meals);
    });
    ref.onDispose(() => _repoSub?.cancel());
  }

  void disposeController() {
    _repoSub?.cancel();
  }

  // No extra view-model mapping required; UI can consume `MealEntry` directly.
}

final mealControllerProvider = NotifierProvider<MealListController, MealListState>(MealListController.new);
