import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../entity_labels.dart';
import '../sync_all.dart';
import '../sync_run.dart';
import 'server_sheet.dart';

/// The cloud chip in the dashboard top bar. Shows when the phone last synced,
/// a spinner while syncing, or a red cloud when the last sync failed. Tapping
/// it opens [showSyncSheet].
class SyncChip extends ConsumerWidget {
  const SyncChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final run = ref.watch(syncRunProvider);
    final settings = ref.watch(settingsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final last = prefs.getInt(lastFullSyncPrefKey) ?? 0;
    final noServer = settings.remoteSyncBaseUrl.isEmpty;

    final Widget icon;
    final String? label;
    Color? color;
    if (run.running) {
      icon = const SizedBox.square(
        dimension: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      label = null;
    } else if (run.phase == SyncRunPhase.failed) {
      color = scheme.error;
      icon = Icon(Icons.cloud_off_outlined, size: 16, color: color);
      label = null;
    } else if (noServer) {
      icon = Icon(
        Icons.cloud_off_outlined,
        size: 16,
        color: scheme.onSurfaceVariant,
      );
      label = null;
    } else {
      icon = const Icon(Icons.cloud_done_outlined, size: 16);
      label = last == 0 ? l10n.syncNever : lastSyncedLabel(l10n, last);
    }

    return Semantics(
      button: true,
      label: l10n.syncHubTitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceXs),
        child: ActionChip(
          avatar: icon,
          label: label == null ? const SizedBox.shrink() : Text(label),
          labelPadding: label == null
              ? EdgeInsets.zero
              : const EdgeInsets.only(right: FitFatTokens.spaceXs),
          side: BorderSide(
            color: color?.withValues(alpha: 0.5) ?? scheme.outlineVariant,
          ),
          visualDensity: VisualDensity.compact,
          onPressed: () => showSyncSheet(context),
        ),
      ),
    );
  }
}

/// Short sheet with the server status, last sync, any failure, and a Sync
/// now button, so syncing does not require leaving the dashboard.
Future<void> showSyncSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => const _SyncSheet(),
);

class _SyncSheet extends ConsumerWidget {
  const _SyncSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFatTokens.spaceL,
          0,
          FitFatTokens.spaceL,
          FitFatTokens.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FitFatTokens.spaceM,
          children: [
            const SyncStatusPanel(),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/sync');
              },
              child: Text(l10n.syncOpen, style: theme.textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/// Server card + last sync + Sync now, with live progress and the failure
/// (and its fixes) in place. Shared by the dashboard sheet and the top of
/// the Sync screen.
class SyncStatusPanel extends ConsumerWidget {
  const SyncStatusPanel({
    super.key,
    this.reachable,
    this.checking = false,
    this.onServerChanged,
  });

  /// Result of the Sync screen's server ping, when it has one.
  final bool? reachable;

  /// The Sync screen is pinging the server right now.
  final bool checking;

  /// Called after the server was switched or rescanned, so the caller can
  /// ping it again.
  final VoidCallback? onServerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final run = ref.watch(syncRunProvider);
    final settings = ref.watch(settingsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final last = prefs.getInt(lastFullSyncPrefKey) ?? 0;
    final server = settings.activeServer?.label ?? l10n.syncNoServerYet;
    final noServer = settings.remoteSyncBaseUrl.isEmpty;
    final offline = run.unreachable || reachable == false;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final dotColor = noServer
        ? scheme.outline
        : offline
        ? scheme.error
        : reachable == true || run.phase == SyncRunPhase.ok
        ? theme.extension<FitFatColors>()!.success
        : scheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceM,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            // Tap to switch server or add one.
            onTap: () async {
              await showServerSheet(context);
              onServerChanged?.call();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FitFatTokens.spaceM,
                FitFatTokens.spaceM,
                FitFatTokens.spaceXs,
                FitFatTokens.spaceM,
              ),
              child: Row(
                spacing: FitFatTokens.spaceM,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.3),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          noServer
                              ? l10n.syncNoServerYet
                              : offline
                              ? l10n.syncCantReach(server)
                              : server,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          checking
                              ? l10n.syncStatusChecking(server)
                              : l10n.syncLastSync(lastSyncedLabel(l10n, last)),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.syncRescanQrTooltip,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      await rescanAfterFailure(context, ref);
                      onServerChanged?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (run.running) ...[
          Text(
            run.step == null
                ? l10n.syncStep('…')
                : (run.pushing ? l10n.syncSending : l10n.syncFetching)(
                    syncEntityLabel(l10n, run.step!),
                  ),
            style: theme.textTheme.bodyMedium,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
            child: LinearProgressIndicator(value: run.progress, minHeight: 6),
          ),
        ] else if (run.phase == SyncRunPhase.failed && run.error != null)
          Container(
            padding: const EdgeInsets.all(FitFatTokens.spaceM),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FitFatTokens.spaceS,
              children: [
                Icon(Icons.error_outline, color: scheme.error, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: FitFatTokens.spaceXs,
                    children: [
                      Text(run.error!, style: theme.textTheme.bodyMedium),
                      if (run.unreachable)
                        Text(l10n.syncCantReachHint, style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Row(
          spacing: FitFatTokens.spaceS,
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: run.running ? null : () => runFullSync(context, ref),
                icon: const Icon(Icons.sync, size: 18),
                label: Text(
                  run.phase == SyncRunPhase.failed
                      ? l10n.commonRetry
                      : l10n.syncNow,
                ),
              ),
            ),
            if (offline && !run.running)
              OutlinedButton.icon(
                onPressed: () => rescanAfterFailure(context, ref),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: Text(l10n.syncRescan),
              ),
          ],
        ),
      ],
    );
  }
}
