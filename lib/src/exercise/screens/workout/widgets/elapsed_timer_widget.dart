import 'dart:async';

import 'package:flutter/material.dart';

/// Format a [Duration] as HH:MM:SS or MM:SS.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// A widget that displays a live-ticking elapsed time since [startedAt].
class ElapsedTimerWidget extends StatefulWidget {
  final DateTime startedAt;
  final TextStyle? style;

  const ElapsedTimerWidget({super.key, required this.startedAt, this.style});

  @override
  State<ElapsedTimerWidget> createState() => _ElapsedTimerWidgetState();
}

class _ElapsedTimerWidgetState extends State<ElapsedTimerWidget> {
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

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    return Text(formatDuration(elapsed), style: widget.style);
  }
}
