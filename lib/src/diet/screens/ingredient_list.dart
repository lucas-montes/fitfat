import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../exercise/widgets/select_sheet.dart';
import '../../models/ingredient.dart';
import '../../settings/providers/settings.dart';
import '../../sync/repositories/catalog_repository.dart';
import '../../sync/sync_service.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/macro_bar.dart';
import 'barcode_scan_sheet.dart';
import '../providers/ingredients.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_form.dart';

final class IngredientListScreen extends ConsumerStatefulWidget {
  const IngredientListScreen({super.key});

  @override
  ConsumerState<IngredientListScreen> createState() =>
      _IngredientListScreenState();
}

final class _IngredientListScreenState
    extends ConsumerState<IngredientListScreen> {
  bool _syncing = false;

  Future<void> _syncAll() async {
    final s = ref.read(settingsProvider);
    setState(() => _syncing = true);
    try {
      final result = await ref
          .read(syncServiceProvider)
          .syncIngredients(s.remoteSyncBaseUrl, s.remoteSyncApiKey);
      if (!mounted) return;
      ref.invalidate(ingredientListProvider);
      if (!result.ok && result.error != null) {
        showTopBanner(context, message: result.error!);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// On-demand cache refresh for the sheet's refresh button. Banners on
  /// failure and returns null so the sheet keeps its current rows.
  Future<List<DisplayItem>?> _refreshIngredientDisplay() async {
    final s = ref.read(settingsProvider);
    final refreshed = await ref
        .read(syncServiceProvider)
        .refreshIngredientCatalog(
          s.remoteSyncBaseUrl,
          s.remoteSyncApiKey,
          endpoint: '${s.endpointIngredients}/catalog',
          timeout: Duration(seconds: s.apiTimeoutSeconds),
        );
    if (!mounted) return null;
    if (!refreshed.ok) {
      showTopBanner(context, message: refreshed.error!);
      return null;
    }
    return ref.read(ingredientCatalogRepositoryProvider).searchHideImported('');
  }

  /// Selective sync: fast `/health` gate (blocks with a banner when the
  /// server is unreachable), then pick instantly from the local cache
  /// (barcode subtitles, no thumbnails in V1), importing only the checked
  /// minimal aggregates.
  Future<void> _selectiveSync() async {
    final l10n = AppLocalizations.of(context)!;
    final s = ref.read(settingsProvider);
    final base = s.remoteSyncBaseUrl;
    final key = s.remoteSyncApiKey;
    if (base.isEmpty) {
      showTopBanner(context, message: l10n.syncServerNotConfigured);
      return;
    }
    setState(() => _syncing = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final timeout = Duration(seconds: s.apiTimeoutSeconds);
      if (!await svc.pingServer(base, key, timeout: timeout)) {
        if (!mounted) return;
        showTopBanner(context, message: l10n.syncServerUnreachable);
        return;
      }
      final display = await ref
          .read(ingredientCatalogRepositoryProvider)
          .searchHideImported('');
      if (!mounted) return;
      if (display.isEmpty) {
        showTopBanner(context, message: l10n.syncNothingNew);
        return;
      }
      final selected = await showSelectSheet(
        context,
        items: display,
        initialSelected: const {},
        title: l10n.selectServerIngredients,
        hint: l10n.ingredientListSearchHint,
        refreshTooltip: l10n.refreshList,
        onRefresh: _refreshIngredientDisplay,
      );
      if (!mounted) return;
      if (selected == null || selected.isEmpty) return;
      final result = await svc.importSelectedIngredients(
        base,
        key,
        selected,
        endpoint: s.endpointIngredients,
        timeout: timeout,
      );
      if (!mounted) return;
      ref.invalidate(ingredientListProvider);
      if (!result.ok && result.error != null) {
        showTopBanner(context, message: result.error!);
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _query = '';

  Future<void> _scan(List<Ingredient> all) async {
    final l10n = AppLocalizations.of(context)!;
    final code = await showBarcodeScanSheet(context);
    if (code == null || !mounted) return;
    final match = all.where((i) => i.barcode == code).firstOrNull;
    if (match == null) {
      showTopBanner(context, message: l10n.mealEditBarcodeUnknown(code));
      return;
    }
    await _openDetail(context, ref, match);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = ref.watch(ingredientListProvider).value ?? const <Ingredient>[];
    final thumbs = ref.watch(ingredientThumbnailsProvider).value ?? const {};
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final i in all)
        if (q.isEmpty ||
            i.name.toLowerCase().contains(q) ||
            (i.brand?.toLowerCase().contains(q) ?? false))
          i,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ingredientListAppBar),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: l10n.syncIngredientsTooltip,
              icon: const Icon(Icons.cloud_sync_outlined),
              onSelected: (v) {
                if (v == 'all') {
                  unawaited(_syncAll());
                } else {
                  unawaited(_selectiveSync());
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'all', child: Text(l10n.syncAll)),
                PopupMenuItem(value: 'select', child: Text(l10n.syncSelect)),
              ],
            ),
        ],
      ),
      body: all.isEmpty
          ? EmptyState(
              icon: Icons.soup_kitchen_outlined,
              title: l10n.emptyIngredientsTitle,
              description: l10n.emptyIngredientsBody,
              ctaLabel: l10n.emptyIngredientsCta,
              onCtaPressed: () => _openForm(context, ref, null),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FitFatTokens.kContentMaxWidth,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FitFatTokens.spaceL,
                        FitFatTokens.spaceXs,
                        FitFatTokens.spaceL,
                        FitFatTokens.spaceS,
                      ),
                      child: TextField(
                        key: const ValueKey('ingredientSearch'),
                        decoration: InputDecoration(
                          hintText: l10n.ingredientSearchCount(all.length),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: l10n.mealEditScan,
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () => _scan(all),
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          FitFatTokens.spaceL,
                          0,
                          FitFatTokens.spaceL,
                          88,
                        ),
                        itemCount: shown.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: FitFatTokens.spaceS),
                        itemBuilder: (_, i) => _IngredientTile(
                          key: ValueKey(shown[i].id),
                          ingredient: shown[i],
                          thumbnail: thumbs[shown[i].id],
                          onTap: () => _openDetail(context, ref, shown[i]),
                          onDismissed: () =>
                              _archiveIngredient(context, ref, shown[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: l10n.dietAddIngredient,
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Opens the read-mostly detail screen; edits go through its appbar action.
  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientDetailScreen(ingredientId: ingredient.id),
      ),
    );
    if (context.mounted) ref.invalidate(ingredientListProvider);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Ingredient? existing,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IngredientFormScreen(ingredient: existing),
      ),
    );
    if (saved == true) ref.invalidate(ingredientListProvider);
  }

  Future<void> _archiveIngredient(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(ingredientRepositoryProvider);
    await repo.archive(ingredient.id);
    ref.invalidate(ingredientListProvider);
    if (context.mounted) {
      showTopBanner(
        context,
        message: l10n.ingredientArchived(ingredient.name),
        actionLabel: l10n.commonUndo,
        onAction: () async {
          await repo.restore(ingredient.id);
          ref.invalidate(ingredientListProvider);
        },
      );
    }
  }
}

