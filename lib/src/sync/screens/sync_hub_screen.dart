import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../network/api_client.dart';
import '../../database/database_provider.dart' as db;
import '../../exercise/widgets/select_sheet.dart';
import '../repositories/catalog_repository.dart';
import '../../ui/tokens.dart';
import '../../settings/providers/settings.dart';
import '../data_push_service.dart';
import '../local_backup.dart';
import '../personal_pull_service.dart';
import '../sync_refresh.dart';
import '../sync_service.dart';
import 'qr_scan_sheet.dart';
import '../sync_state_store.dart';
import '../phone_log_shipper.dart';
import '../sync_models.dart';
import '../../ui/widgets/top_banner.dart';
import '../entity_labels.dart';

/// Translates raw sync/HTTP failures into the sentence a regular user can act
/// on. Anything unrecognised is shown as-is for power users.
String friendlySyncError(AppLocalizations l10n, String url, String error) {
  final e = error.toLowerCase();
  final unreachable =
      e.contains('timeoutexception') ||
      e.contains('socketexception') ||
      e.contains('connection refused') ||
      e.contains('connection reset') ||
      e.contains('connection closed') ||
      e.contains('failed host lookup');
  if (unreachable) {
    return l10n.syncErrorUnreachable(url);
  }
  if (e.contains('apiexception(405') || e.contains('apiexception(501')) {
    return l10n.syncErrorServerTooOld;
  }
  if (e.contains('apiexception(404')) {
    return l10n.syncErrorUnknownOperation;
  }
  if (e.contains('apiexception(401') || e.contains('apiexception(403')) {
    return l10n.syncErrorKeyRejected;
  }
  if (e.contains('apiexception(413')) {
    return l10n.syncErrorTooLarge;
  }
  if (e.contains('apiexception(5')) {
    return l10n.syncErrorServerInternal;
  }
  return error;
}

/// Ships the phone's recent log lines (including any error just recorded) to
/// the configured server so they appear in the computer's console output.
Future<void> shipPhoneLogs(WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  await PhoneLogShipper.instance.ship(
    baseUrl: settings.remoteSyncBaseUrl,
    apiKey: settings.remoteSyncApiKey,
  );
}

final class SyncHubScreen extends ConsumerWidget {
  const SyncHubScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncHubTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        children: [
          _ServerConfigCard(),
          const SizedBox(height: FitFatTokens.spaceL),
          _SectionCard(
            icon: Icons.cloud_download_outlined,
            title: l10n.syncGlobalPool,
            subtitle: l10n.syncGlobalPoolHint,
            child: _GlobalPoolSection(),
          ),
          const SizedBox(height: FitFatTokens.spaceL),
          _SectionCard(
            icon: Icons.cloud_upload_outlined,
            title: l10n.syncPersonalPool,
            subtitle: l10n.syncPersonalPoolHint,
            child: _PersonalPoolSection(),
          ),
          const SizedBox(height: FitFatTokens.spaceL),
          _SectionCard(
            icon: Icons.backup_outlined,
            title: l10n.syncLocalBackup,
            subtitle: l10n.syncLocalBackupHint,
            child: _LocalBackupSection(),
          ),
        ],
      ),
    );
  }
}

final class _ServerConfigCard extends ConsumerStatefulWidget {
  const _ServerConfigCard();
  @override
  ConsumerState<_ServerConfigCard> createState() => _ServerConfigCardState();
}

