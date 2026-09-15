import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';

Future<String?> showBarcodeScanSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _BarcodeScanSheet(),
  );
}

final class _BarcodeScanSheet extends StatefulWidget {
  const _BarcodeScanSheet();
  @override
  State<_BarcodeScanSheet> createState() => _BarcodeScanSheetState();
}

final class _BarcodeScanSheetState extends State<_BarcodeScanSheet> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final _manualCtrl = TextEditingController();
  bool _handled = false;
  String? _error;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    if (!_validBarcode(raw)) {
      setState(() => _error = raw);
      return;
    }
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  static bool _validBarcode(String raw) =>
      RegExp(r'^[0-9]{8,14}$').hasMatch(raw);

  void _submitManual() {
    final raw = _manualCtrl.text.trim();
    if (!_validBarcode(raw)) {
      setState(() => _error = raw);
      return;
    }
    Navigator.of(context).pop(raw);
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  l10n.ingredientFormScanTile,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _controller.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.errorWithMessage(_error!),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientFormBarcodeLabel,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitManual,
                  child: Text(l10n.commonOk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
