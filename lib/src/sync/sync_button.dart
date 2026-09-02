import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/widgets/top_banner.dart';
import 'sync_models.dart';

/// Button that runs a sync pull. Shows a spinner while in flight and an error
/// banner if the pull fails; per the notebook rule it stays silent on success
/// (no success noise). When [label] is provided it renders an icon+text
/// button; otherwise it falls back to an icon-only button (tooltip only).
final class SyncButton extends ConsumerStatefulWidget {
  final Future<SyncResult> Function() run;
  final String tooltip;
  final Widget? label;

  const SyncButton({
    super.key,
    required this.run,
    required this.tooltip,
    this.label,
  });

  @override
  ConsumerState<SyncButton> createState() => _SyncButtonState();
}

final class _SyncButtonState extends ConsumerState<SyncButton> {
  bool _syncing = false;

  Widget _icon(BuildContext context) => _syncing
      ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        )
      : const Icon(Icons.sync);

  @override
  Widget build(BuildContext context) {
    if (widget.label != null) {
      return OutlinedButton.icon(
        onPressed: _syncing ? null : _onPressed,
        icon: _icon(context),
        label: widget.label!,
      );
    }
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _syncing ? null : _onPressed,
      icon: _icon(context),
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
