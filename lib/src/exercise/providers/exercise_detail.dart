import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workout.dart';
import '../services/providers.dart';

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

enum ExerciseDetailStatus { loading, data, error }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Manages all state for the exercise detail screen (sets, navigation, rest).
///
/// Follows the meals pattern: explicit state class with [copyWith] and a
/// status enum. The screen watches this provider and renders from its state
/// instead of using local `setState`.
class ExerciseDetailState {
  final ExerciseDetailStatus status;
  final List<WeightSet> allWeightSets;
  final List<CardioSet> allCardioSets;
  final List<String> exerciseIds;
  final int currentIndex;
  final bool isResting;
  final DateTime? restStartedAt;
  final String? errorMessage;

  const ExerciseDetailState({
    required this.status,
    this.allWeightSets = const [],
    this.allCardioSets = const [],
    this.exerciseIds = const [],
    this.currentIndex = 0,
    this.isResting = false,
    this.restStartedAt,
    this.errorMessage,
  });

  ExerciseDetailState copyWith({
    ExerciseDetailStatus? status,
    List<WeightSet>? allWeightSets,
    List<CardioSet>? allCardioSets,
    List<String>? exerciseIds,
    int? currentIndex,
    bool? isResting,
    DateTime? restStartedAt,
    bool clearRestStartedAt = false,
    String? errorMessage,
  }) {
    return ExerciseDetailState(
      status: status ?? this.status,
      allWeightSets: allWeightSets ?? this.allWeightSets,
      allCardioSets: allCardioSets ?? this.allCardioSets,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      currentIndex: currentIndex ?? this.currentIndex,
      isResting: isResting ?? this.isResting,
      restStartedAt: clearRestStartedAt
          ? null
          : (restStartedAt ?? this.restStartedAt),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // Computed views
  // ---------------------------------------------------------------------------

  /// The exercise ID of the currently visible page.
  String get currentExerciseId =>
      exerciseIds.isNotEmpty ? exerciseIds[currentIndex] : '';

  /// Weight sets filtered for the current exercise (most recent first).
  List<WeightSet> get weightSets {
    final exId = currentExerciseId;
    return allWeightSets
        .where((s) => s.exerciseId == exId)
        .toList()
        .reversed
        .toList();
  }

  /// Cardio sets filtered for the current exercise (most recent first).
  List<CardioSet> get cardioSets {
    final exId = currentExerciseId;
    return allCardioSets
        .where((s) => s.exerciseId == exId)
        .toList()
        .reversed
        .toList();
  }

  /// The most recent `completedAt` timestamp across all sets, or null.
  DateTime? get lastCompletedAt {
    DateTime? latest;
    for (final s in allWeightSets) {
      if (s.completedAt != null &&
          (latest == null || s.completedAt!.isAfter(latest))) {
        latest = s.completedAt;
      }
    }
    for (final s in allCardioSets) {
      if (s.completedAt != null &&
          (latest == null || s.completedAt!.isAfter(latest))) {
        latest = s.completedAt;
      }
    }
    return latest;
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ExerciseDetailNotifier extends Notifier<ExerciseDetailState> {
  final String workoutId;
  final String initialExerciseId;

  ExerciseDetailNotifier({
    required this.workoutId,
    required this.initialExerciseId,
  });

  @override
  ExerciseDetailState build() {
    _loadSets(initialExerciseId: initialExerciseId);
    return const ExerciseDetailState(status: ExerciseDetailStatus.loading);
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Load all sets for this workout and derive exercise IDs.
  ///
  /// When [initialExerciseId] is provided (initial load), the page index
  /// is set to that exercise. When omitted (after mutation), the current
  /// index is preserved.
  Future<void> _loadSets({String? initialExerciseId}) async {
    state = state.copyWith(
      status: ExerciseDetailStatus.loading,
      errorMessage: null,
    );
    try {
      final service = ref.read(setManagementServiceProvider);
      final (allWeight, allCardio) = await service.loadSets(workoutId);

      final ids = service.deriveExerciseIds(
        allWeight,
        allCardio,
        initialExerciseId: initialExerciseId,
      );

      final initialIdx =
          initialExerciseId != null && ids.contains(initialExerciseId)
          ? ids.indexOf(initialExerciseId)
          : state.currentIndex < ids.length
          ? state.currentIndex
          : 0;

      final last = _findLastCompletedAt(allWeight, allCardio);

      state = ExerciseDetailState(
        status: ExerciseDetailStatus.data,
        allWeightSets: allWeight,
        allCardioSets: allCardio,
        exerciseIds: ids,
        currentIndex: initialIdx,
        isResting: last != null,
        restStartedAt: last,
      );
    } catch (e) {
      state = state.copyWith(
        status: ExerciseDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reload sets preserving the current page index.
  /// Called by the screen after any set mutation.
  Future<void> reload() async {
    await _loadSets();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Switch to the exercise at [index] and reset the rest timer.
  void selectExercise(int index) {
    state = state.copyWith(
      currentIndex: index,
      isResting: false,
      clearRestStartedAt: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Rest timer
  // ---------------------------------------------------------------------------

  /// Dismiss the rest timer (user tapped "Skip").
  void dismissRest() {
    state = state.copyWith(isResting: false, clearRestStartedAt: true);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DateTime? _findLastCompletedAt(
    List<WeightSet> weightSets,
    List<CardioSet> cardioSets,
  ) {
    DateTime? latest;
    for (final s in weightSets) {
      if (s.completedAt != null &&
          (latest == null || s.completedAt!.isAfter(latest))) {
        latest = s.completedAt;
      }
    }
    for (final s in cardioSets) {
      if (s.completedAt != null &&
          (latest == null || s.completedAt!.isAfter(latest))) {
        latest = s.completedAt;
      }
    }
    return latest;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Family provider scoped to `(workoutId, initialExerciseId)`.
final exerciseDetailProvider =
    NotifierProvider.family<
      ExerciseDetailNotifier,
      ExerciseDetailState,
      (String, String)
    >((arg) {
      final (workoutId, initialExerciseId) = arg;
      return ExerciseDetailNotifier(
        workoutId: workoutId,
        initialExerciseId: initialExerciseId,
      );
    });
