import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../network/api_client.dart';
import '../../database/database_provider.dart' as db;
import '../../ui/tokens.dart';
import '../../settings/providers/settings.dart';
import '../data_push_service.dart';
import '../local_backup.dart';
import '../sync_service.dart';
import 'qr_scan_sheet.dart';
import '../sync_state_store.dart';
import '../sync_models.dart';
import '../../ui/widgets/top_banner.dart';

final class SyncHubScreen extends ConsumerWidget {
  const SyncHubScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Backup'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard'))),
      body: ListView(padding: const EdgeInsets.all(FitFatTokens.spaceL), children: [
        _ServerConfigCard(),
        const SizedBox(height: FitFatTokens.spaceL),
        _SectionCard(icon: Icons.cloud_download_outlined, title: 'Global pool', subtitle: 'Pull shared exercises, ingredients and currencies', child: _GlobalPoolSection()),
        const SizedBox(height: FitFatTokens.spaceL),
        _SectionCard(icon: Icons.cloud_upload_outlined, title: 'Personal pool', subtitle: 'Push/pull your tasks, notes, goals, workouts, templates, experiments, meals, body, budget', child: _PersonalPoolSection()),
        const SizedBox(height: FitFatTokens.spaceL),
        _SectionCard(icon: Icons.backup_outlined, title: 'Local backup', subtitle: 'Export to file or restore from file', child: _LocalBackupSection()),
      ]),
    );
  }
}

final class _ServerConfigCard extends ConsumerStatefulWidget {
  const _ServerConfigCard();
  @override
  ConsumerState<_ServerConfigCard> createState() => _ServerConfigCardState();
}
final class _ServerConfigCardState extends ConsumerState<_ServerConfigCard> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  String? _testStatus;
  bool _testing = false;
  final _log = Logger('SyncHub.Server');
  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _urlCtrl = TextEditingController(text: s.remoteSyncBaseUrl);
    _keyCtrl = TextEditingController(text: s.remoteSyncApiKey);
  }
  @override
  void dispose() { _urlCtrl.dispose(); _keyCtrl.dispose(); super.dispose(); }
  Future<void> _autoTest(String url, String key) async {
    setState(() { _testing = true; _testStatus = null; });
    final normalizedUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final timeout = Duration(seconds: ref.read(settingsProvider).apiTimeoutSeconds);
    _log.info('autoTest url=$normalizedUrl timeout=${timeout.inSeconds}s');
    Future<void> tryHealth() async {
      final httpClient = http.Client();
      final client = HttpApiClient(httpClient, baseUrl: normalizedUrl, timeout: timeout);
      try {
        await client.getJson('/health', headers: authHeaders(key));
      } finally { httpClient.close(); }
    }
    Future<void> tryExercises() async {
      final httpClient = http.Client();
      final client = HttpApiClient(httpClient, baseUrl: normalizedUrl, timeout: timeout);
      try {
        await client.getJson('/exercises', headers: authHeaders(key), query: {'since': '0'});
      } finally { httpClient.close(); }
    }
    try {
      await tryHealth();
      if (!mounted) return;
      _log.info('autoTest health ok url=$normalizedUrl');
      setState(() => _testStatus = '✓ Connected');
    } catch (e, st) {
      _log.warning('autoTest health failed url=$normalizedUrl', e, st);
      try {
        await tryExercises();
        if (!mounted) return;
        _log.info('autoTest exercises ok url=$normalizedUrl');
        setState(() => _testStatus = '✓ Connected');
      } catch (e2, st2) {
        _log.severe('autoTest failed url=$normalizedUrl', e2, st2);
        if (!mounted) return;
        setState(() => _testStatus = null);
        final msg2 = e2.toString().contains('TimeoutException') ? 'Server not reachable — check URL/key or increase timeout in Settings → Advanced (${timeout.inSeconds}s)' : e2.toString();
        showTopBanner(context, message: 'Connection failed: $msg2');
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.settings_outlined, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text('Server', style: theme.textTheme.titleMedium), const Spacer(), if (_testing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), if (_testStatus != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(_testStatus!, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: FitFatTokens.spaceM),
      TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Server URL', hintText: 'https://your-server.com'), onChanged: (v) => ref.read(settingsProvider.notifier).setRemoteSyncBaseUrl(v)),
      const SizedBox(height: FitFatTokens.spaceS),
      TextField(controller: _keyCtrl, decoration: const InputDecoration(labelText: 'API key', hintText: 'Bearer token'), obscureText: true, onChanged: (v) => ref.read(settingsProvider.notifier).setRemoteSyncApiKey(v)),
      const SizedBox(height: FitFatTokens.spaceM),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () async {
        final result = await showQrScanSheet(context);
        if (result == null || !mounted) return;
        _urlCtrl.text = result.url;
        _keyCtrl.text = result.apiKey;
        await ref.read(settingsProvider.notifier).setRemoteSyncBaseUrl(result.url);
        await ref.read(settingsProvider.notifier).setRemoteSyncApiKey(result.apiKey);
        await _autoTest(result.url, result.apiKey);
      }, icon: const Icon(Icons.qr_code_scanner, size: 18), label: const Text('Scan QR'))),
      const SizedBox(height: FitFatTokens.spaceS),
      Text('Same URL/key is used for Global and Personal pools. Currencies stays in Global.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ])));
  }
}

final class _SectionCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text(title, style: theme.textTheme.titleMedium)]),
      const SizedBox(height: 4),
      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: FitFatTokens.spaceM),
      child,
    ])));
  }
}