/// Photo, name, brand and kcal, then protein, carbs, fat, fiber, sodium and
/// sugar per 100 g in six columns.
final class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final String? thumbnail;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _IngredientTile({
    super.key,
    required this.ingredient,
    required this.thumbnail,
    required this.onTap,
    required this.onDismissed,
  });

  static String _v(double v) {
    if (v == 0) return '0';
    if (v < 1) {
      return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
    if (v < 10) return v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return v.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final i = ingredient;
    return Dismissible(
      key: ValueKey('dismiss-${i.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: FitFatTokens.spaceL),
        child: Icon(Icons.archive_outlined, color: scheme.error),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceM,
              FitFatTokens.spaceM,
              FitFatTokens.spaceM,
              FitFatTokens.spaceS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FitFatTokens.spaceS,
              children: [
                Row(
                  spacing: FitFatTokens.spaceM,
                  children: [
                    _Thumb(path: thumbnail, name: i.name),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (i.brand != null)
                            Text(
                              i.brand!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${i.caloriesPer100g.round()}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: ' kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                MacroColumns(
                  labels: [...macroLabels(l10n), l10n.macroSugar],
                  values: [
                    for (final v in [
                      i.proteinPer100g,
                      i.carbsPer100g,
                      i.fatPer100g,
                      i.fiberPer100g,
                      i.sodiumPer100g,
                      i.sugarPer100g,
                    ])
                      _v(v),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 40 dp photo, or the name's first letter when there is none.
final class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.name});

  final String? path;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (path == null) return letter;
    return ClipRRect(
      borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      child: Image.file(
        File(path!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        cacheWidth: 120,
        errorBuilder: (_, _, _) => letter,
      ),
    );
  }
}
