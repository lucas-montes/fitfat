import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../network/api_client.dart';
import '../../database/database_provider.dart' as db;
import '../../exercise/widgets/select_sheet.dart';
import '../../app/app_restart.dart';
import '../repositories/catalog_repository.dart';
import '../../ui/tokens.dart';
import '../../settings/providers/settings.dart';
import '../data_push_service.dart';
import '../local_backup.dart';
import '../personal_pull_service.dart';
import '../sync_service.dart';
import 'qr_scan_sheet.dart';
import '../sync_state_store.dart';
import '../phone_log_shipper.dart';
import '../sync_models.dart';
import '../../ui/widgets/top_banner.dart';

/// Translates raw sync/HTTP failures into the sentence a regular user can act
/// on. Anything unrecognised is shown as-is for power users.
String friendlySyncError(String url, String error) {
  final e = error.toLowerCase();
  final unreachable =
      e.contains('timeoutexception') ||
      e.contains('socketexception') ||
      e.contains('connection refused') ||
      e.contains('connection reset') ||
      e.contains('connection closed') ||
      e.contains('failed host lookup');
  if (unreachable) {
    return 'Cannot reach the server at $url. Check that the sync server is '
        'running on the computer and that the phone is on the same Wi-Fi '
        'network (or configured via adb reverse). Use "Test /health" above to '
        'retry.';
  }
  if (e.contains('apiexception(405') || e.contains('apiexception(501')) {
    return 'This server is an older version that cannot receive this data '
        'yet. Update the sync server on the computer, then push again.';
  }
  if (e.contains('apiexception(404')) {
    return 'The server does not recognise this sync operation — its version '
        'may be too old. Update the sync server on the computer, then try '
        'again.';
  }
  if (e.contains('apiexception(401') || e.contains('apiexception(403')) {
    return 'The server rejected the API key. Check the key for this server '
        '(remove it, then re-add or re-scan the QR code).';
  }
  if (e.contains('apiexception(413')) {
    return 'This data set is too large for the server to accept in one go. '
        'Push fewer categories at once (uncheck some boxes above).';
  }
  if (e.contains('apiexception(5')) {
    return 'The server hit an internal problem while receiving this data. Its '
        'recent activity was logged on the computer — check the server '
        'console output.';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Backup'),
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
            title: 'Global pool',
            subtitle: 'Pull shared exercises, ingredients and currencies',
            child: _GlobalPoolSection(),
          ),
          const SizedBox(height: FitFatTokens.spaceL),
          _SectionCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Personal pool',
            subtitle:
                'Push/pull your tasks, notes, goals, workouts, templates, meals, body, budget',
            child: _PersonalPoolSection(),
          ),
          const SizedBox(height: FitFatTokens.spaceL),
          _SectionCard(
            icon: Icons.backup_outlined,
            title: 'Local backup',
            subtitle: 'Export to file or restore from file',
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
      setState(() => _testStatus = '✓ Connected ($normalizedUrl)');
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
        setState(() => _testStatus = '✓ Connected ($normalizedUrl)');
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
        setState(() => _testStatus = '✓ Connected ($normalizedUrl)');
        success = true;
      } catch (e2, st2) {
        _log.severe('autoTest failed url=$normalizedUrl', e2, st2);
        if (!mounted) return;
        setState(() => _testStatus = null);
        showTopBanner(
          context,
          message:
              'Connection failed — '
              '${friendlySyncError(normalizedUrl, e2.toString())}',
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
        title: const Text('Add server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://127.0.0.1:3030',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'API key'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              final key = keyCtrl.text.trim();
              if (url.isEmpty || key.isEmpty) return;
              Navigator.pop(ctx, (url: url, apiKey: key));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final normalized = result.url.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      showTopBanner(context, message: 'Invalid URL');
      return;
    }
    if (result.apiKey.isEmpty) {
      showTopBanner(context, message: 'API key required');
      return;
    }
    final notifier = ref.read(settingsProvider.notifier);
    if (ref.read(settingsProvider).servers.any((s) => s.url == normalized)) {
      showTopBanner(context, message: 'Server already exists');
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
                Text('Servers', style: theme.textTheme.titleMedium),
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
              'Add multiple server URL + API key pairs. Select active to sync. Keep adb reverse + http://127.0.0.1:3030 for hotspot.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            if (servers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No servers yet — add one via Scan QR or Add',
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
                  tooltip: 'Remove',
                  onPressed: servers.length <= 1
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove server?'),
                              content: Text('Remove ${s.label}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Remove'),
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
                    label: const Text('Add'),
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
                        showTopBanner(
                          context,
                          message: 'Server already exists',
                        );
                        return;
                      }
                      await ref
                          .read(settingsProvider.notifier)
                          .addServer(normalized, result.apiKey);
                      await _autoTest(normalized, result.apiKey);
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan QR'),
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
                    showTopBanner(context, message: 'No active server');
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
                label: const Text('Test /health'),
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
    String last(SyncResource r) {
      final ms = state.getLastSyncedAt(r);
      if (ms == 0) return 'never';
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    final timeout = Duration(seconds: settings.apiTimeoutSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Exercises'),
          subtitle: Text('Last sync: ${last(SyncResource.exercises)}'),
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
          title: const Text('Ingredients'),
          subtitle: Text('Last sync: ${last(SyncResource.ingredients)}'),
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
          title: const Text('Currencies'),
          subtitle: Text('Last sync: ${last(SyncResource.currencies)}'),
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
          label: Text(_busyPickerEx ? 'Loading…' : 'Select exercises…'),
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
          label: Text(_busyPickerIng ? 'Loading…' : 'Select ingredients…'),
        ),
      ],
    );
  }

  Future<void> _showExercisePicker(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    if (base.isEmpty) {
      showTopBanner(context, message: 'Server URL not configured');
      return;
    }
    setState(() => _busyPickerEx = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final timeout = Duration(seconds: settings.apiTimeoutSeconds);
      if (!await svc.pingServer(base, key, timeout: timeout)) {
        if (mounted) {
          showTopBanner(
            context,
            message: 'Server not reachable — check URL/key or increase timeout',
          );
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
            message: friendlySyncError('server', refreshed.error!),
          );
          return null;
        }
        return loadDisplay();
      }

      final displayItems = await loadDisplay();
      if (!mounted) return;
      if (displayItems.isEmpty) {
        showTopBanner(context, message: 'No exercises on server');
        return;
      }
      final selected = await showSelectSheet(
        context,
        items: displayItems,
        initialSelected: const {},
        title: 'Select server exercises',
        hint: 'Search server exercises',
        refreshTooltip: 'Refresh list',
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
      showTopBanner(context, message: 'Server URL not configured');
      return;
    }
    setState(() => _busyPickerIng = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final timeout = Duration(seconds: settings.apiTimeoutSeconds);
      if (!await svc.pingServer(base, key, timeout: timeout)) {
        if (mounted) {
          showTopBanner(
            context,
            message: 'Server not reachable — check URL/key or increase timeout',
          );
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
            message: friendlySyncError('server', refreshed.error!),
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
        showTopBanner(context, message: 'No ingredients on server');
        return;
      }
      final selected = await showSelectSheet(
        context,
        items: displayItems,
        initialSelected: const {},
        title: 'Select server ingredients',
        hint: 'Search server ingredients',
        refreshTooltip: 'Refresh list',
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
  void _setBusy(String key, bool v) => setState(() => _busy[key] = v);

  /// Dependency order for both directions.
  ///
  /// Tags go first so links can name them; exercises go before workouts and
  /// templates because those reference exercise ids (the server enforces the
  /// foreign key on push). Stores precede foods, and foods precede meals: the
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
    'Foods',
    'Meals',
    'Body',
    'Budget',
    'Transactions',
    'Receipts',
  ];

  static const _entities = [
    ('Tags', Icons.sell_outlined),
    ('Exercises', Icons.directions_run),
    ('Tasks', Icons.checklist),
    ('Notes', Icons.note_alt_outlined),
    ('Goals', Icons.flag_outlined),
    ('Workouts', Icons.fitness_center),
    ('Templates', Icons.view_module_outlined),
    ('Stores', Icons.storefront_outlined),
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
        if (announce) showTopBanner(context, message: 'Pushed $entity');
        setState(() {});
        return null;
      }
      final message =
          'Could not push $entity — '
          '${friendlySyncError(ref.read(settingsProvider).remoteSyncBaseUrl, res.error ?? 'unknown error')}';
      if (announce) showTopBanner(context, message: message);
      return message;
    } catch (e) {
      await shipPhoneLogs(ref);
      final message = friendlySyncError(
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
        if (announce) {
          showTopBanner(
            context,
            message:
                'Pulled $entity — ${res.updated} updated, ${res.deleted} deleted',
          );
        }
        setState(() {});
        return null;
      }
      final message =
          'Could not pull $entity — '
          '${friendlySyncError(ref.read(settingsProvider).remoteSyncBaseUrl, res.error ?? 'unknown error')}';
      if (announce) showTopBanner(context, message: message);
      return message;
    } catch (e) {
      await shipPhoneLogs(ref);
      final message = friendlySyncError(
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
        final error = await _pushOne(entity, announce: false);
        if (error != null) {
          if (mounted) showTopBanner(context, message: error);
          return;
        }
      }
      if (mounted) showTopBanner(context, message: 'Pushed all data');
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
      for (final entity in _order) {
        if (!mounted) return;
        final error = await _pullOne(entity, announce: false);
        if (error != null) failures.add(entity);
      }
      if (!mounted) return;
      showTopBanner(
        context,
        message: failures.isEmpty
            ? 'Pulled all data'
            : 'Pulled with errors: ${failures.join(', ')}',
      );
    } finally {
      if (mounted) setState(() => _pullingAll = false);
    }
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
    'Foods' => 'foods',
    _ => 'tasks',
  };

  @override
  Widget build(BuildContext context) {
    final state = PrefsSyncStateStore(ref.watch(sharedPreferencesProvider));
    String last(SyncResource? r) {
      if (r == null) return '—';
      final ms = state.getLastSyncedAt(r);
      if (ms == 0) return 'never';
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

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
                title: Text('$name · ${counts[name] ?? 0}'),
                subtitle: Text('Last sync: ${last(resourceOf(name))}'),
                trailing: _isBusy(name)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cloud_upload_outlined),
                            tooltip: 'Push $name',
                            onPressed: () => _pushOne(name),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.cloud_download_outlined),
                            tooltip: 'Pull $name',
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
                  label: const Text('Push all'),
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
                  label: const Text('Pull all'),
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
  bool _wholeDb = true;
  final Set<String> _selected = {
    'Tasks',
    'Notes',
    'Goals',
    'Workouts',
    'Templates',
    'Meals',
    'Body',
    'Budget',
    'Receipts',
  };
  bool _busyExport = false;
  bool _busyImport = false;
  bool _busyServerBackup = false;
  bool _busyServerRestore = false;
  static const _prefsKey = 'local_backup_selected';
  static const _wholeKey = 'local_backup_whole';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPreferencesProvider);
      final savedWhole = prefs.getBool(_wholeKey);
      final saved = prefs.getStringList(_prefsKey);
      if (!mounted) return;
      setState(() {
        if (savedWhole != null) _wholeDb = savedWhole;
        if (saved != null && saved.isNotEmpty) {
          _selected.clear();
          _selected.addAll(saved);
        }
      });
    });
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(_wholeKey, _wholeDb);
    prefs.setStringList(_prefsKey, _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Whole DB')),
            ButtonSegment(value: false, label: Text('Selected')),
          ],
          selected: {_wholeDb},
          onSelectionChanged: (s) => setState(() {
            _wholeDb = s.first;
            _persist();
          }),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        Text(
          _wholeDb
              ? 'Whole DB → .sqlite (full file)'
              : 'Selected → .json (filtered by selection)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!_wholeDb) ...[
          const SizedBox(height: FitFatTokens.spaceM),
          Wrap(
            spacing: FitFatTokens.spaceS,
            children: [
              for (final e in [
                'Tasks',
                'Notes',
                'Goals',
                'Workouts',
                'Templates',
                'Meals',
                'Body',
                'Budget',
                'Receipts',
              ])
                FilterChip(
                  label: Text(e),
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
            'Selected (${_selected.length}/10) — applies to both Export and Import',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: FitFatTokens.spaceM),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Export', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _busyExport
                        ? null
                        : () async {
                            setState(() => _busyExport = true);
                            try {
                              if (_wholeDb)
                                await exportWholeDb(context, ref);
                              else {
                                if (_selected.isEmpty) {
                                  showTopBanner(
                                    context,
                                    message: 'Select at least one entity',
                                  );
                                  return;
                                }
                                await exportJsonPerEntity(
                                  context,
                                  ref,
                                  _selected,
                                );
                              }
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
                    label: Text(
                      _wholeDb
                          ? 'Export DB'
                          : 'Export JSON (${_selected.length})',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: FitFatTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Import', style: theme.textTheme.labelMedium),
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
                                wholeDb: _wholeDb,
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
                    label: Text(_wholeDb ? 'Import DB' : 'Import JSON'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Text('Server copy', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Stash the whole database on the computer, or pull it back later',
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
                label: const Text('Back up to server'),
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
                label: const Text('Restore from server'),
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
      final file = await backupWholeDb(ref);
      final bytes = await file.readAsBytes();
      final httpClient = http.Client();
      final client = HttpApiClient(
        httpClient,
        baseUrl: settings.remoteSyncBaseUrl,
        timeout: Duration(seconds: settings.apiTimeoutSeconds),
      );
      try {
        await client.postBytes(
          '/backup',
          body: bytes,
          headers: authHeaders(settings.remoteSyncApiKey),
        );
      } finally {
        httpClient.close();
      }
      if (mounted) showTopBanner(context, message: 'Database backed up');
    } catch (e, st) {
      Logger('SyncHub.Backup').severe('server backup failed', e, st);
      await shipPhoneLogs(ref);
      if (mounted)
        showTopBanner(
          context,
          message: friendlySyncError(
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
        title: const Text('Replace local data?'),
        content: const Text(
          'Importing will replace the whole local database with the copy '
          'stored on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
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
          '/backup/latest',
          headers: authHeaders(settings.remoteSyncApiKey),
        );
      } finally {
        httpClient.close();
      }
      final tmp = await getTemporaryDirectory();
      final file = File(
        p.join(tmp.path, 'fitfat-restore-${DateTime.now().millisecondsSinceEpoch}.sqlite'),
      );      await file.writeAsBytes(bytes);
      await replaceWholeDb(ref, file.path);
      restartApp();
    } catch (e, st) {
      Logger('SyncHub.Backup').severe('server restore failed', e, st);
      await shipPhoneLogs(ref);
      if (mounted)
        showTopBanner(
          context,
          message: friendlySyncError(
            ref.read(settingsProvider).remoteSyncBaseUrl,
            '$e',
          ),
        );
    } finally {
      if (mounted) setState(() => _busyServerRestore = false);
    }
  }
}
