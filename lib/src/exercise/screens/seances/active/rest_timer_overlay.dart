import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/exercise.dart';
import '../../../providers/exercises.dart';

class RestTimerOverlay extends ConsumerStatefulWidget {
  const RestTimerOverlay({super.key, required this.seance});

  final Seance seance;

  @override
  ConsumerState<RestTimerOverlay> createState() => RestTimerOverlayState();
}

class RestTimerOverlayState extends ConsumerState<RestTimerOverlay> {
  @override
  void initState() {
    super.initState();
    final restSeconds = widget.seance.restBetweenSets.inSeconds;
    Future.microtask(() {
      ref.read(restTimerProvider.notifier).startRest(restSeconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timer = ref.watch(restTimerProvider);
    if (!timer.isRunning && timer.remainingSeconds == 0) {
      return const SizedBox.shrink();
    }

    final minutes = timer.remainingSeconds ~/ 60;
    final seconds = timer.remainingSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        color: timer.isFinished
            ? Colors.green.withAlpha(26)
            : Colors.orange.withAlpha(26),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.timer, size: 20),
                  Text(
                    l10n.restTimer,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(restTimerProvider.notifier).skipRest(),
                    child: Text(l10n.skip),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                timer.isFinished
                    ? l10n.restOver
                    : '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: timer.isFinished ? Colors.green : null,
                ),
              ),
              if (timer.isFinished) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.getReadyNextSet,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: timer.progress,
                color: timer.isFinished ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