final class _ServerConfigCardState extends ConsumerState<_ServerConfigCard> {
  String? _testStatus;
  bool _testing = false;
  final _log = Logger('SyncHub.Server');
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  Future<void> _autoTest(String url, String key) async {
    setState(() {
      _testing = true;
      _testStatus = null;
    });
    final normalizedUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final timeout = Duration(
      seconds: ref.read(settingsProvider).apiTimeoutSeconds,
    );
    _log.info(
      'autoTest url=$normalizedUrl timeout=${timeout.inSeconds}s key=${key.isEmpty ? 'empty' : '***'}',
    );
    Future<void> tryHealthNoAuth() async {
      final httpClient = http.Client();
      final client = HttpApiClient(
        httpClient,
        baseUrl: normalizedUrl,
        timeout: timeout,
      );
      try {
        await client.getJson('/health');
      } finally {
        httpClient.close();
      }
    }

    Future<void> tryHealthAuth() async {
      final httpClient = http.Client();
      final client = HttpApiClient(
        httpClient,
        baseUrl: normalizedUrl,
        timeout: timeout,
      );
      try {
        await client.getJson('/health', headers: authHeaders(key));
      } finally {
        httpClient.close();
      }
    }

    Future<void> tryExercises() async {
      final httpClient = http.Client();
      final client = HttpApiClient(
        httpClient,
        baseUrl: normalizedUrl,
        timeout: timeout,
      );
      try {
        await client.getJson(
          '/exercises',
          headers: authHeaders(key),
          query: {'since': '0'},
        );
      } finally {
        httpClient.close();
      }
    }

    bool success = false;
    try {
      await tryHealthNoAuth();
      if (!mounted) return;
      _log.info('autoTest health (no auth) ok url=$normalizedUrl');
      setState(() => _testStatus = l10n.syncConnected(normalizedUrl));
      success = true;
    } catch (e, st) {
      _log.warning(
        'autoTest health (no auth) failed url=$normalizedUrl',
        e,
        st,
      );
    }
    if (!success) {
      try {
        await tryHealthAuth();
        if (!mounted) return;
        _log.info('autoTest health (auth) ok url=$normalizedUrl');
        setState(() => _testStatus = l10n.syncConnected(normalizedUrl));
        success = true;
      } catch (e, st) {
        _log.warning('autoTest health (auth) failed url=$normalizedUrl', e, st);
      }
    }
    if (!success) {
      try {
        await tryExercises();
        if (!mounted) return;
        _log.info('autoTest exercises ok url=$normalizedUrl');
        setState(() => _testStatus = l10n.syncConnected(normalizedUrl));
        success = true;
      } catch (e2, st2) {
        _log.severe('autoTest failed url=$normalizedUrl', e2, st2);
        if (!mounted) return;
        setState(() => _testStatus = null);
        showTopBanner(
          context,
          message: l10n.syncConnectionFailed(
            friendlySyncError(l10n, normalizedUrl, e2.toString()),
          ),
        );
      }
    }
    if (mounted) setState(() => _testing = false);
  }

  Future<void> _addServerDialog() async {
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
    if (result == null) return;
    final normalized = result.url.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      showTopBanner(context, message: l10n.syncInvalidUrl);
      return;
    }
    if (result.apiKey.isEmpty) {
      showTopBanner(context, message: l10n.syncApiKeyRequired);
      return;
    }
    final notifier = ref.read(settingsProvider.notifier);
    if (ref.read(settingsProvider).servers.any((s) => s.url == normalized)) {
      showTopBanner(context, message: l10n.syncServerExists);
      return;
    }
    await notifier.addServer(normalized, result.apiKey);
    await _autoTest(normalized, result.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final servers = settings.servers;
    final activeId = settings.activeServerId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: FitFatTokens.spaceS),
                Text(l10n.syncServers, style: theme.textTheme.titleMedium),
                const Spacer(),
                if (_testing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_testStatus != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _testStatus!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            Text(
              l10n.syncServersHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            if (servers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.syncNoServers,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final s in servers) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Radio<String>(
                  value: s.id,
                  groupValue:
                      activeId ??
                      (servers.isNotEmpty ? servers.first.id : null),
                  onChanged: (v) async {
                    if (v != null)
                      await ref
                          .read(settingsProvider.notifier)
                          .setActiveServer(v);
                  },
                ),
                title: Text(
                  s.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  s.url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonRemove,
                  onPressed: servers.length <= 1
                      ? null
                      : () async {
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
                          if (confirmed == true)
                            await ref
                                .read(settingsProvider.notifier)
                                .deleteServer(s.id);
                        },
                ),
                onTap: () async => await ref
                    .read(settingsProvider.notifier)
                    .setActiveServer(s.id),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: FitFatTokens.spaceM),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _addServerDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.commonAdd),
                  ),
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await showQrScanSheet(context);
                      if (result == null || !mounted) return;
                      final normalized = result.url.trim().replaceAll(
                        RegExp(r'/+$'),
                        '',
                      );
                      if (ref
                          .read(settingsProvider)
                          .servers
                          .any((s) => s.url == normalized)) {
                        showTopBanner(context, message: l10n.syncServerExists);
                        return;
                      }
                      await ref
                          .read(settingsProvider.notifier)
                          .addServer(normalized, result.apiKey);
                      await _autoTest(normalized, result.apiKey);
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: Text(l10n.syncScanQr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final active = settings.activeServer;
                  if (active == null) {
                    showTopBanner(context, message: l10n.syncNoActiveServer);
                    return;
                  }
                  final key = ref.read(settingsProvider).remoteSyncApiKey;
                  await _autoTest(active.url, key);
                },
                icon: _testing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: Text(l10n.syncTestHealth),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: FitFatTokens.spaceS),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            child,
          ],
        ),
      ),
    );
  }
}

