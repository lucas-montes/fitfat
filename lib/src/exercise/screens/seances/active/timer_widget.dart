import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerWidget extends ConsumerStatefulWidget {
  const TimerWidget({required this.startedAt, super.key});

  final DateTime startedAt;

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = Duration.zero;
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(widget.startedAt));
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _elapsed.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;
    final timeText = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '$minutes:${seconds.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        timeText,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
