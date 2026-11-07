import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Tracks the currently visible banner so a new one replaces the previous,
/// matching the old `ScaffoldMessenger` "replace current" behavior.
OverlayEntry? _currentBanner;

/// Shows a compact top-anchored banner that auto-dismisses after
/// [displayDuration] (default 2s) and replaces any previously shown banner.
///
/// An optional [actionLabel]/[onAction] renders a tappable button (e.g. "Undo")
/// that runs [onAction] and then dismisses.
void showTopBanner(
  BuildContext context, {
  required String message,
  Duration displayDuration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.of(context);
  showTopBannerOverlay(
    overlay,
    message: message,
    displayDuration: displayDuration,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// Overlay-based variant for call sites that need to display a banner after an
/// async gap: capture the [OverlayState] with `Overlay.of(context)` while the
/// context is still valid, then call this after the await without touching the
/// (possibly stale) `BuildContext`.
void showTopBannerOverlay(
  OverlayState overlay, {
  required String message,
  Duration displayDuration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final scheme = Theme.of(overlay.context).colorScheme;
  _currentBanner?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopBannerWidget(
      scheme: scheme,
      message: message,
      displayDuration: displayDuration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismissed: () {
        if (_currentBanner == entry) _currentBanner = null;
        entry.remove();
      },
    ),
  );
  _currentBanner = entry;
  overlay.insert(entry);
}

class _TopBannerWidget extends StatefulWidget {
  const _TopBannerWidget({
    required this.scheme,
    required this.message,
    required this.displayDuration,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  final ColorScheme scheme;
  final String message;
  final Duration displayDuration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted || _dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    _controller.reverse();
    // Remove the overlay entry once the slide-out has finished. This is
    // time-based rather than chained to the ticker so the banner can never
    // get stuck in the overlay if the animation is interrupted.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: FitFatTokens.spaceL,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FitFatTokens.kContentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FitFatTokens.spaceL,
              ),
              child: SlideTransition(
                position: _offset,
                child: Material(
                  color: widget.scheme.inverseSurface,
                  borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FitFatTokens.spaceL,
                      vertical: FitFatTokens.spaceM,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _dismiss,
                            child: Text(
                              widget.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.scheme.onInverseSurface,
                              ),
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null &&
                            widget.onAction != null)
                          TextButton(
                            onPressed: () {
                              widget.onAction?.call();
                              _dismiss();
                            },
                            child: Text(
                              widget.actionLabel!,
                              style: TextStyle(
                                color: widget.scheme.inversePrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