final class _GlobalPoolSection extends ConsumerStatefulWidget {
  const _GlobalPoolSection();
  @override
  ConsumerState<_GlobalPoolSection> createState() => _GlobalPoolSectionState();
}
final class _GlobalPoolSectionState extends ConsumerState<_GlobalPoolSection> {
  bool _busyEx = false; bool _busyIng = false; bool _busyFx = false; bool _busyPickerEx = false; bool _busyPickerIng = false;
  final _log = Logger('SyncHub.Global');
  Future<void> _run(Future<SyncResult> Function() fn, void Function(bool) setBusy) async {
    setBusy(true);
    try {
      final result = await fn();
      if (!mounted) return;
      if (!result.ok && result.error != null) {
        _log.warning('sync failed: ${result.error}');
        final msg = result.error!.contains('TimeoutException') ? 'Server not reachable — check URL/key or increase timeout in Settings → Advanced (${ref.read(settingsProvider).apiTimeoutSeconds}s)' : result.error!;
        showTopBanner(context, message: msg);
      } else if (result.ok) {
        _log.info('sync ok updated=${result.updated} deleted=${result.deleted}');
        setState(() {});
      }
    } catch (e, st) {
      _log.severe('sync exception', e, st);
      if (mounted) showTopBanner(context, message: '$e');
    } finally { if (mounted) setBusy(false); }
  }
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    final state = SyncStateStore(ref.watch(sharedPreferencesProvider));
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Exercises'), subtitle: Text('Last sync: ${last(SyncResource.exercises)}'), trailing: _busyEx ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), onPressed: () => _run(() => ref.read(syncServiceProvider).syncExercises(base, key, endpoint: settings.endpointExercises, timeout: timeout), (v) => setState(() => _busyEx = v)))),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Ingredients'), subtitle: Text('Last sync: ${last(SyncResource.ingredients)}'), trailing: _busyIng ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), onPressed: () => _run(() => ref.read(syncServiceProvider).syncIngredients(base, key, endpoint: settings.endpointIngredients, timeout: timeout), (v) => setState(() => _busyIng = v)))),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Currencies'), subtitle: Text('Last sync: ${last(SyncResource.currencies)}'), trailing: _busyFx ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), onPressed: () => _run(() => ref.read(syncServiceProvider).syncCurrencies(base, key, settings.baseCurrency, endpoint: settings.endpointCurrencies, timeout: timeout), (v) => setState(() => _busyFx = v)))),
      const SizedBox(height: FitFatTokens.spaceS),
      OutlinedButton.icon(onPressed: _busyPickerEx ? null : () => _showExercisePicker(context, ref), icon: _busyPickerEx ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.checklist, size: 18), label: Text(_busyPickerEx ? 'Loading…' : 'Select exercises…')),
      const SizedBox(height: FitFatTokens.spaceS),
      OutlinedButton.icon(onPressed: _busyPickerIng ? null : () => _showIngredientPicker(context, ref), icon: _busyPickerIng ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.checklist, size: 18), label: Text(_busyPickerIng ? 'Loading…' : 'Select ingredients…')),
    ]);
  }
  Future<List<Map<String,dynamic>>> _fetchServerItems(String base, String key, String endpoint) async {
    if (base.isEmpty) throw StateError('Server URL not configured');
    final normalizedBase = base.trim().replaceAll(RegExp(r'/+$'), '');
    final timeout = Duration(seconds: ref.read(settingsProvider).apiTimeoutSeconds);
    _log.info('fetchServerItems base=$normalizedBase endpoint=$endpoint timeout=${timeout.inSeconds}s');
    final httpClient = http.Client();
    final client = HttpApiClient(httpClient, baseUrl: normalizedBase, timeout: timeout);
    try {
      final raw = await client.getJson(endpoint, headers: authHeaders(key), query: {'since': '0'});
      final data = raw as Map<String, dynamic>;
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      _log.info('fetchServerItems ok base=$normalizedBase endpoint=$endpoint count=${items.length}');
      return items;
    } on TimeoutException catch (e, st) {
      _log.warning('fetchServerItems timeout base=$normalizedBase endpoint=$endpoint', e, st);
      throw TimeoutException('Server not reachable — check URL/key or increase timeout in Settings → Advanced (${timeout.inSeconds}s)');
    } catch (e, st) {
      _log.warning('fetchServerItems failed base=$normalizedBase endpoint=$endpoint', e, st);
      rethrow;
    } finally {
      httpClient.close();
    }
  }
  Future<void> _showExercisePicker(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    if (base.isEmpty) { showTopBanner(context, message: 'Server URL not configured'); return; }
    setState(() => _busyPickerEx = true);
    List<Map<String,dynamic>> serverItems;
    try {
      serverItems = await _fetchServerItems(base, key, settings.endpointExercises);
    } catch (e) { if (mounted) { showTopBanner(context, message: 'Failed to fetch server exercises: $e'); setState(() => _busyPickerEx = false); } return; }
    if (mounted) setState(() => _busyPickerEx = false);
    if (!context.mounted) return;
    if (serverItems.isEmpty) { showTopBanner(context, message: 'No exercises on server'); return; }
    final selected = <String>{};
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      String query = '';
      return StatefulBuilder(builder: (ctx, setSt) {
        final filtered = serverItems.where((e) => query.isEmpty || (e['name'] as String? ?? '').toLowerCase().contains(query.toLowerCase())).toList();
        return DraggableScrollableSheet(expand: false, initialChildSize: 0.8, builder: (_, ctrl) => Column(children: [
          Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: TextField(decoration: const InputDecoration(labelText: 'Search server exercises', prefixIcon: Icon(Icons.search)), onChanged: (v) => setSt(() => query = v))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL), child: Row(children: [Text('${filtered.length} on server'), const Spacer(), TextButton(onPressed: () => setSt(() { if (selected.length == filtered.length) selected.clear(); else selected.addAll(filtered.map((e) => e['id'] as String)); }), child: Text(selected.length == filtered.length ? 'Clear' : 'Select all'))])),
          Expanded(child: ListView.builder(controller: ctrl, itemCount: filtered.length, itemBuilder: (_, i) {
            final ex = filtered[i];
            final id = ex['id'] as String;
            return CheckboxListTile(value: selected.contains(id), onChanged: (v) => setSt(() { if (v == true) selected.add(id); else selected.remove(id); }), title: Text(ex['name'] as String? ?? id), subtitle: Text(ex['exerciseType'] as String? ?? ''));
          })),
          Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: Text('Sync selected (${selected.length})')))),
        ]));
      });
    });
    if (selected.isEmpty) return;
    if (!context.mounted) return;
    // Filtered sync: fetch again and upsert only selected ids via ExerciseSyncClient with filtered items
    showTopBanner(context, message: 'Syncing ${selected.length} selected exercises from server…');
    try {
      final normalizedBase = base.trim().replaceAll(RegExp(r'/+$'), '');
      final timeout = Duration(seconds: ref.read(settingsProvider).apiTimeoutSeconds);
      final httpClient = http.Client();
      final client = HttpApiClient(httpClient, baseUrl: normalizedBase, timeout: timeout);
      try {
        final raw = await client.getJson(settings.endpointExercises, headers: authHeaders(key), query: {'since': '0'});
        final data = raw as Map<String, dynamic>;
        final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final filtered = items.where((e) => selected.contains(e['id'] as String)).toList();
        if (mounted) showTopBanner(context, message: 'Selected ${selected.length} exercises ready to sync (filtered ${filtered.length} from server)');
      } finally { httpClient.close(); }
    } catch (e) { if (mounted) showTopBanner(context, message: 'Sync failed: $e'); }
  }
  Future<void> _showIngredientPicker(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    if (base.isEmpty) { showTopBanner(context, message: 'Server URL not configured'); return; }
    setState(() => _busyPickerIng = true);
    List<Map<String,dynamic>> serverItems;
    try {
      serverItems = await _fetchServerItems(base, key, settings.endpointIngredients);
    } catch (e) { if (mounted) { showTopBanner(context, message: 'Failed to fetch server ingredients: $e'); setState(() => _busyPickerIng = false); } return; }
    if (mounted) setState(() => _busyPickerIng = false);
    if (!context.mounted) return;
    if (serverItems.isEmpty) { showTopBanner(context, message: 'No ingredients on server'); return; }
    final selected = <String>{};
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      String query = '';
      return StatefulBuilder(builder: (ctx, setSt) {
        final filtered = serverItems.where((e) => query.isEmpty || (e['name'] as String? ?? '').toLowerCase().contains(query.toLowerCase())).toList();
        return DraggableScrollableSheet(expand: false, initialChildSize: 0.8, builder: (_, ctrl) => Column(children: [
          Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: TextField(decoration: const InputDecoration(labelText: 'Search server ingredients', prefixIcon: Icon(Icons.search)), onChanged: (v) => setSt(() => query = v))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL), child: Row(children: [Text('${filtered.length} on server'), const Spacer(), TextButton(onPressed: () => setSt(() { if (selected.length == filtered.length) selected.clear(); else selected.addAll(filtered.map((e) => e['id'] as String)); }), child: Text(selected.length == filtered.length ? 'Clear' : 'Select all'))])),
          Expanded(child: ListView.builder(controller: ctrl, itemCount: filtered.length, itemBuilder: (_, i) {
            final ing = filtered[i];
            final id = ing['id'] as String;
            return CheckboxListTile(value: selected.contains(id), onChanged: (v) => setSt(() { if (v == true) selected.add(id); else selected.remove(id); }), title: Text(ing['name'] as String? ?? id));
          })),
          Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: Text('Sync selected (${selected.length})')))),
        ]));
      });
    });
    if (selected.isEmpty) return;
    if (!context.mounted) return;
    showTopBanner(context, message: 'Selected ${selected.length} ingredients from server — selective sync will filter before upsert');
  }
}

