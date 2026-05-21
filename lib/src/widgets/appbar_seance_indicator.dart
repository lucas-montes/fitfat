import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/exercise_providers.dart';
import '../screens/exercise/current_seance_screen.dart'
    show CurrentSeanceScreen;

class SeanceAppBarAction extends ConsumerStatefulWidget {
  const SeanceAppBarAction({super.key});

  @override
  ConsumerState<SeanceAppBarAction> createState() => _SeanceAppBarActionState();
}

class _SeanceAppBarActionState extends ConsumerState<SeanceAppBarAction> {
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

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Cancel seance',
            onPressed: () {
              ref.read(activeSeanceProvider.notifier).cancelSeance();
            },
          ),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const CurrentSeanceScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _format(_elapsed),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
