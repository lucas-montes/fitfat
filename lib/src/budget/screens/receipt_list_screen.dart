import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../database/database_provider.dart';
import '../../settings/providers/settings.dart';
import '../../ui/widgets/top_banner.dart';
import '../models/receipt.dart';
import '../providers/receipts.dart';
import '../providers/services.dart';

/// Receipt capture, selection and sending.
///
/// The phone is only a launchpad: a receipt is photographed, inserted locally,
/// sent to the server and then forgotten. What stays on this screen is the
/// queue — receipts that have not been accepted yet — so it can be retried or
/// sent in one go.
final class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

final class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  final Set<String> _selected = {};
  bool _selecting = false;
  bool _sending = false;
  int _sendDone = 0;
  int _sendTotal = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final receiptsAsync = ref.watch(receiptListProvider);
    // Retry any receipt whose upload was cut short last time.
    ref.watch(receiptResumeProvider);
    final serverConfigured = ref
        .watch(settingsProvider)
        .remoteSyncBaseUrl
        .trim()
        .isNotEmpty;
    final receipts = receiptsAsync.value ?? const <Receipt>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selecting
              ? l10n.receiptSelectedCount(_selected.length)
              : l10n.receiptListAppBar,
        ),
        leading: _selecting
            ? IconButton(
                tooltip: l10n.commonCancel,
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              )
            : null,
        actions: [
          if (_selecting)
            IconButton(
              tooltip: l10n.receiptSendSelected,
              icon: const Icon(Icons.cloud_upload_outlined),
              onPressed: _selected.isEmpty || _sending || !serverConfigured
                  ? null
                  : _sendSelected,
            )
          else if (receipts.isNotEmpty)
            IconButton(
              tooltip: l10n.receiptSendAll,
              icon: const Icon(Icons.cloud_upload_outlined),
              onPressed: _sending || !serverConfigured ? null : _sendAll,
            ),
        ],
      ),
      floatingActionButton:
          receiptsAsync.value == null ||
              receipts.isEmpty ||
              _selecting ||
              _sending
          ? null
          : FloatingActionButton(
              heroTag: null,
              tooltip: l10n.receiptCapture,
              onPressed: _showCaptureSheet,
              child: const Icon(Icons.add_a_photo_outlined),
            ),
      body: Column(
        children: [
          if (_sending)
            _SendProgress(
              label: l10n.receiptSendingProgress(_sendDone, _sendTotal),
              done: _sendDone,
              total: _sendTotal,
            ),
          if (!serverConfigured)
            _NoServerBanner(onOpenSync: () => context.push('/sync')),
          Expanded(
            child: receiptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    onCamera: () => _pickAndSend(ImageSource.camera),
                    onGallery: () => _pickAndSend(ImageSource.gallery),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Text(
                        l10n.receiptListSentNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final r = items[i];
                        final selected = _selected.contains(r.id);
                        return _ReceiptCard(
                          receipt: r,
                          selecting: _selecting,
                          selected: selected,
                          onTap: () {
                            if (_selecting) {
                              _toggleSelection(r.id);
                            } else {
                              context.push('/budget/receipt/${r.id}');
                            }
                          },
                          onLongPress: () => _toggleSelection(r.id),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      _selecting = true;
      if (!_selected.add(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selecting = false;
      }
    });
  }

  void _exitSelection() {
    if (!mounted) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _showCaptureSheet() async {
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
    await _pickAndSend(source);
  }

  /// Picks one photo (camera) or many (gallery), saves each locally, then sends
  /// exactly the new batch. Nothing else in the queue is touched.
  Future<void> _pickAndSend(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context);
    // Read before the first await so the widget can be popped mid-pick without
    // touching a disposed `ref`.
    final repository = ref.read(receiptRepositoryProvider);
    final picker = ImagePicker();
    final List<XFile> picked;
    if (source == ImageSource.gallery) {
      picked = await picker.pickMultiImage();
    } else {
      final one = await picker.pickImage(source: source);
      picked = one == null ? const [] : [one];
    }
    if (picked.isEmpty || !mounted) return;

    final ids = <String>[];
    var saveFailures = 0;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(dir.path, 'receipts'));
      await receiptsDir.create(recursive: true);
      for (final file in picked) {
        try {
          final ext = p.extension(file.path);
          final name = '${const Uuid().v7()}${ext.isEmpty ? '.jpg' : ext}';
          final saved = await File(
            file.path,
          ).copy(p.join(receiptsDir.path, name));
          final receipt = newReceipt(localPath: saved.path);
          await repository.insert(receipt);
          ids.add(receipt.id);
        } catch (_) {
          saveFailures++;
        }
      }
    } catch (e) {
      if (mounted) {
        showTopBannerOverlay(overlay, message: l10n.errorWithMessage('$e'));
      }
      return;
    }

    if (!mounted) return;
    ref.invalidate(receiptListProvider);
    if (ids.isEmpty) {
      showTopBannerOverlay(
        overlay,
        message: saveFailures > 0
            ? l10n.receiptSaveFailedCount(saveFailures)
            : l10n.receiptUploadError,
      );
      return;
    }
    await _runSend(
      ids,
      overlay: overlay,
      l10n: l10n,
      saveFailures: saveFailures,
    );
  }

  Future<void> _sendAll() async {
    final l10n = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context);
    final ids = (ref.read(receiptListProvider).value ?? const <Receipt>[])
        .map((r) => r.id)
        .toList();
    if (ids.isEmpty) return;
    await _runSend(ids, overlay: overlay, l10n: l10n);
  }

  Future<void> _sendSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context);
    await _runSend(_selected.toList(), overlay: overlay, l10n: l10n);
    _exitSelection();
  }

  Future<void> _runSend(
    List<String> ids, {
    required OverlayState overlay,
    required AppLocalizations l10n,
    int saveFailures = 0,
  }) async {
    if (ids.isEmpty || !mounted) return;
    final database = ref.read(databaseProvider);
    final sync = ref.read(budgetSyncServiceProvider);
    setState(() {
      _sending = true;
      _sendDone = 0;
      _sendTotal = ids.length;
    });

    final ReceiptSendOutcome outcome;
    try {
      outcome = await sendReceipts(
        database,
        sync,
        ids,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _sendDone = done;
            _sendTotal = total;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showTopBannerOverlay(overlay, message: l10n.errorWithMessage('$e'));
      }
      return;
    }

    if (!mounted) return;
    setState(() => _sending = false);
    ref.invalidate(receiptListProvider);
    ref.invalidate(receiptPendingProvider);
    _announce(overlay, l10n, outcome, saveFailures: saveFailures);
  }

  void _announce(
    OverlayState overlay,
    AppLocalizations l10n,
    ReceiptSendOutcome outcome, {
    int saveFailures = 0,
  }) {
    final parts = <String>[
      if (outcome.sent > 0) l10n.receiptSentCount(outcome.sent),
      if (outcome.failed > 0) l10n.receiptFailedCount(outcome.failed),
      if (outcome.noPicture > 0) l10n.receiptNoPictureCount(outcome.noPicture),
      if (saveFailures > 0) l10n.receiptSaveFailedCount(saveFailures),
    ];
    // A clean send needs no banner: the list already shows the new status.
    final clean =
        outcome.sent > 0 &&
        outcome.failed == 0 &&
        outcome.noPicture == 0 &&
        saveFailures == 0 &&
        outcome.firstError == null;
    if (clean) return;
    var message = parts.isEmpty ? l10n.receiptUploadError : parts.join(', ');
    if (outcome.firstError != null) {
      message = '$message — ${outcome.firstError}';
    }
    showTopBannerOverlay(overlay, message: message);
  }
}

