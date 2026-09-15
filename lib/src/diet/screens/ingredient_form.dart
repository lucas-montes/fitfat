import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/ingredient.dart';
import '../../models/store.dart';
import '../../settings/providers/settings.dart';
import '../../sync/ingredient_lookup_client.dart';
import '../../sync/sync_service.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/ingredients.dart';
import '../repositories/ingredient_repository.dart';
import 'barcode_scan_sheet.dart';
import 'store_manager_screen.dart';

final class IngredientFormScreen extends ConsumerStatefulWidget {
  final Ingredient? ingredient;
  const IngredientFormScreen({super.key, this.ingredient});

  @override
  ConsumerState<IngredientFormScreen> createState() =>
      _IngredientFormScreenState();
}

/// A picture shown in the gallery strip: either an already-persisted row
/// ([dbId] set) or a freshly picked file that is saved on [IngredientFormScreen._save].
final class _PictureDraft {
  final String? dbId;
  final String path;

  const _PictureDraft({required this.path, this.dbId});
}

final class _IngredientFormScreenState
    extends ConsumerState<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _sodiumCtrl;
  late final TextEditingController _fiberCtrl;
  late final TextEditingController _sugarCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _priceCtrl;
  String? _selectedStoreId;
  bool _saving = false;
  bool _scanning = false;
  bool _lookingUp = false;

  final _picker = ImagePicker();
  final List<_PictureDraft> _pictures = [];

  bool get _isEditing => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _nameCtrl = TextEditingController(text: ing?.name ?? '');
    _caloriesCtrl = TextEditingController(
      text: ing?.caloriesPer100g.toStringAsFixed(1) ?? '',
    );
    _proteinCtrl = TextEditingController(
      text: ing?.proteinPer100g.toStringAsFixed(1) ?? '',
    );
    _carbsCtrl = TextEditingController(
      text: ing?.carbsPer100g.toStringAsFixed(1) ?? '',
    );
    _fatCtrl = TextEditingController(
      text: ing?.fatPer100g.toStringAsFixed(1) ?? '',
    );
    _sodiumCtrl = TextEditingController(
      text: ing?.sodiumPer100g?.toStringAsFixed(1) ?? '',
    );
    _fiberCtrl = TextEditingController(
      text: ing?.fiberPer100g?.toStringAsFixed(1) ?? '',
    );
    _sugarCtrl = TextEditingController(
      text: ing?.sugarPer100g?.toStringAsFixed(1) ?? '',
    );
    _brandCtrl = TextEditingController(text: ing?.brand ?? '');
    _barcodeCtrl = TextEditingController(text: ing?.barcode ?? '');
    _priceCtrl = TextEditingController();
    if (_isEditing) {
      _loadPictures();
      _loadLatestPrice();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _sodiumCtrl.dispose();
    _fiberCtrl.dispose();
    _sugarCtrl.dispose();
    _brandCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPictures() async {
    final rows = await ref
        .read(ingredientRepositoryProvider)
        .getPictures(widget.ingredient!.id);
    if (!mounted) return;
    setState(() {
      _pictures
        ..clear()
        ..addAll(rows.map((r) => _PictureDraft(dbId: r.id, path: r.imagePath)));
    });
  }

  /// Preloads the most recent price observation (newest first from the
  /// repository) so editing an ingredient starts from its latest known price
  /// and store. Saving records a fresh observation for today.
  Future<void> _loadLatestPrice() async {
    final rows = await ref
        .read(ingredientRepositoryProvider)
        .getPrices(widget.ingredient!.id);
    if (rows.isEmpty || !mounted) return;
    final (price, store) = rows.first;
    setState(() {
      _priceCtrl.text = price.price.toStringAsFixed(2);
      _selectedStoreId = store.id;
    });
  }

  /// Prompts for a store name, creates it, and selects it in the picker.
  Future<void> _addStore() async {
    final name = await promptStoreName(context);
    if (name == null || !mounted) return;
    final repo = ref.read(ingredientRepositoryProvider);
    final store = newStore(name: name);
    await repo.insertStore(store);
    ref.invalidate(storesProvider);
    if (mounted) setState(() => _selectedStoreId = store.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.ingredientFormEditTitle
              : l10n.ingredientFormNewTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormNameLabel,
                hintText: l10n.ingredientFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.ingredientFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormBrandLabel,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormBarcodeLabel,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\dXx-]')),
              ],
            ),
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(l10n.ingredientFormScanTile),
                trailing: (_scanning || _lookingUp)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: (_scanning || _lookingUp) ? null : _scanBarcode,
              ),
            ),
            const SizedBox(height: 16),
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
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientPriceAmountLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final stores =
                    ref.watch(storesProvider).value ?? const <Store>[];
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedStoreId),
                      initialValue: _selectedStoreId,
                      decoration: InputDecoration(
                        labelText: l10n.ingredientPriceStoreLabel,
                      ),
                      items: [
                        for (final store in stores)
                          DropdownMenuItem(
                            value: store.id,
                            child: Text(store.name),
                          ),
                      ],
                      // A price observation only makes sense with a store.
                      validator: (v) =>
                          _priceCtrl.text.trim().isEmpty || v != null
                          ? null
                          : l10n.storeNameRequired,
                      onChanged: (v) => setState(() => _selectedStoreId = v),
                    ),
                    TextButton.icon(
                      onPressed: () => _addStore(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.storeManagerAddTile),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormCaloriesLabel,
                suffixText: l10n.ingredientFormCaloriesSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) =>
                  _validatePositive(v, l10n.ingredientFormCaloriesLabel, l10n),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormProteinLabel,
                suffixText: l10n.ingredientFormProteinSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateNonNegative(
                v,
                l10n.ingredientFormProteinLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carbsCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormCarbsLabel,
                suffixText: l10n.ingredientFormCarbsSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) =>
                  _validateNonNegative(v, l10n.ingredientFormCarbsLabel, l10n),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fatCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormFatLabel,
                suffixText: l10n.ingredientFormFatSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) =>
                  _validateNonNegative(v, l10n.ingredientFormFatLabel, l10n),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sodiumCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormSodiumLabel,
                suffixText: l10n.ingredientFormSodiumSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientFormSodiumLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fiberCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormFiberLabel,
                suffixText: l10n.ingredientFormFiberSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientFormFiberLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sugarCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormSugarLabel,
                suffixText: l10n.ingredientFormSugarSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientFormSugarLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 24),
            _buildPicturesSection(l10n),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pictures gallery strip
  // ---------------------------------------------------------------------------

  Widget _buildPicturesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ingredientFormPicturesSection,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pictures.length + 1,
            onReorder: _onReorderPictures,
            itemBuilder: (context, i) {
              if (i == _pictures.length) {
                return OutlinedButton.icon(
                  key: const ValueKey('add-picture'),
                  onPressed: () => _pickPicture(),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.ingredientFormAddPicture),
                );
              }
              final draft = _pictures[i];
              return Stack(
                key: ValueKey(draft.dbId ?? draft.path),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(draft.path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkResponse(
                      onTap: () => _removePicture(i),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _onReorderPictures(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final moved = _pictures.removeAt(oldIndex);
      _pictures.insert(newIndex.clamp(0, _pictures.length), moved);
    });
  }

  Future<void> _pickPicture() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.receiptTakePhoto),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.receiptPickGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      // Gallery allows multi-select; camera stays single-shot.
      final picked = source == ImageSource.gallery
          ? await _picker.pickMultiImage(imageQuality: 85)
          : [
              await _picker.pickImage(
                source: source,
                imageQuality: 85,
              ),
            ].whereType<XFile>().toList();
      if (picked.isEmpty || !mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      final picturesDir = Directory(p.join(dir.path, 'ingredient_pictures'));
      await picturesDir.create(recursive: true);
      for (final file in picked) {
        final ext = p.extension(file.path);
        final name = '${const Uuid().v7()}$ext';
        final saved = await File(
          file.path,
        ).copy(p.join(picturesDir.path, name));
        setState(() => _pictures.add(_PictureDraft(path: saved.path)));
      }
    } catch (e) {
      if (mounted) {
        showTopBanner(
          context,
          message: AppLocalizations.of(context)!.errorWithMessage('$e'),
        );
      }
    }
  }

  Future<void> _removePicture(int index) async {
    final draft = _pictures[index];
    setState(() => _pictures.removeAt(index));
    if (draft.dbId == null) return;
    final repo = ref.read(ingredientRepositoryProvider);
    await repo.deletePicture(draft.dbId!);
    final file = File(draft.path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
    if (mounted) {
      ref.invalidate(ingredientPicturesProvider(widget.ingredient!.id));
    }
  }

  /// Persists pending gallery changes after the ingredient row is written:
  /// new pictures get rows, then the whole strip is renumbered densely
  /// following the on-screen order.
  Future<void> _persistPictures(String ingredientId) async {
    if (_pictures.isEmpty) return;
    final repo = ref.read(ingredientRepositoryProvider);
    for (var i = 0; i < _pictures.length; i++) {
      final draft = _pictures[i];
      if (draft.dbId != null) continue;
      await repo.insertPicture(
        newIngredientPicture(
          ingredientId: ingredientId,
          imagePath: draft.path,
          sortOrder: i,
        ),
      );
    }
    final rows = await repo.getPictures(ingredientId);
    final idByPath = {for (final row in rows) row.imagePath: row.id};
    final orderedIds = [for (final draft in _pictures) ?idByPath[draft.path]];
    await repo.reorderPictures(ingredientId, orderedIds);
  }

  // ---------------------------------------------------------------------------
  // Barcode scan + server lookup (local DB, else OpenFoodFacts draft)
  // ---------------------------------------------------------------------------

  Future<void> _scanBarcode() async {
    setState(() => _scanning = true);
    final code = await showBarcodeScanSheet(context);
    if (!mounted) return;
    setState(() => _scanning = false);
    if (code == null || code.isEmpty) return;
    setState(() => _barcodeCtrl.text = code);
    await _lookupAfterScan(code);
  }

  Future<void> _lookupAfterScan(String code) async {
    final settings = ref.read(settingsProvider);
    if (settings.remoteSyncBaseUrl.isEmpty) return;
    setState(() => _lookingUp = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final result = await svc.lookupIngredientByBarcode(
        settings.remoteSyncBaseUrl,
        settings.remoteSyncApiKey,
        code,
        timeout: Duration(seconds: settings.apiTimeoutSeconds),
      );
      if (!mounted) return;
      switch (result.source) {
        case LookupSource.local:
          final item = result.item;
          if (item != null) {
            _applyMap(item, overwriteName: false);
            showTopBanner(
              context,
              message: '${item['name'] ?? code}',
            );
          }
        case LookupSource.openfoodfacts:
          final draft = result.draft;
          if (draft != null) {
            await _showOffPreview(draft, result.openfoodUrl, code);
          }
        case LookupSource.none:
          showTopBanner(
            context,
            message: AppLocalizations.of(
              context,
            )!.errorWithMessage(result.openfoodUrl),
          );
      }
    } catch (e) {
      if (mounted) {
        showTopBanner(
          context,
          message: AppLocalizations.of(context)!.errorWithMessage('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  void _applyMap(Map<String, Object?> map, {bool overwriteName = true}) {
    String? s(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    String fmt(Object? v) =>
        v is num ? (v.toDouble().toStringAsFixed(1)) : '';
    void fillIfEmpty(TextEditingController c, String v) {
      if (v.isEmpty) return;
      if (c.text.trim().isEmpty) c.text = v;
    }

    final name = s(map['name']);
    if (name != null && (overwriteName || _nameCtrl.text.trim().isEmpty)) {
      _nameCtrl.text = name;
    }
    fillIfEmpty(_brandCtrl, s(map['brand']) ?? '');
    fillIfEmpty(_caloriesCtrl, fmt(map['caloriesPer100g']));
    fillIfEmpty(_proteinCtrl, fmt(map['proteinPer100g']));
    fillIfEmpty(_carbsCtrl, fmt(map['carbsPer100g']));
    fillIfEmpty(_fatCtrl, fmt(map['fatPer100g']));
    fillIfEmpty(_sodiumCtrl, fmt(map['sodiumPer100g']));
    fillIfEmpty(_fiberCtrl, fmt(map['fiberPer100g']));
    fillIfEmpty(_sugarCtrl, fmt(map['sugarPer100g']));
    setState(() {});
  }

  Future<void> _showOffPreview(
    Map<String, Object?> draft,
    String openfoodUrl,
    String code,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${draft['name'] ?? code}'),
              subtitle: Text(
                '${draft['brand'] ?? ''}\n$openfoodUrl',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Apply to form'),
              onTap: () => Navigator.of(ctx).pop('apply'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Save to server & apply'),
              onTap: () => Navigator.of(ctx).pop('import'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share OpenFoodFacts link'),
              onTap: () => Navigator.of(ctx).pop('share'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'apply') {
      _applyMap(draft);
    } else if (action == 'share') {
      await SharePlus.instance.share(ShareParams(text: openfoodUrl));
    } else if (action == 'import') {
      await _importFromServer(code, draft);
    }
  }

  Future<void> _importFromServer(
    String code,
    Map<String, Object?> draft,
  ) async {
    final settings = ref.read(settingsProvider);
    setState(() => _lookingUp = true);
    try {
      final svc = ref.read(syncServiceProvider);
      final row = await svc.importIngredientFromBarcode(
        settings.remoteSyncBaseUrl,
        settings.remoteSyncApiKey,
        code,
        timeout: Duration(seconds: settings.apiTimeoutSeconds),
      );
      if (!mounted) return;
      _applyMap(row, overwriteName: false);
      _applyMap(draft);
    } catch (e) {
      if (mounted) {
        showTopBanner(
          context,
          message: AppLocalizations.of(context)!.errorWithMessage('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Save + validation
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final calories = double.parse(_caloriesCtrl.text);
      final protein = double.parse(_proteinCtrl.text);
      final carbs = double.parse(_carbsCtrl.text);
      final fat = double.parse(_fatCtrl.text);
      final sodium = _parseOptional(_sodiumCtrl.text);
      final fiber = _parseOptional(_fiberCtrl.text);
      final sugar = _parseOptional(_sugarCtrl.text);
      final brand = _parseText(_brandCtrl.text);
      final barcode = _parseText(_barcodeCtrl.text);

      final repo = ref.read(ingredientRepositoryProvider);

      if (_isEditing) {
        final updated = widget.ingredient!.copyWith(
          name: name,
          caloriesPer100g: calories,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          sodiumPer100g: sodium,
          fiberPer100g: fiber,
          sugarPer100g: sugar,
          brand: brand,
          barcode: barcode,
        );
        await repo.update(updated);
        await _persistPictures(updated.id);
        await _recordPrice(updated.id, repo);
        ref.invalidate(ingredientPricesProvider(updated.id));
      } else {
        final created = newIngredient(
          name: name,
          caloriesPer100g: calories,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          sodiumPer100g: sodium,
          fiberPer100g: fiber,
          sugarPer100g: sugar,
          brand: brand,
          barcode: barcode,
        );
        await repo.insert(created);
        await _persistPictures(created.id);
        await _recordPrice(created.id, repo);
        ref.invalidate(ingredientPricesProvider(created.id));
      }

      ref.invalidate(ingredientListProvider);
      if (_isEditing) {
        ref.invalidate(ingredientPicturesProvider(widget.ingredient!.id));
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Records a price observation for today when a price (and its store) was
  /// entered. Prices are optional; a blank field saves nothing.
  Future<void> _recordPrice(
    String ingredientId,
    IngredientRepository repo,
  ) async {
    final priceText = _priceCtrl.text.trim();
    if (priceText.isEmpty || _selectedStoreId == null) return;
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) return;
    await repo.upsertPrice(
      newIngredientPrice(
        ingredientId: ingredientId,
        storeId: _selectedStoreId!,
        price: price,
        currencyCode: ref.read(settingsProvider).baseCurrency,
        recordedAt: DateTime.now(),
      ),
    );
  }

  String? _validatePositive(String? v, String label, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.ingredientFormFieldRequired(label);
    final value = double.tryParse(v);
    if (value == null || value <= 0) {
      return l10n.ingredientFormFieldPositive(label);
    }
    return null;
  }

  String? _validateNonNegative(String? v, String label, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.ingredientFormFieldRequired(label);
    final value = double.tryParse(v);
    if (value == null || value < 0) {
      return l10n.ingredientFormFieldNonNegative(label);
    }
    return null;
  }

  /// Validates an optional numeric field: blank is allowed, non-blank must
  /// parse to a non-negative number.
  String? _validateOptionalNonNegative(
    String? v,
    String label,
    AppLocalizations l10n,
  ) {
    if (v == null || v.trim().isEmpty) return null;
    final value = double.tryParse(v);
    if (value == null || value < 0) {
      return l10n.ingredientFormFieldNonNegative(label);
    }
    return null;
  }

  /// Parses an optional numeric input; blank/whitespace maps to null.
  double? _parseOptional(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.parse(trimmed);
  }

  /// Normalizes an optional free-text input; blank maps to null.
  String? _parseText(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
