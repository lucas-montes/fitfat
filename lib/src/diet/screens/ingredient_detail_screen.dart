import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../budget/format.dart' as bf;
import '../../budget/providers/fx_rates.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_price.dart';
import '../../models/store.dart';
import '../../settings/providers/settings.dart';
import '../../sync/sync_service.dart';
import '../../ui/date_formats.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/ingredients.dart';
import '../repositories/ingredient_repository.dart';
import 'ingredient_form.dart';
import 'store_manager_screen.dart';

const _commonCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'CHF', 'AUD'];

final class IngredientDetailScreen extends ConsumerWidget {
  final String ingredientId;
  const IngredientDetailScreen({super.key, required this.ingredientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientAsync = ref.watch(ingredientByIdProvider(ingredientId));
    return ingredientAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context)!.errorWithMessage('$e')),
        ),
      ),
      data: (ingredient) {
        if (ingredient == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(AppLocalizations.of(context)!.emptyIngredientsTitle),
            ),
          );
        }
        return _DetailBody(ingredient: ingredient);
      },
    );
  }
}

final class _DetailBody extends ConsumerWidget {
  final Ingredient ingredient;

  const _DetailBody({required this.ingredient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final picturesAsync = ref.watch(ingredientPicturesProvider(ingredient.id));
    final pictures = picturesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(ingredient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: l10n.syncPushIngredientTooltip,
            onPressed: () => _pushToServer(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
            onPressed: () => _edit(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (ingredient.brand != null || ingredient.barcode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (ingredient.brand != null)
                    Chip(
                      avatar: const Icon(Icons.storefront_outlined, size: 18),
                      label: Text(ingredient.brand!),
                    ),
                  if (ingredient.barcode != null)
                    Chip(
                      avatar: const Icon(Icons.qr_code_2, size: 18),
                      label: Text(ingredient.barcode!),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _MacroCell(
                          theme: theme,
                          value: ingredient.caloriesPer100g.toStringAsFixed(0),
                          unit: 'kcal',
                        ),
                        _MacroCell(
                          theme: theme,
                          value:
                              'P ${ingredient.proteinPer100g.toStringAsFixed(1)}g',
                        ),
                        _MacroCell(
                          theme: theme,
                          value:
                              'C ${ingredient.carbsPer100g.toStringAsFixed(1)}g',
                        ),
                        _MacroCell(
                          theme: theme,
                          value:
                              'F ${ingredient.fatPer100g.toStringAsFixed(1)}g',
                        ),
                      ],
                    ),
                    if (ingredient.sodiumPer100g != null ||
                        ingredient.fiberPer100g != null ||
                        ingredient.sugarPer100g != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          [
                            if (ingredient.sodiumPer100g != null)
                              l10n.ingredientNutrientSodium(
                                ingredient.sodiumPer100g!.toStringAsFixed(0),
                              ),
                            if (ingredient.fiberPer100g != null)
                              l10n.ingredientNutrientFiber(
                                ingredient.fiberPer100g!.toStringAsFixed(1),
                              ),
                            if (ingredient.sugarPer100g != null)
                              l10n.ingredientNutrientSugar(
                                ingredient.sugarPer100g!.toStringAsFixed(1),
                              ),
                          ].join('  ·  '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (pictures.isNotEmpty)
            SizedBox(
              height: 104,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pictures.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _openViewer(
                      context,
                      pictures.map((pict) => pict.imagePath).toList(),
                      i,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(pictures[i].imagePath),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 96,
                          height: 96,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _PricesSection(ingredientId: ingredient.id),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IngredientFormScreen(ingredient: ingredient),
      ),
    );
    if (saved == true) {
      ref.invalidate(ingredientListProvider);
      ref.invalidate(ingredientByIdProvider(ingredient.id));
    }
  }

  Future<void> _pushToServer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    if (settings.remoteSyncBaseUrl.isEmpty) {
      if (context.mounted) {
        showTopBanner(context, message: l10n.syncServerNotConfigured);
      }
      return;
    }
    final repo = ref.read(ingredientRepositoryProvider);
    final pictures = await repo.getPictures(ingredient.id);
    final prices = (await repo.getPrices(
      ingredient.id,
    )).map((p) => p.$1).toList();
    final result = await ref
        .read(syncServiceProvider)
        .pushIngredient(
          baseUrl: settings.remoteSyncBaseUrl,
          apiKey: settings.remoteSyncApiKey,
          ingredient: ingredient,
          pictures: pictures,
          prices: prices,
        );
    if (context.mounted && !result.ok && result.error != null) {
      showTopBanner(context, message: result.error!);
    }
  }

  void _openViewer(BuildContext context, List<String> paths, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _PictureViewerScreen(paths: paths, initialIndex: initialIndex),
      ),
    );
  }
}

/// Full-screen swipeable picture viewer with pinch-to-zoom.
final class _PictureViewerScreen extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _PictureViewerScreen({required this.paths, required this.initialIndex});

  @override
  State<_PictureViewerScreen> createState() => _PictureViewerScreenState();
}

final class _PictureViewerScreenState extends State<_PictureViewerScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(widget.paths[i]),
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _MacroCell extends StatelessWidget {
  final ThemeData theme;
  final String value;
  final String? unit;

  const _MacroCell({required this.theme, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            unit == null ? value : '$value $unit',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prices section
// ---------------------------------------------------------------------------

final class _PricesSection extends ConsumerWidget {
  final String ingredientId;

  const _PricesSection({required this.ingredientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final base = ref.watch(settingsProvider).baseCurrency;
    final rates = Map<String, double>.from(
      ref.watch(fxRatesProvider).value ?? {},
    )..[base] = 1.0;
    final pricesAsync = ref.watch(ingredientPricesProvider(ingredientId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ingredientDetailPricesTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _manageStores(context, ref),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(l10n.ingredientDetailManageStores),
              ),
            ],
          ),
          const SizedBox(height: 4),
          pricesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(l10n.errorWithMessage('$e')),
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.ingredientDetailNoPrices,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              // Latest observation per store, in the history's (newest-first)
              // order.
              final seen = <String>{};
              final latest = [
                for (final entry in entries)
                  if (seen.add(entry.$1.storeId)) entry,
              ];
              return Column(
                children: [
                  for (final (price, store) in latest)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(store.name),
                        subtitle: _priceSubtitle(context, price, base, rates),
                        trailing: Text(
                          bf.formatMoney(price.price, price.currencyCode),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => showIngredientPriceSheet(
                          context,
                          ref,
                          ingredientId: ingredientId,
                          existing: price,
                          initialStoreId: store.id,
                        ),
                      ),
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: Text(l10n.ingredientPriceHistoryTitle),
                    children: [
                      for (final (price, store) in entries)
                        ListTile(
                          dense: true,
                          title: Text(
                            '${bf.formatMoney(price.price, price.currencyCode)} · ${store.name}',
                          ),
                          subtitle: Text(
                            DateFormats.formatShortDate(
                              context,
                              price.recordedAt,
                            ),
                          ),
                          onTap: () => showIngredientPriceSheet(
                            context,
                            ref,
                            ingredientId: ingredientId,
                            existing: price,
                            initialStoreId: store.id,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          FilledButton.tonalIcon(
            onPressed: () => showIngredientPriceSheet(
              context,
              ref,
              ingredientId: ingredientId,
            ),
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: Text(l10n.ingredientPriceAdd),
          ),
        ],
      ),
    );
  }

  Widget? _priceSubtitle(
    BuildContext context,
    IngredientPrice price,
    String base,
    Map<String, double> rates,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final per100 = price.costPer100gInBase(baseCode: base, ratesToBase: rates);
    final parts = <String>[
      if (per100 != null)
        l10n.ingredientDetailCostPer100g(bf.formatMoney(per100, base)),
      if (price.packageGrams != null) '${_formatGrams(price.packageGrams!)} g',
    ];
    if (parts.isEmpty) return null;
    return Text(
      parts.join('  ·  '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<void> _manageStores(BuildContext context, WidgetRef ref) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StoreManagerScreen()));
    // Store renames should reflect immediately in price rows.
    ref.invalidate(storesProvider);
    ref.invalidate(ingredientPricesProvider(ingredientId));
  }
}

String _formatGrams(double grams) =>
    grams % 1 == 0 ? grams.toStringAsFixed(0) : grams.toStringAsFixed(1);

// ---------------------------------------------------------------------------
// Price add/edit sheet
// ---------------------------------------------------------------------------

/// Bottom-sheet form to record a price observation: store, price + currency,
/// package weight and date. Re-recording the same store on the same day
/// overwrites the previous row (upsert).
Future<void> showIngredientPriceSheet(
  BuildContext context,
  WidgetRef ref, {
  required String ingredientId,
  IngredientPrice? existing,
  String? initialStoreId,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PriceSheet(
      ingredientId: ingredientId,
      existing: existing,
      initialStoreId: initialStoreId,
    ),
  );
  if (saved == true) {
    ref.invalidate(ingredientPricesProvider(ingredientId));
  }
}

final class _PriceSheet extends ConsumerStatefulWidget {
  final String ingredientId;
  final IngredientPrice? existing;
  final String? initialStoreId;

  const _PriceSheet({
    required this.ingredientId,
    this.existing,
    this.initialStoreId,
  });

  @override
  ConsumerState<_PriceSheet> createState() => _PriceSheetState();
}

final class _PriceSheetState extends ConsumerState<_PriceSheet> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _gramsCtrl;
  late String _currency;
  DateTime _recordedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.existing?.price.toStringAsFixed(2) ?? '',
    );
    _gramsCtrl = TextEditingController(
      text: widget.existing?.packageGrams?.toStringAsFixed(0) ?? '',
    );
    _currency = widget.existing?.currencyCode ?? '';
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  Map<String, double> _rates() {
    final base = ref.read(settingsProvider).baseCurrency;
    final map = Map<String, double>.from(ref.read(fxRatesProvider).value ?? {});
    map[base] = 1.0;
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(settingsProvider).baseCurrency;
    final storesAsync = ref.watch(storesProvider);
    final stores = storesAsync.value ?? const <Store>[];

    final currencyOptions = {
      base,
      ..._commonCurrencies,
      ..._rates().keys,
    }.toList()..sort();
    if (_currency.isEmpty || !currencyOptions.contains(_currency)) {
      _currency = base;
    }

    String? selectedStoreId = widget.existing?.storeId ?? widget.initialStoreId;
    if (!stores.any((s) => s.id == selectedStoreId)) {
      selectedStoreId = stores.isEmpty ? null : stores.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? l10n.ingredientPriceAdd
                  : l10n.ingredientPriceEdit,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedStoreId),
              initialValue: selectedStoreId,
              decoration: InputDecoration(
                labelText: l10n.ingredientPriceStoreLabel,
              ),
              items: [
                for (final store in stores)
                  DropdownMenuItem(value: store.id, child: Text(store.name)),
              ],
              validator: (v) => v == null ? l10n.storeNameRequired : null,
              onChanged: (v) => setState(() => selectedStoreId = v),
            ),
            TextButton.icon(
              onPressed: () => _addStore(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.storeManagerAddTile),
            ),
            TextFormField(
              controller: _priceCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientPriceAmountLabel,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) =>
                  (v == null || v.trim().isEmpty || double.tryParse(v) == null)
                  ? l10n.transactionAmountInvalid
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_currency),
              initialValue: _currency,
              decoration: InputDecoration(
                labelText: l10n.transactionCurrencyLabel,
              ),
              items: currencyOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gramsCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientPriceGramsLabel,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.transactionDateLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _recordedAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _recordedAt = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
                      });
                    }
                  },
                  child: Text(
                    DateFormats.formatShortDate(context, _recordedAt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _save(selectedStoreId),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStore(BuildContext context) async {
    final name = await promptStoreName(context);
    if (name == null) return;
    final repo = ref.read(ingredientRepositoryProvider);
    await repo.insertStore(newStore(name: name));
    ref.invalidate(storesProvider);
  }

  Future<void> _save(String? storeId) async {
    if (storeId == null) return;
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return;
    final grams = double.tryParse(_gramsCtrl.text.trim());
    final repo = ref.read(ingredientRepositoryProvider);
    // Moving an existing observation to another day deletes the original row
    // (the new day gets a fresh upsert); same-day saves just overwrite.
    final existing = widget.existing;
    if (existing != null && !_isSameDay(existing.recordedAt, _recordedAt)) {
      await repo.deletePrice(existing.id);
    }
    await repo.upsertPrice(
      newIngredientPrice(
        ingredientId: widget.ingredientId,
        storeId: storeId,
        price: price,
        currencyCode: _currency,
        recordedAt: _recordedAt,
        packageGrams: grams,
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
