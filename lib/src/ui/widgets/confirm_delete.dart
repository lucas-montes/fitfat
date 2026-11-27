import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'top_banner.dart';

/// Something else that is removed along with the item, e.g. ("Sets", 18).
typedef CascadeCount = ({String label, int count});

/// The app's single delete flow.
///
/// * Nothing else affected ([cascade] empty or all zero): deletes right away
///   and shows an Undo banner (when [undo] is given).
/// * Other data goes too: shows a sheet listing what else is deleted, and
///   deletes only after the user confirms.
///
/// * [alwaysConfirm]: show the sheet even when nothing else goes (for deletes
///   that cannot be undone).
///
/// Returns true when the item was deleted.
Future<bool> confirmDelete(
  BuildContext context, {
  required String itemName,
  required Future<void> Function() delete,
  List<CascadeCount> cascade = const [],
  Future<void> Function()? undo,
  String? confirmLabel,
  bool alwaysConfirm = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final overlay = Overlay.of(context);
  final affected = cascade.where((c) => c.count > 0).toList();

  // Irreversible deletes with nothing else affected still ask first.
  if (affected.isNotEmpty || alwaysConfirm) {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => _CascadeSheet(
        title: l10n.commonDeleteTitle(itemName),
        alsoDeleted: l10n.commonAlsoDeleted,
        items: affected,
        confirmLabel: confirmLabel ?? l10n.commonDelete,
        cancelLabel: l10n.commonCancel,
      ),
    );
    if (ok != true) return false;
  }

  await delete();
  showTopBannerOverlay(
    overlay,
    message: l10n.commonDeleted(itemName),
    displayDuration: const Duration(seconds: 4),
    actionLabel: undo == null ? null : l10n.commonUndo,
    onAction: undo == null ? null : () => undo(),
  );
  return true;
}

class _CascadeSheet extends StatelessWidget {
  const _CascadeSheet({
    required this.title,
    required this.alsoDeleted,
    required this.items,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String alsoDeleted;
  final List<CascadeCount> items;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFatTokens.spaceXl,
          0,
          FitFatTokens.spaceXl,
          FitFatTokens.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FitFatTokens.spaceM,
          children: [
            Row(
              spacing: FitFatTokens.spaceM,
              children: [
                CircleAvatar(
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.error,
                  child: const Icon(Icons.delete_outline),
                ),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (items.isNotEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(FitFatTokens.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FitFatTokens.spaceS,
                    children: [
                      Text(
                        alsoDeleted.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                        ),
                      ),
                      for (final c in items)
                        Row(
                          children: [
                            Expanded(child: Text(c.label)),
                            Text(
                              '${c.count}',
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}
