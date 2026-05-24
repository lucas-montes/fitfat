import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/food_models.dart';
import '../adapters/drift/drift_ingredient_repository.dart';
import 'database_providers.dart';
import 'repositories.dart';

enum IngredientPageStatus { idle, loading, data, error }

class IngredientPageState {
  final IngredientPageStatus status;
  final List<Ingredient> items;
  final bool hasMore;
  final bool isLoading;
  final String? errorMessage;

  IngredientPageState({
    required this.status,
    required this.hasMore,
    required this.isLoading,
    required this.errorMessage,
    this.items = const [],
  });

  IngredientPageState copyWith({
    IngredientPageStatus? status,
    List<Ingredient>? items,
    bool? hasMore,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IngredientPageState(
      status: status ?? this.status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class IngredientController extends StateNotifier<IngredientPageState> {
  final IngredientRepository _repo;

  IngredientController(this._repo, int initialPage, {bool isLoading = false})
    : super(
        IngredientPageState(
          status: IngredientPageStatus.loading,
          hasMore: true,
          isLoading: isLoading,
          errorMessage: null,
        ),
      );

  Future<void> loadPage(int page) async {
    state = state.copyWith(
      status: IngredientPageStatus.loading,
      isLoading: true,
    );
    try {
      final items = await _repo.getItemsForPage(page);
      final hasMore = items.length >= 50;
      state = state.copyWith(
        status: IngredientPageStatus.data,
        items: items.take(50).toList(),
        hasMore: hasMore,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: IngredientPageStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    try {
      final nextItems = await _repo.getItemsForPage(
        state.items.length ~/ 50 + 1,
      );
      final nextItemsList = nextItems.take(50).toList();
      final updatedItems = [...state.items, ...nextItemsList];
      state = state.copyWith(
        items: updatedItems,
        hasMore: updatedItems.length >= 50,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: IngredientPageStatus.error,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void addIngredient(Ingredient ingredient) {
    final updatedItems = [...state.items, ingredient];
    state = state.copyWith(items: updatedItems);
    _persist(updatedItems);
  }

  void updateIngredient(Ingredient ingredient) {
    final updatedItems = [
      for (final existing in state.items)
        if (existing.id == ingredient.id) ingredient else existing,
    ];
    state = state.copyWith(items: updatedItems);
    _persist(updatedItems);
  }

  void removeIngredient(String id) {
    final updatedItems = state.items.where((i) => i.id != id).toList();
    state = state.copyWith(items: updatedItems);
    _persist(updatedItems);
  }

  void _persist(List<Ingredient> items) {
    Future.microtask(() async {
      try {
        final db = ref.read(databaseProvider);
        final repo = DriftIngredientRepository(db);
        for (final ingredient in items) {
          if (ingredient.components.isEmpty) {
            await repo.insert(ingredient);
          }
        }
      } catch (_) {}
    });
  }
}

final ingredientListProvider =
    StateNotifierProvider<IngredientController, IngredientPageState>((ref) {
      return IngredientController(ref.read(ingredientRepositoryProvider), 0);
    });