final class _GlobalPoolSection extends ConsumerStatefulWidget {
  const _GlobalPoolSection();
  @override
  ConsumerState<_GlobalPoolSection> createState() => _GlobalPoolSectionState();
}

final class _GlobalPoolSectionState extends ConsumerState<_GlobalPoolSection> {
  bool _busyEx = false;
  bool _busyIng = false;
  bool _busyFx = false;
  bool _busyPickerEx = false;
  bool _busyPickerIng = false;
  final _log = Logger('SyncHub.Global');
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  Future<void> _run(
    Future<SyncResult> Function() fn,
    void Function(bool) setBusy,
  ) async {
    setBusy(true);
    try {
      final result = await fn();
      if (!mounted) return;
      if (!result.ok && result.error != null) {
        _log.warning('sync failed: ${result.error}');
        final msg = friendlySyncError(
          l10n,
          ref.read(settingsProvider).remoteSyncBaseUrl,
          result.error!,
        );
        await shipPhoneLogs(ref);
        if (!mounted) return;
        showTopBanner(context, message: msg);
      } else if (result.ok) {
        _log.info(
          'sync ok updated=${result.updated} deleted=${result.deleted}',
        );
        setState(() {});
      }
    } catch (e, st) {
      _log.severe('sync exception', e, st);
      await shipPhoneLogs(ref);
      if (mounted) {
        showTopBanner(
          context,
          message: friendlySyncError(
            l10n,
            ref.read(settingsProvider).remoteSyncBaseUrl,
            '$e',
          ),
        );
      }
    } finally {
      if (mounted) setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    final state = PrefsSyncStateStore(ref.watch(sharedPreferencesProvider));
    String last(SyncResource r) =>
        l10n.syncLastSync(lastSyncedLabel(l10n, state.getLastSyncedAt(r)));

    final timeout = Duration(seconds: settings.apiTimeoutSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.syncEntityExercises),
          subtitle: Text(last(SyncResource.exercises)),
          trailing: _busyEx
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => _run(
                    () => ref
                        .read(syncServiceProvider)
                        .syncExercises(
                          base,
                          key,
                          endpoint: settings.endpointExercises,
                          timeout: timeout,
                        ),
                    (v) => setState(() => _busyEx = v),
                  ),
                ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.syncEntityIngredients),
          subtitle: Text(last(SyncResource.ingredients)),
          trailing: _busyIng
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => _run(
                    () => ref
                        .read(syncServiceProvider)
                        .syncIngredients(
                          base,
                          key,
                          endpoint: settings.endpointIngredients,
                          timeout: timeout,
                        ),
                    (v) => setState(() => _busyIng = v),
                  ),
                ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.syncEntityCurrencies),
          subtitle: Text(last(SyncResource.currencies)),
          trailing: _busyFx
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => _run(
                    () => ref
                        .read(syncServiceProvider)
                        .syncCurrencies(
                          base,
                          key,
                          settings.baseCurrency,
                          endpoint: settings.endpointCurrencies,
                          timeout: timeout,
                        ),
                    (v) => setState(() => _busyFx = v),
                  ),
                ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        OutlinedButton.icon(
          onPressed: _busyPickerEx
              ? null
              : () => _showExercisePicker(context, ref),
          icon: _busyPickerEx
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.checklist, size: 18),
          label: Text(
            _busyPickerEx ? l10n.commonLoading : l10n.syncSelectExercises,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        OutlinedButton.icon(
          onPressed: _busyPickerIng
              ? null
              : () => _showIngredientPicker(context, ref),
          icon: _busyPickerIng
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.checklist, size: 18),
          label: Text(
            _busyPickerIng ? l10n.commonLoading : l10n.syncSelectIngredients,
          ),
        ),
      ],
    );
  }

  Future<void> _showExercisePicker(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    if (base.isEmpty) {
      showTopBanner(context, message: l10n.syncServerNotConfigured);
      return;
    }
    setState(() => _busyPickerEx = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final timeout = Duration(seconds: settings.apiTimeoutSeconds);
      if (!await svc.pingServer(base, key, timeout: timeout)) {
        if (mounted) {
          showTopBanner(context, message: l10n.syncServerUnreachable);
        }
        return;
      }
      Future<List<DisplayItem>> loadDisplay() async {
        final normalizedBase = base.trim().replaceAll(RegExp(r'/+$'), '');
        final headers = authHeaders(key);
        final entries = await ref
            .read(exerciseCatalogRepositoryProvider)
            .searchHideImported('');
        return [
          for (final d in entries)
            DisplayItem(
              id: d.id,
              name: d.name,
              imagePath: d.hasImage
                  ? '$normalizedBase/exercises/${d.id}.jpg'
                  : null,
              imageHeaders: d.hasImage ? headers : null,
            ),
        ];
      }

      Future<List<DisplayItem>?> refreshDisplay() async {
        final refreshed = await svc.refreshExerciseCatalog(
          base,
          key,
          endpoint: '${settings.endpointExercises}/catalog',
          timeout: timeout,
        );
        if (!mounted) return null;
        if (!refreshed.ok) {
          showTopBanner(
            context,
            message: friendlySyncError(l10n, 'server', refreshed.error!),
          );
          return null;
        }
        return loadDisplay();
      }

      final displayItems = await loadDisplay();
      if (!mounted) return;
      if (displayItems.isEmpty) {
        showTopBanner(context, message: l10n.syncNoExercisesOnServer);
        return;
      }
      final selected = await showSelectSheet(
        context,
        items: displayItems,
        initialSelected: const {},
        title: l10n.syncSelectServerExercises,
        hint: l10n.syncSearchServerExercises,
        refreshTooltip: l10n.syncRefreshList,
        onRefresh: refreshDisplay,
      );
      if (selected == null || selected.isEmpty) return;
      if (!context.mounted) return;
      final result = await svc.importSelectedExercises(
        base,
        key,
        selected,
        endpoint: settings.endpointExercises,
        timeout: timeout,
      );
      if (!mounted) return;
      if (!result.ok && result.error != null) {
        showTopBanner(context, message: result.error!);
        return;
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _busyPickerEx = false);
    }
  }

  Future<void> _showIngredientPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settings = ref.read(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    if (base.isEmpty) {
      showTopBanner(context, message: l10n.syncServerNotConfigured);
      return;
    }
    setState(() => _busyPickerIng = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final timeout = Duration(seconds: settings.apiTimeoutSeconds);
      if (!await svc.pingServer(base, key, timeout: timeout)) {
        if (mounted) {
          showTopBanner(context, message: l10n.syncServerUnreachable);
        }
        return;
      }
      Future<List<DisplayItem>?> refreshDisplay() async {
        final refreshed = await svc.refreshIngredientCatalog(
          base,
          key,
          endpoint: '${settings.endpointIngredients}/catalog',
          timeout: timeout,
        );
        if (!mounted) return null;
        if (!refreshed.ok) {
          showTopBanner(
            context,
            message: friendlySyncError(l10n, 'server', refreshed.error!),
          );
          return null;
        }
        return ref
            .read(ingredientCatalogRepositoryProvider)
            .searchHideImported('');
      }

      final displayItems = await ref
          .read(ingredientCatalogRepositoryProvider)
          .searchHideImported('');
      if (!mounted) return;
      if (displayItems.isEmpty) {
        showTopBanner(context, message: l10n.syncNoIngredientsOnServer);
        return;
      }
      final selected = await showSelectSheet(
        context,
        items: displayItems,
        initialSelected: const {},
        title: l10n.syncSelectServerIngredients,
        hint: l10n.syncSearchServerIngredients,
        refreshTooltip: l10n.syncRefreshList,
        onRefresh: refreshDisplay,
      );
      if (selected == null || selected.isEmpty) return;
      if (!context.mounted) return;
      final result = await svc.importSelectedIngredients(
        base,
        key,
        selected,
        endpoint: settings.endpointIngredients,
        timeout: timeout,
      );
      if (!mounted) return;
      if (!result.ok && result.error != null) {
        showTopBanner(context, message: result.error!);
        return;
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _busyPickerIng = false);
    }
  }
}

