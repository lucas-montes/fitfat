import 'package:flutter/widgets.dart';

/// Provides the shell's active branch index to [DeferredBranch] widgets.
final class BranchVisibility extends InheritedWidget {
  final int currentIndex;

  const BranchVisibility({
    required this.currentIndex,
    required super.child,
    super.key,
  });

  static int indexOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BranchVisibility>()!
      .currentIndex;

  @override
  bool updateShouldNotify(BranchVisibility oldWidget) =>
      oldWidget.currentIndex != currentIndex;
}

/// Defers a shell branch's first build until it is actually selected, so
/// cold-start only constructs (and fires providers for) the dashboard branch
/// instead of every tab (~3,800-row exercise list, budget, experiments…).
///
/// Once a branch has been visited it builds normally and stays alive inside
/// the shell's IndexedStack — state and scroll positions survive switching,
/// exactly as before. The built-set is static on purpose: it lives for the
/// whole process, matching the shell's lifetime.
final class DeferredBranch extends StatefulWidget {
  final int index;
  final Widget child;

  const DeferredBranch({required this.index, required this.child, super.key});

  @override
  State<DeferredBranch> createState() => _DeferredBranchState();
}

final class _DeferredBranchState extends State<DeferredBranch> {
  static final _built = <int>{};

  @override
  Widget build(BuildContext context) {
    final current = BranchVisibility.indexOf(context);
    if (!_built.contains(widget.index)) {
      if (current != widget.index) return const SizedBox.shrink();
      // First visit of this branch while it is on screen: mark it built.
      _built.add(widget.index);
    }
    return widget.child;
  }
}