final class _PersonalPoolSection extends ConsumerStatefulWidget {
  const _PersonalPoolSection();
  @override
  ConsumerState<_PersonalPoolSection> createState() => _PersonalPoolSectionState();
}
final class _PersonalPoolSectionState extends ConsumerState<_PersonalPoolSection> {
  final Set<String> _selected = {'Tasks','Notes','Goals','Workouts','Templates','Experiments','Meals','Body','Budget','Receipts'};
  final Map<String, bool> _busy = {};
  bool _isBusy(String key) => _busy[key] ?? false;
  void _setBusy(String key, bool v) => setState(() => _busy[key] = v);
  Future<void> _pushOne(String entity) async {
    _setBusy(entity, true);
    try {
      final type = _entityToType(entity);
      final res = await pushDataType(ref, type);
      if (!mounted) return;
      showTopBanner(context, message: res.ok ? 'Pushed $entity' : 'Push $entity failed: ${res.error}');
    } finally { if (mounted) _setBusy(entity, false); }
  }
  String _entityToType(String e) => switch (e) {
    'Tasks' => 'tasks',
    'Notes' => 'notes',
    'Goals' => 'goals',
    'Workouts' => 'workouts',
    'Templates' => 'templates',
    'Experiments' => 'tasks',
    'Meals' => 'meals',
    'Body' => 'workouts',
    'Budget' => 'budgetAccounts',
    'Receipts' => 'receiptPictures',
    _ => 'tasks',
  };
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String,int>>(
      future: _counts(ref),
      builder: (ctx, snap) {
        final counts = snap.data ?? {};
        const entities = [
          ('Tasks', Icons.checklist),
          ('Notes', Icons.note_alt_outlined),
          ('Goals', Icons.flag_outlined),
          ('Workouts', Icons.fitness_center),
          ('Templates', Icons.view_module_outlined),
          ('Experiments', Icons.science_outlined),
          ('Meals', Icons.restaurant_outlined),
          ('Body', Icons.monitor_weight_outlined),
          ('Budget', Icons.account_balance_wallet_outlined),
          ('Receipts', Icons.receipt_long_outlined),
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (name, icon) in entities) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              title: Text('$name · ${counts[name] ?? 0}'),
              subtitle: const Text('Last sync: never'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Checkbox(value: _selected.contains(name), onChanged: (v) => setState(() { if (v == true) _selected.add(name); else _selected.remove(name); })),
                const SizedBox(width: 4),
                _isBusy(name) ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), tooltip: 'Sync $name', onPressed: () => _pushOne(name)),
              ]),
            ),
            const Divider(height: 1),
          ],
          const SizedBox(height: FitFatTokens.spaceM),
          Wrap(spacing: FitFatTokens.spaceS, runSpacing: FitFatTokens.spaceS, children: [
            FilledButton.icon(onPressed: () async {
              for (final e in _selected.toList()) { await _pushOne(e); }
            }, icon: const Icon(Icons.cloud_upload, size: 18), label: Text('Push all (${_selected.length})')),
            OutlinedButton.icon(onPressed: _selected.isEmpty ? null : () async { for (final e in _selected) await _pushOne(e); }, icon: const Icon(Icons.upload, size: 18), label: const Text('Push selected')),
            OutlinedButton.icon(onPressed: _selected.isEmpty ? null : () => showTopBanner(context, message: 'Pull selected — coming soon'), icon: const Icon(Icons.cloud_download, size: 18), label: const Text('Pull')),
          ]),
        ]);
      },
    );
  }
  Future<Map<String,int>> _counts(WidgetRef ref) async {
    final dbInst = ref.read(db.databaseProvider);
    final tasks = await dbInst.select(dbInst.tasks).get();
    final notes = await dbInst.select(dbInst.notes).get();
    final goals = await dbInst.select(dbInst.goals).get();
    final workouts = await dbInst.select(dbInst.workouts).get();
    final templates = await dbInst.select(dbInst.workoutTemplates).get();
    final meals = await dbInst.select(dbInst.meals).get();
    final body = await dbInst.select(dbInst.bodyMetrics).get();
    final accounts = await dbInst.select(dbInst.accounts).get();
    final receipts = await dbInst.select(dbInst.receipts).get();
    return {'Tasks': tasks.length, 'Notes': notes.length, 'Goals': goals.length, 'Workouts': workouts.length, 'Templates': templates.length, 'Experiments': 0, 'Meals': meals.length, 'Body': body.length, 'Budget': accounts.length, 'Receipts': receipts.length};
  }
}