final class _PersonalPoolSection extends ConsumerStatefulWidget {
  const _PersonalPoolSection();
  @override
  ConsumerState<_PersonalPoolSection> createState() =>
      _PersonalPoolSectionState();
}

final class _PersonalPoolSectionState
    extends ConsumerState<_PersonalPoolSection> {
  final Map<String, bool> _busy = {};
  bool _pushingAll = false;
  bool _pullingAll = false;
  bool _isBusy(String key) => _busy[key] ?? false;
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  void _setBusy(String key, bool v) => setState(() => _busy[key] = v);

  /// Dependency order for both directions.
  ///
  /// Tags go first so links can name them; exercises go before workouts and
  /// templates because those reference exercise ids (the server enforces the
  /// foreign key on push). Stores precede ingredients (their prices name a
  /// store), ingredients precede foods, and foods precede meals: the
  /// server skips a logged food whose recipe it does not know yet, and budget
  /// accounts precede transactions for the same reason.
  static const _order = [
    'Tags',
    'Exercises',
    'Tasks',
    'Notes',
    'Goals',
    'Workouts',
    'Templates',
    'Stores',
    'Ingredients',
    'Foods',
    'Meals',
    'Body',
    'Budget',
    'Transactions',
    'Receipts',
  ];

  /// Entities the phone only pulls. Accounts and transactions are the
  /// server's: the desktop and the statement imports make them, and a push
  /// would put the phone's stale copy back over them.
  static const _pullOnly = {'Budget', 'Transactions'};

  /// Entities the phone only pushes. A receipt is sent, parsed by the server
  /// and forgotten here; pulling would only bring the forgotten back.
  static const _pushOnly = {'Receipts'};

  /// Pull-all deliberately skips the catalogue. Workouts and templates bring
  /// only the exercises they reference (see [_importRelatedExercises]); the
  /// rest arrive through the exercise search.
  static final _pullOrder = List<String>.unmodifiable(
    _order.where((entity) => entity != 'Exercises'),
  );

  static const _entities = [
    ('Tags', Icons.sell_outlined),
    ('Exercises', Icons.directions_run),
    ('Tasks', Icons.checklist),
    ('Notes', Icons.note_alt_outlined),
    ('Goals', Icons.flag_outlined),
    ('Workouts', Icons.fitness_center),
    ('Templates', Icons.view_module_outlined),
    ('Stores', Icons.storefront_outlined),
    ('Ingredients', Icons.egg_outlined),
    ('Foods', Icons.local_grocery_store_outlined),
    ('Meals', Icons.restaurant_outlined),
    ('Body', Icons.monitor_weight_outlined),
    ('Budget', Icons.account_balance_wallet_outlined),
    ('Transactions', Icons.swap_horiz),
    ('Receipts', Icons.receipt_long_outlined),
  ];

  /// Pushes one entity. Returns the failure message, or null on success.
  Future<String?> _pushOne(String entity, {bool announce = true}) async {
    _setBusy(entity, true);
    try {
      final res = await pushDataType(ref, _entityToType(entity));
      // Ship diagnostics either way so a failure is visible on the computer.
      await shipPhoneLogs(ref);
      if (!mounted) return null;
      if (res.ok) {
        setState(() {});
        return null;
      }
      final message = l10n.syncCouldNotPush(
        syncEntityLabel(l10n, entity),
        friendlySyncError(
          l10n,
          ref.read(settingsProvider).remoteSyncBaseUrl,
          res.error ?? l10n.syncUnknownError,
        ),
      );
      if (announce) showTopBanner(context, message: message);
      return message;
    } catch (e) {
      await shipPhoneLogs(ref);
      final message = friendlySyncError(
        l10n,
        ref.read(settingsProvider).remoteSyncBaseUrl,
        '$e',
      );
      if (mounted && announce) showTopBanner(context, message: message);
      return message;
    } finally {
      if (mounted) _setBusy(entity, false);
    }
  }

  /// Pulls one entity. Returns the failure message, or null on success.
  Future<String?> _pullOne(String entity, {bool announce = true}) async {
    _setBusy(entity, true);
    try {
      final res = await pullDataType(ref, _entityToType(entity));
      // Ship diagnostics either way so a failure is visible on the computer.
      await shipPhoneLogs(ref);
      if (!mounted) return null;
      if (res.ok) {
        // A single pull can touch any table, so refresh every cached list.
        // Pull-all does this once at the end.
        if (announce) invalidateAllData(ref);
        setState(() {});
        return null;
      }
      final message = l10n.syncCouldNotPull(
        syncEntityLabel(l10n, entity),
        friendlySyncError(
          l10n,
          ref.read(settingsProvider).remoteSyncBaseUrl,
          res.error ?? l10n.syncUnknownError,
        ),
      );
      if (announce) showTopBanner(context, message: message);
      return message;
    } catch (e) {
      await shipPhoneLogs(ref);
      final message = friendlySyncError(
        l10n,
        ref.read(settingsProvider).remoteSyncBaseUrl,
        '$e',
      );
      if (mounted && announce) showTopBanner(context, message: message);
      return message;
    } finally {
      if (mounted) _setBusy(entity, false);
    }
  }

  /// Mirrors the phone's full state onto the server, in dependency order.
  /// Stops at the first failure — later entities may reference the failed one.
  Future<void> _pushAll() async {
    setState(() => _pushingAll = true);
    try {
      for (final entity in _order) {
        if (!mounted) return;
        if (_pullOnly.contains(entity)) continue;
        final error = await _pushOne(entity, announce: false);
        if (error != null) {
          if (mounted) showTopBanner(context, message: error);
          return;
        }
      }
    } finally {
      if (mounted) setState(() => _pushingAll = false);
    }
  }

  /// Mirrors the server's full state onto the phone, in dependency order.
  /// Keeps going after a failure so one bad endpoint cannot block the rest.
  Future<void> _pullAll() async {
    setState(() => _pullingAll = true);
    final failures = <String>[];
    try {
      for (final entity in _pullOrder) {
        if (!mounted) return;
        if (_pushOnly.contains(entity)) continue;
        final error = await _pullOne(entity, announce: false);
        if (error != null) failures.add(entity);
      }
      if (!mounted) return;
      await _importRelatedExercises(failures);
      if (!mounted) return;
      // Every entity just wrote to the database; refresh the tabs once rather
      // than after each pull.
      invalidateAllData(ref);
      if (failures.isNotEmpty) {
        showTopBanner(
          context,
          message: l10n.syncPulledWithErrors(
            failures.map((e) => syncEntityLabel(l10n, e)).join(', '),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pullingAll = false);
    }
  }

  /// Imports the exercise definitions referenced by the workouts and template
  /// blueprints that just landed. The catalogue is never pulled in bulk here:
  /// only ids the phone does not already have are fetched, one by one, through
  /// the selective import path (which also downloads their media).
  Future<void> _importRelatedExercises(List<String> failures) async {
    // Read everything up front: the screen can be disposed while the queries
    // and downloads below are in flight, and a `ref.read` after that throws.
    final database = ref.read(db.databaseProvider);
    final settings = ref.read(settingsProvider);
    final sync = ref.read(syncServiceProvider);
    final rows = await database.customSelect('''
      SELECT DISTINCT we.exercise_id
      FROM workout_exercises we
      JOIN workouts w ON w.id = we.workout_id
      WHERE w.deleted_at IS NULL
        AND we.exercise_id NOT IN (SELECT id FROM exercises)
      UNION
      SELECT DISTINCT wte.exercise_id
      FROM workout_template_exercises wte
      JOIN workout_templates wt ON wt.id = wte.template_id
      WHERE wt.deleted_at IS NULL
        AND wte.exercise_id NOT IN (SELECT id FROM exercises)
    ''').get();
    final ids = {for (final row in rows) row.read<String>('exercise_id')};
    if (ids.isEmpty) return;

    final result = await sync.importSelectedExercises(
      settings.remoteSyncBaseUrl,
      settings.remoteSyncApiKey,
      ids,
      endpoint: settings.endpointExercises,
      timeout: Duration(seconds: settings.apiTimeoutSeconds),
    );
    if (!result.ok) failures.add(kRelatedExercisesEntity);
  }

  String _entityToType(String e) => switch (e) {
    'Tags' => 'tags',
    'Exercises' => 'exercises',
    'Tasks' => 'tasks',
    'Notes' => 'notes',
    'Goals' => 'goals',
    'Workouts' => 'workouts',
    'Templates' => 'templates',
    'Meals' => 'meals',
    'Body' => 'bodyMetrics',
    'Budget' => 'budgetAccounts',
    'Transactions' => 'transactions',
    'Receipts' => 'receiptPictures',
    'Stores' => 'stores',
    'Ingredients' => 'ingredients',
    'Foods' => 'foods',
    _ => 'tasks',
  };

  @override
  Widget build(BuildContext context) {
    final state = PrefsSyncStateStore(ref.watch(sharedPreferencesProvider));
    String last(SyncResource? r) => l10n.syncLastSync(
      r == null ? '—' : lastSyncedLabel(l10n, state.getLastSyncedAt(r)),
    );

    SyncResource? resourceOf(String entity) => switch (entity) {
      'Tags' => SyncResource.tags,
      'Exercises' => SyncResource.exercises,
      'Tasks' => SyncResource.tasks,
      'Notes' => SyncResource.notes,
      'Goals' => SyncResource.goals,
      'Workouts' => SyncResource.workouts,
      'Templates' => SyncResource.templates,
      'Meals' => SyncResource.meals,
      'Body' => SyncResource.bodyMetrics,
      'Budget' => SyncResource.budgetAccounts,
      'Transactions' => SyncResource.transactions,
      'Receipts' => SyncResource.receipts,
      'Stores' => SyncResource.stores,
      'Ingredients' => SyncResource.ingredients,
      'Foods' => SyncResource.foods,
      _ => null,
    };
    return FutureBuilder<Map<String, int>>(
      future: _counts(ref),
      builder: (ctx, snap) {
        final counts = snap.data ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (name, icon) in _entities) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  '${syncEntityLabel(l10n, name)} · ${counts[name] ?? 0}',
                ),
                subtitle: Text(last(resourceOf(name))),
                trailing: _isBusy(name)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_pullOnly.contains(name)) ...[
                            IconButton(
                              icon: const Icon(Icons.cloud_upload_outlined),
                              tooltip: l10n.syncPushEntity(
                                syncEntityLabel(l10n, name),
                              ),
                              onPressed: () => _pushOne(name),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (!_pushOnly.contains(name))
                            IconButton(
                              icon: Icon(
                                name == 'Exercises'
                                    ? Icons.sync
                                    : Icons.cloud_download_outlined,
                              ),
                              tooltip: name == 'Exercises'
                                  ? l10n.syncExerciseUpdates
                                  : l10n.syncPullEntity(
                                      syncEntityLabel(l10n, name),
                                    ),
                              onPressed: () => _pullOne(name),
                            ),
                        ],
                      ),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: FitFatTokens.spaceM),
            Wrap(
              spacing: FitFatTokens.spaceS,
              runSpacing: FitFatTokens.spaceS,
              children: [
                FilledButton.icon(
                  onPressed: _pushingAll || _pullingAll ? null : _pushAll,
                  icon: _pushingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(l10n.syncPushAll),
                ),
                OutlinedButton.icon(
                  onPressed: _pushingAll || _pullingAll ? null : _pullAll,
                  icon: _pullingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download, size: 18),
                  label: Text(l10n.syncPullAll),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _counts(WidgetRef ref) async {
    final dbInst = ref.read(db.databaseProvider);
    final tasks = await dbInst.select(dbInst.tasks).get();
    final notes = await dbInst.select(dbInst.notes).get();
    final goals = await dbInst.select(dbInst.goals).get();
    final workouts = await dbInst.select(dbInst.workouts).get();
    final templates = await dbInst.select(dbInst.workoutTemplates).get();
    final meals = await dbInst.select(dbInst.meals).get();
    final body = await dbInst.select(dbInst.bodyMetrics).get();
    final accounts = await dbInst.select(dbInst.accounts).get();
    final transactions = await dbInst.select(dbInst.transactions).get();
    final receipts = await dbInst.select(dbInst.receipts).get();
    final tags = await dbInst.select(dbInst.tags).get();
    final exercises = await dbInst.select(dbInst.exercises).get();
    final stores = await dbInst.select(dbInst.stores).get();
    final ingredients = await (dbInst.select(
      dbInst.ingredients,
    )..where((t) => t.isArchived.equals(false))).get();
    final foods = await dbInst.select(dbInst.foods).get();
    return {
      'Tags': tags.length,
      'Exercises': exercises.length,
      'Tasks': tasks.length,
      'Notes': notes.length,
      'Goals': goals.length,
      'Workouts': workouts.length,
      'Templates': templates.length,
      'Meals': meals.length,
      'Body': body.length,
      'Budget': accounts.length,
      'Transactions': transactions.length,
      'Receipts': receipts.length,
      'Stores': stores.length,
      'Ingredients': ingredients.length,
      'Foods': foods.length,
    };
  }
}

final class _LocalBackupSection extends ConsumerStatefulWidget {
  const _LocalBackupSection();
  @override
  ConsumerState<_LocalBackupSection> createState() =>
      _LocalBackupSectionState();
}

final class _LocalBackupSectionState
    extends ConsumerState<_LocalBackupSection> {
  final Set<String> _selected = {...allBackupEntities};
  bool _busyExport = false;
  bool _busyImport = false;
  bool _busyServerBackup = false;
  bool _busyServerRestore = false;
  static const _prefsKey = 'local_backup_selected';
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = prefs.getStringList(_prefsKey);
      if (!mounted) return;
      setState(() {
        if (saved != null) {
          final known = saved.where(allBackupEntities.contains).toSet();
          // An older build could save groups that no longer exist (e.g.
          // 'Templates', now part of Workouts). Never end up with nothing
          // selected because of a stale preference.
          if (known.isNotEmpty) {
            _selected
              ..clear()
              ..addAll(known);
          }
        }
      });
    });
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setStringList(_prefsKey, _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.syncBackupFormatHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Wrap(
          spacing: FitFatTokens.spaceS,
          children: [
            for (final e in backupEntityGroups)
              FilterChip(
                label: Text(syncEntityLabel(l10n, e)),
                selected: _selected.contains(e),
                onSelected: (v) => setState(() {
                  if (v)
                    _selected.add(e);
                  else
                    _selected.remove(e);
                  _persist();
                }),
              ),
          ],
        ),
        Text(
          l10n.syncBackupGroupsSelected(
            _selected.length,
            backupEntityGroups.length,
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.syncExport, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _busyExport
                        ? null
                        : () async {
                            setState(() => _busyExport = true);
                            try {
                              if (_selected.isEmpty) {
                                showTopBanner(
                                  context,
                                  message: l10n.syncSelectOneGroup,
                                );
                                return;
                              }
                              await exportJsonPerEntity(
                                context,
                                ref,
                                _selected,
                              );
                            } catch (e) {
                              if (mounted)
                                showTopBanner(context, message: '$e');
                            } finally {
                              if (mounted) setState(() => _busyExport = false);
                            }
                          },
                    icon: _busyExport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share, size: 18),
                    label: Text(l10n.syncExportJson(_selected.length)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: FitFatTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.syncImport, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _busyImport
                        ? null
                        : () async {
                            setState(() => _busyImport = true);
                            try {
                              await importBackup(
                                context,
                                ref,
                                entities: _selected,
                              );
                            } catch (e) {
                              if (mounted)
                                showTopBanner(context, message: '$e');
                            } finally {
                              if (mounted) setState(() => _busyImport = false);
                            }
                          },
                    icon: _busyImport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_open, size: 18),
                    label: Text(l10n.syncImportJson),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Text(l10n.syncServerCopy, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          l10n.syncServerCopyHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busyServerBackup
                    ? null
                    : () => _backUpToServer(context),
                icon: _busyServerBackup
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup, size: 18),
                label: Text(l10n.syncBackUpToServer),
              ),
            ),
            const SizedBox(width: FitFatTokens.spaceM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busyServerRestore
                    ? null
                    : () => _restoreFromServer(context),
                icon: _busyServerRestore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore, size: 18),
                label: Text(l10n.syncRestoreFromServer),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _backUpToServer(BuildContext context) async {
    setState(() => _busyServerBackup = true);
    try {
      final settings = ref.read(settingsProvider);
      final bytes = await buildBackupArchive(ref, allBackupEntities);
      final httpClient = http.Client();
      final client = HttpApiClient(
        httpClient,
        baseUrl: settings.remoteSyncBaseUrl,
        timeout: Duration(seconds: settings.apiTimeoutSeconds),
      );
      try {
        await client.postBytes(
          settings.endpointExport,
          body: bytes,
          headers: authHeaders(settings.remoteSyncApiKey),
        );
      } finally {
        httpClient.close();
      }
    } catch (e, st) {
      Logger('SyncHub.Backup').severe('server backup failed', e, st);
      await shipPhoneLogs(ref);
      if (mounted)
        showTopBanner(
          context,
          message: friendlySyncError(
            l10n,
            ref.read(settingsProvider).remoteSyncBaseUrl,
            '$e',
          ),
        );
    } finally {
      if (mounted) setState(() => _busyServerBackup = false);
    }
  }

  Future<void> _restoreFromServer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.syncReplaceLocalTitle),
        content: Text(l10n.syncReplaceFromServerBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyServerRestore = true);
    try {
      final settings = ref.read(settingsProvider);
      final httpClient = http.Client();
      final client = HttpApiClient(
        httpClient,
        baseUrl: settings.remoteSyncBaseUrl,
        timeout: Duration(seconds: settings.apiTimeoutSeconds),
      );
      Uint8List bytes;
      try {
        bytes = await client.getBytes(
          settings.endpointImport,
          headers: authHeaders(settings.remoteSyncApiKey),
        );
      } finally {
        httpClient.close();
      }
      await importBackupArchive(ref, bytes);
    } catch (e, st) {
      Logger('SyncHub.Backup').severe('server restore failed', e, st);
      await shipPhoneLogs(ref);
      if (mounted)
        showTopBanner(
          context,
          message: friendlySyncError(
            l10n,
            ref.read(settingsProvider).remoteSyncBaseUrl,
            '$e',
          ),
        );
    } finally {
      if (mounted) setState(() => _busyServerRestore = false);
    }
  }
}