String _statusLabel(AppLocalizations l10n, ReceiptStatus status) =>
    switch (status) {
      ReceiptStatus.local => l10n.receiptStatusLocal,
      ReceiptStatus.uploading => l10n.receiptStatusUploading,
      ReceiptStatus.uploaded => l10n.receiptStatusUploaded,
      ReceiptStatus.error => l10n.receiptStatusError,
      ReceiptStatus.parsing => l10n.receiptStatusParsing,
    };

final class _SendProgress extends StatelessWidget {
  const _SendProgress({
    required this.label,
    required this.done,
    required this.total,
  });

  final String label;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: total == 0 ? null : done / total),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ],
    );
  }
}

final class _NoServerBanner extends StatelessWidget {
  const _NoServerBanner({required this.onOpenSync});

  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.receiptsNoServer,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
              ),
              onPressed: onOpenSync,
              child: Text(l10n.receiptOpenSync),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(l10n.receiptEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l10n.receiptTakePhoto),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.receiptPickGallery),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ReceiptCard({
    required this.receipt,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.file(
                    File(receipt.localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Center(child: Icon(Icons.receipt_long_outlined)),
                  ),
                ),
                Container(
                  color: scheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusLabel(l10n, receipt.status),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (receipt.parsed)
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: scheme.primary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (selecting)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected ? scheme.primary : scheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
