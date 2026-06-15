import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../providers/exercises.dart';

class RestTimerOverlay extends ConsumerStatefulWidget {
  const RestTimerOverlay({super.key, required this.restSeconds});

  final int restSeconds;

  @override
  ConsumerState<RestTimerOverlay> createState() => RestTimerOverlayState();
}

class RestTimerOverlayState extends ConsumerState<RestTimerOverlay> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(restTimerProvider.notifier).startRest(widget.restSeconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timer = ref.watch(restTimerProvider);

    if (!timer.isRunning && !timer.isFinished) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: timer.isFinished
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                timer.isFinished ? l10n.restOver : l10n.restTimer,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                timer.isFinished
                    ? l10n.getReadyNextSet
                    : '${timer.remainingSeconds}s',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!timer.isFinished) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: timer.progress),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(restTimerProvider.notifier).skipRest(),
                  child: Text(l10n.skip),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
