import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../database/providers.dart';
import '../../services/logger.dart';

final _log = logger('exercise_seance');

final exerciseListProvider =
    NotifierProvider<ExerciseListNotifier, List<ExerciseDefinition>>(
      ExerciseListNotifier.new,
    );

/// Manages the global exercise library.
///
/// **State**: A list of all available exercises.
/// **Source**: Loaded from the database on initialization.
/// **Usage**: Provides the complete exercise catalog for UI widgets to display
///           exercise options when adding exercises to a seance. Watched by
///           exercise pickers, search filters, and dropdown menus.
class ExerciseListNotifier extends Notifier<List<ExerciseDefinition>> {
  @override
  List<ExerciseDefinition> build() {
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.getAllExercises();
      if (rows.isEmpty) return;
      state = rows
          .map(
            (exercise) => ExerciseDefinition(
              id: exercise.id,
              name: exercise.name,
              category: exercise.category,
              type: exercise.type,
              met: exercise.met,
            ),
          )
          .toList();
    } catch (e, stack) {
      _log.warning('Failed to load exercises from database', e, stack);
    }
  }
}

/// Rest timer state
class RestTimerState {
  const RestTimerState({
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.isRunning = false,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  bool get isFinished => isRunning && remainingSeconds <= 0;
  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const RestTimerState();
  }

  void startRest(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        state = RestTimerState(
          remainingSeconds: 0,
          totalSeconds: state.totalSeconds,
          isRunning: false,
        );
        HapticFeedback.heavyImpact();
      } else {
        state = RestTimerState(
          remainingSeconds: remaining,
          totalSeconds: state.totalSeconds,
          isRunning: true,
        );
      }
    });
  }

  void skipRest() {
    _timer?.cancel();
    state = const RestTimerState();
  }
}
