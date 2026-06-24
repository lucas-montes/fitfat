import 'dart:async';

import 'package:flutter/material.dart';

/// Shows the elapsed time since the last completed set (rest period).
///
/// Displayed as a card in `secondaryContainer` color above the add-set form.
/// Ticks every second. Has a "Skip" button to dismiss early.
/// Auto-resets when a new set is completed or the user switches exercises.
class RestElapsedCard extends StatefulWidget {
  final DateTime startedAt;
  final VoidCallback onSkip;

  const RestElapsedCard({
    super.key,
    required this.startedAt,
    required this.onSkip,
  });

  @override
  State<RestElapsedCard> createState() => _RestElapsedCardState();
}

class _RestElapsedCardState extends State<RestElapsedCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _elapsed => DateTime.now().difference(widget.startedAt);

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    _formatDuration(_elapsed),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
          ],
        ),
      ),
    );
  }
}