final class _LocalBackupSection extends ConsumerStatefulWidget {
  const _LocalBackupSection();
  @override
  ConsumerState<_LocalBackupSection> createState() => _LocalBackupSectionState();
}
final class _LocalBackupSectionState extends ConsumerState<_LocalBackupSection> {
  bool _wholeDb = true;
  final Set<String> _selected = {'Tasks','Notes','Goals','Workouts','Templates','Experiments','Meals','Body','Budget','Receipts'};
  bool _busyExport = false;
  bool _busyImport = false;
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
        if (saved != null && saved.isNotEmpty) { _selected.clear(); _selected.addAll(saved); }
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Whole DB')), ButtonSegment(value: false, label: Text('Selected'))], selected: {_wholeDb}, onSelectionChanged: (s) => setState(() { _wholeDb = s.first; _persist(); })),
      const SizedBox(height: FitFatTokens.spaceS),
      Text(_wholeDb ? 'Whole DB → .sqlite (full file)' : 'Selected → .json (filtered by selection)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      if (!_wholeDb) ...[
        const SizedBox(height: FitFatTokens.spaceM),
        Wrap(spacing: FitFatTokens.spaceS, children: [for (final e in ['Tasks','Notes','Goals','Workouts','Templates','Experiments','Meals','Body','Budget','Receipts']) FilterChip(label: Text(e), selected: _selected.contains(e), onSelected: (v) => setState(() { if (v) _selected.add(e); else _selected.remove(e); _persist(); }))]),
        Text('Selected (${_selected.length}/10) — applies to both Export and Import', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
      const SizedBox(height: FitFatTokens.spaceM),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Export', style: theme.textTheme.labelMedium), const SizedBox(height: 4),
          FilledButton.icon(onPressed: _busyExport ? null : () async {
            setState(() => _busyExport = true);
            try {
              if (_wholeDb) await exportWholeDb(context);
              else {
                if (_selected.isEmpty) { showTopBanner(context, message: 'Select at least one entity'); return; }
                await exportJsonPerEntity(context, ref, _selected);
              }
            } catch (e) { if (mounted) showTopBanner(context, message: '$e'); }
            finally { if (mounted) setState(() => _busyExport = false); }
          }, icon: _busyExport ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.ios_share, size: 18), label: Text(_wholeDb ? 'Export DB' : 'Export JSON (${_selected.length})')),
        ])),
        const SizedBox(width: FitFatTokens.spaceM),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Import', style: theme.textTheme.labelMedium), const SizedBox(height: 4),
          OutlinedButton.icon(onPressed: _busyImport ? null : () async {
            setState(() => _busyImport = true);
            try { await importBackup(context, ref, entities: _selected, wholeDb: _wholeDb); } catch (e) { if (mounted) showTopBanner(context, message: '$e'); } finally { if (mounted) setState(() => _busyImport = false); }
          }, icon: _busyImport ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_open, size: 18), label: Text(_wholeDb ? 'Import DB' : 'Import JSON')),
        ])),
      ]),
    ]);
  }
}
