import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rest timer state.
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
