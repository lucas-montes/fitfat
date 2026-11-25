import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/top_banner.dart';
import '../screens/qr_scan_sheet.dart';
import '../sync_service.dart';

/// Pings the active server's `/health`. False when none is configured.
Future<bool> pingActiveServer(WidgetRef ref) {
  final s = ref.read(settingsProvider);
  return ref
      .read(syncServiceProvider)
      .pingServer(
        s.remoteSyncBaseUrl,
        s.remoteSyncApiKey,
        timeout: Duration(seconds: s.apiTimeoutSeconds),
      );
}

/// Scans a server QR code and applies it to the active server (see
/// `SettingsNotifier.rescanServer`), then checks the server answers and says
/// so in a banner. Returns true when the server is reachable afterwards.
Future<bool> rescanServerQr(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showQrScanSheet(context);
  if (result == null || !context.mounted) return false;
  await ref
      .read(settingsProvider.notifier)
      .rescanServer(result.url, result.apiKey);
  final ok = await pingActiveServer(ref);
  if (context.mounted) {
    showTopBanner(
      context,
      message: ok ? l10n.syncServerUpdated : l10n.syncServerUnreachable,
    );
  }
  return ok;
}

/// The server bottom sheet: status of the active server, rescan QR, test,
/// switch between saved servers, remove one, or add one by hand.
Future<void> showServerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ServerSheet(),
    );

final class _ServerSheet extends ConsumerStatefulWidget {
  const _ServerSheet();

  @override
  ConsumerState<_ServerSheet> createState() => _ServerSheetState();
}

final class _ServerSheetState extends ConsumerState<_ServerSheet> {
  bool? _reachable;
  bool _testing = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _test());
  }

  Future<void> _test() async {
    if (ref.read(settingsProvider).remoteSyncBaseUrl.isEmpty) return;
    setState(() => _testing = true);
    final ok = await pingActiveServer(ref);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _reachable = ok;
    });
  }

  Future<void> _rescan() async {
    await rescanServerQr(context, ref);
    if (mounted) await _test();
  }

  Future<void> _confirmRemove(ServerProfile s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.syncRemoveServerTitle),
        content: Text(l10n.syncRemoveServerBody(s.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsProvider.notifier).deleteServer(s.id);
    if (mounted) await _test();
  }

  Future<void> _addByHand() async {
    final urlCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final result = await showDialog<({String url, String apiKey})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.syncAddServer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: l10n.syncServerUrl,
                hintText: 'http://127.0.0.1:3030',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: InputDecoration(labelText: l10n.syncApiKey),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              final key = keyCtrl.text.trim();
              if (url.isEmpty || key.isEmpty) return;
              Navigator.pop(ctx, (url: url, apiKey: key));
            },
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
    urlCtrl.dispose();
    keyCtrl.dispose();
    if (result == null || !mounted) return;
    final normalized = result.url.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      showTopBanner(context, message: l10n.syncInvalidUrl);
      return;
    }
    if (ref.read(settingsProvider).servers.any((s) => s.url == normalized)) {
      showTopBanner(context, message: l10n.syncServerExists);
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .addServer(normalized, result.apiKey);
    if (mounted) await _test();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final servers = settings.servers;
    final active = settings.activeServer;

    final String status;
    final Color dot;
    if (active == null) {
      status = l10n.syncNoServerYet;
      dot = scheme.outline;
    } else if (_testing || _reachable == null) {
      status = l10n.syncStatusChecking(active.label);
      dot = scheme.outline;
    } else if (_reachable!) {
      status = l10n.syncStatusConnected(active.label);
      dot = scheme.primary;
    } else {
      status = l10n.syncStatusOffline(active.label);
      dot = scheme.error;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          FitFatTokens.spaceL,
          0,
          FitFatTokens.spaceL,
          FitFatTokens.spaceL + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.syncServerSheetTitle,
              style: theme.textTheme.headlineSmall,
            ),
            if (active != null) ...[
              const SizedBox(height: 4),
              Text(
                active.url,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceL),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: _rescan,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(active == null ? l10n.syncScanQr : l10n.syncRescanQr),
            ),
            if (active != null) ...[
              const SizedBox(height: FitFatTokens.spaceS),
              Text(
                l10n.syncRescanQrHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceM),
              OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: Text(l10n.syncTestConnection),
              ),
            ],
            const SizedBox(height: FitFatTokens.spaceL),
            if (servers.isNotEmpty)
              Text(
                l10n.syncServers,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            for (final s in servers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s.id == active?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: s.id == active?.id ? scheme.primary : null,
                ),
                title: Text(s.label),
                subtitle: Text(s.url),
                trailing: servers.length <= 1
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonRemove,
                        onPressed: () => _confirmRemove(s),
                      ),
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setActiveServer(s.id);
                  if (mounted) await _test();
                },
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addByHand,
                icon: const Icon(Icons.add),
                label: Text(l10n.syncAddServerByHand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
