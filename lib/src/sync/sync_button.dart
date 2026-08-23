import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/widgets/top_banner.dart';
import 'sync_models.dart';

/// Icon button that runs a sync pull. Shows a spinner while in flight and an
/// error banner if the pull fails; per the notebook rule it stays silent on
/// success (no success noise).
final class SyncButton extends ConsumerStatefulWidget {
  final Future<SyncResult> Function() run;
  final String tooltip;

  const SyncButton({super.key, required this.run, required this.tooltip});

  @override
  ConsumerState<SyncButton> createState() => _SyncButtonState();
}

final class _SyncButtonState extends ConsumerState<SyncButton> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _syncing ? null : _onPressed,
      icon: _syncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
    );
  }

  Future<void> _onPressed() async {
    setState(() => _syncing = true);
    final result = await widget.run();
    if (!mounted) return;
    setState(() => _syncing = false);
    if (!result.ok && result.error != null) {
      showTopBanner(context, message: result.error!);
    }
  }
}
