import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../exercise/providers/seance.dart';

/// Floating pill that appears at the bottom-right when a seance is running.
/// Tap to open the current seance screen.
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
      final seance = ref.read(activeSeanceProvider);
      if (seance != null) {
        setState(() {
          _elapsed = DateTime.now().difference(seance.startedAt);
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
    final seance = ref.watch(activeSeanceProvider);
    if (seance == null) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/current-seance'),
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
