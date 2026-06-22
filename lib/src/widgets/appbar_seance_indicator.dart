import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../exercise/providers/active_workout.dart';

/// Floating pill that appears at the bottom-right when a workout is running.
/// Tap to open the current workout screen.
/// Rendered in AppShell so it covers all tabs.
class SeanceFloatingPill extends ConsumerStatefulWidget {
  const SeanceFloatingPill({super.key});

  @override
  ConsumerState<SeanceFloatingPill> createState() => _SeanceFloatingPillState();
}

class _SeanceFloatingPillState extends ConsumerState<SeanceFloatingPill> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final workout = ref.read(activeWorkoutProvider).asData?.value;
      if (workout != null && workout.startedAt != null) {
        setState(() {
          _elapsed = DateTime.now().difference(workout.startedAt!);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(activeWorkoutProvider);
    final workout = workoutAsync.asData?.value;
    if (workout == null || !workout.isActive) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/active-workout'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                _format(_elapsed),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
