import 'dart:async';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:material_ui/material_ui.dart';
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
import '../sync_all.dart';
import '../sync_refresh.dart';
import '../sync_service.dart';
import '../sync_state_store.dart';
import '../phone_log_shipper.dart';
import '../../ui/widgets/section_header.dart';
import '../sync_run.dart';
import '../widgets/server_sheet.dart';
import '../widgets/sync_chip.dart';
import '../../ui/widgets/top_banner.dart';
import '../entity_labels.dart';

/// True when [error] means the server could not be reached at all (as opposed
/// to answering with an error).
bool isUnreachableSyncError(String error) {
  final e = error.toLowerCase();
  return e.contains('timeoutexception') ||
      e.contains('socketexception') ||
      e.contains('connection refused') ||
      e.contains('connection reset') ||
      e.contains('connection closed') ||
      e.contains('failed host lookup');
}

/// Translates raw sync/HTTP failures into the sentence a regular user can act
/// on. Anything unrecognised is shown as-is for power users.
String friendlySyncError(AppLocalizations l10n, String url, String error) {
  final e = error.toLowerCase();
  if (isUnreachableSyncError(error)) {
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

/// Sync screen, status first: one "Sync now" for everything, the active
/// server as a pill (tap for the server sheet, QR button to rescan), per-type
/// rows for a single push or pull, the server library to cherry-pick from,
/// and backups one level down.
final class SyncHubScreen extends ConsumerStatefulWidget {
  const SyncHubScreen({super.key});

  @override
  ConsumerState<SyncHubScreen> createState() => _SyncHubScreenState();
}

final class _SyncHubScreenState extends ConsumerState<SyncHubScreen> {
  bool? _reachable;
  bool _checking = false;
  bool _showAll = false;
  bool _busyPickerEx = false;
  bool _busyPickerIng = false;
  final Map<String, bool> _busy = {};
  late Future<Map<String, int>> _counts = _loadCounts();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Display order: the types touched most often first; the collapsed list
  /// shows [_collapsedCount] of them.
  static const _rows = [
    ('Workouts', Icons.fitness_center),
    ('Meals', Icons.restaurant_outlined),
    ('Tasks', Icons.checklist),
    ('Notes', Icons.note_alt_outlined),
    ('Body', Icons.monitor_weight_outlined),
    ('Transactions', Icons.swap_horiz),
    ('Goals', Icons.flag_outlined),
    ('Templates', Icons.view_module_outlined),
    ('Foods', Icons.local_grocery_store_outlined),
    ('Ingredients', Icons.egg_outlined),
    ('Stores', Icons.storefront_outlined),
    ('Budget', Icons.account_balance_wallet_outlined),
    ('Receipts', Icons.receipt_long_outlined),
    ('Tags', Icons.sell_outlined),
    ('Exercises', Icons.directions_run),
  ];
  static const _collapsedCount = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkServer());
  }

  Future<void> _checkServer() async {
    if (ref.read(settingsProvider).remoteSyncBaseUrl.isEmpty) return;
    setState(() => _checking = true);
    final ok = await pingActiveServer(ref);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _reachable = ok;
    });
  }

  void _refreshCounts() => setState(() => _counts = _loadCounts());

  /// Pushes or pulls one entity from its row sheet.
  Future<void> _runOne(String entity, {required bool push}) async {
    setState(() => _busy[entity] = true);
    try {
      final type = syncEntityType(entity);
      final String? error;
      if (push) {
        error = (await pushDataType(ref, type)).error;
      } else {
        final res = await pullDataType(ref, type);
        error = res.ok ? null : (res.error ?? l10n.syncUnknownError);
      }
      await shipPhoneLogs(ref);
      if (!mounted) return;
      if (!push && error == null) invalidateAllData(ref);
      if (error != null) {
        final reason = friendlySyncError(
          l10n,
          ref.read(settingsProvider).remoteSyncBaseUrl,
          error,
        );
        final label = syncEntityLabel(l10n, entity);
        showTopBanner(
          context,
          message: push
              ? l10n.syncCouldNotPush(label, reason)
              : l10n.syncCouldNotPull(label, reason),
        );
      }
    } catch (e) {
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
      if (mounted) {
        setState(() => _busy[entity] = false);
        _refreshCounts();
      }
    }
  }

  Future<void> _showExercisePicker() async {
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
        allowSelectAll: false,
        hint: l10n.syncSearchServerExercises,
        refreshTooltip: l10n.syncRefreshList,
        onRefresh: refreshDisplay,
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      final result = await svc.importSelectedExercises(
        base,
        key,
        selected,
        endpoint: settings.endpointExercises,
        timeout: timeout,
      );
      if (!mounted) return;
      invalidateAllData(ref);
      if (!result.ok && result.error != null) {
        showTopBanner(context, message: result.error!);
      }
    } finally {
      if (mounted) {
        setState(() => _busyPickerEx = false);
        _refreshCounts();
      }
    }
  }

  Future<void> _showIngredientPicker() async {
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
      if (selected == null || selected.isEmpty || !mounted) return;
      final result = await svc.importSelectedIngredients(
        base,
        key,
        selected,
        endpoint: settings.endpointIngredients,
        timeout: timeout,
      );
      if (!mounted) return;
      invalidateAllData(ref);
      if (!result.ok && result.error != null) {
        showTopBanner(context, message: result.error!);
      }
    } finally {
      if (mounted) {
        setState(() => _busyPickerIng = false);
        _refreshCounts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prefs = ref.watch(sharedPreferencesProvider);
    final state = PrefsSyncStateStore(prefs);
    Widget sectionTitle(String text) => SectionHeader(
      text,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, FitFatTokens.spaceS),
    );

    ref.listen(syncRunProvider, (prev, next) {
      if (prev?.running == true && !next.running) {
        _refreshCounts();
        if (next.phase == SyncRunPhase.ok) setState(() => _reachable = true);
        if (next.unreachable) setState(() => _reachable = false);
      }
    });

    final rows = _showAll ? _rows : _rows.take(_collapsedCount);

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
          SyncStatusPanel(
            reachable: _reachable,
            checking: _checking,
            onServerChanged: () {
              if (mounted) _checkServer();
            },
          ),
          const SizedBox(height: FitFatTokens.spaceS),
          Text(
            l10n.syncNowHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FitFatTokens.spaceXl),
          sectionTitle(l10n.syncYourData),
          FutureBuilder<Map<String, int>>(
            future: _counts,
            builder: (ctx, snap) {
              final counts = snap.data ?? const <String, int>{};
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (name, icon) in rows) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: FitFatTokens.spaceL,
                          right: 4,
                        ),
                        leading: Icon(icon, size: 20, color: scheme.primary),
                        title: Text(
                          '${syncEntityLabel(l10n, name)} · ${counts[name] ?? 0}',
                        ),
                        subtitle: Text(
                          l10n.syncLastSync(() {
                            final r = syncResourceOf(name);
                            return r == null
                                ? '—'
                                : lastSyncedLabel(
                                    l10n,
                                    state.getLastSyncedAt(r),
                                  );
                          }()),
                        ),
                        // Send and get sit right on the row: one tap each.
                        // A missing direction keeps its slot so the two
                        // button columns stay aligned down the list.
                        trailing: SizedBox(
                          width: 96,
                          child: _busy[name] == true
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (syncPullOnly.contains(name))
                                      const SizedBox(width: 48)
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cloud_upload_outlined,
                                        ),
                                        tooltip: l10n.syncPushEntity(
                                          syncEntityLabel(l10n, name),
                                        ),
                                        onPressed:
                                            ref.watch(syncRunProvider).running
                                            ? null
                                            : () => _runOne(name, push: true),
                                      ),
                                    if (syncPushOnly.contains(name))
                                      const SizedBox(width: 48)
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cloud_download_outlined,
                                        ),
                                        tooltip: name == 'Exercises'
                                            ? l10n.syncExerciseUpdates
                                            : l10n.syncPullEntity(
                                                syncEntityLabel(l10n, name),
                                              ),
                                        onPressed:
                                            ref.watch(syncRunProvider).running
                                            ? null
                                            : () => _runOne(name, push: false),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    TextButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      child: Text(
                        _showAll
                            ? l10n.syncShowLess
                            : l10n.syncShowAll(_rows.length),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: FitFatTokens.spaceXl),
          sectionTitle(l10n.syncLibraryTitle),
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: FitFatTokens.spaceS,
            ),
            child: Text(
              l10n.syncLibraryHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          FutureBuilder<Map<String, int>>(
            future: _counts,
            builder: (ctx, snap) {
              final counts = snap.data ?? const <String, int>{};
              Widget libraryRow(
                String entity,
                bool busy,
                Future<void> Function() onTap,
              ) => ListTile(
                title: Text(syncEntityLabel(l10n, entity)),
                subtitle: Text(l10n.syncOnPhoneCount(counts[entity] ?? 0)),
                trailing: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.syncBrowse,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                onTap: busy ? null : onTap,
              );
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    libraryRow('Exercises', _busyPickerEx, _showExercisePicker),
                    const Divider(height: 1),
                    libraryRow(
                      'Ingredients',
                      _busyPickerIng,
                      _showIngredientPicker,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: FitFatTokens.spaceXl),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.inventory_2_outlined,
                color: scheme.onSurfaceVariant,
              ),
              title: Text(l10n.syncBackups),
              subtitle: Text(l10n.syncBackupsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SyncBackupScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _loadCounts() async {
    final dbInst = ref.read(db.databaseProvider);
    Future<int> count(
      ResultSetImplementation<HasResultSet, dynamic> table,
    ) async {
      final c = countAll();
      final row = await (dbInst.selectOnly(table)..addColumns([c])).getSingle();
      return row.read(c) ?? 0;
    }

    final ingredients = await (dbInst.select(
      dbInst.ingredients,
    )..where((t) => t.isArchived.equals(false))).get();
    return {
      'Tags': await count(dbInst.tags),
      'Exercises': await count(dbInst.exercises),
      'Tasks': await count(dbInst.tasks),
      'Notes': await count(dbInst.notes),
      'Goals': await count(dbInst.goals),
      'Workouts': await count(dbInst.workouts),
      'Templates': await count(dbInst.workoutTemplates),
      'Meals': await count(dbInst.meals),
      'Body': await count(dbInst.bodyMetrics),
      'Budget': await count(dbInst.accounts),
      'Transactions': await count(dbInst.transactions),
      'Receipts': await count(dbInst.receipts),
      'Stores': await count(dbInst.stores),
      'Ingredients': ingredients.length,
      'Foods': await count(dbInst.foods),
    };
  }
}

/// Backups, one level below the sync screen: JSON file export / import and
/// the compressed copy kept on the computer.
final class SyncBackupScreen extends StatelessWidget {
  const SyncBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncBackups)),
      body: ListView(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(FitFatTokens.spaceL),
              child: _LocalBackupSection(),
            ),
          ),
        ],
      ),
    );
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
                  if (v) {
                    _selected.add(e);
                  } else {
                    _selected.remove(e);
                  }
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
                              if (context.mounted) {
                                showTopBanner(context, message: '$e');
                              }
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
                              if (context.mounted) {
                                showTopBanner(context, message: '$e');
                              }
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
      if (context.mounted) {
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
      if (context.mounted) {
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
      if (mounted) setState(() => _busyServerRestore = false);
    }
  }
}
