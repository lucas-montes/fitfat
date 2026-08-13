import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Shows a dialog to record one body metric (weight or height) for a day.
/// The day defaults to today (editable via a date picker); the value field is
/// empty with no default and must be a positive number.
/// Returns a `(day, value)` record, or `null` if cancelled.
Future<(DateTime, double)?> showBodyMetricDialog(
  BuildContext context, {
  required String dialogTitle,
  required String valueLabel,
  required String valueSuffix,
}) {
  return showDialog<(DateTime, double)>(
    context: context,
    builder: (ctx) => _BodyMetricDialog(
      dialogTitle: dialogTitle,
      valueLabel: valueLabel,
      valueSuffix: valueSuffix,
    ),
  );
}

final class _BodyMetricDialog extends StatefulWidget {
  final String dialogTitle;
  final String valueLabel;
  final String valueSuffix;

  const _BodyMetricDialog({
    required this.dialogTitle,
    required this.valueLabel,
    required this.valueSuffix,
  });

  @override
  State<_BodyMetricDialog> createState() => _BodyMetricDialogState();
}

final class _BodyMetricDialogState extends State<_BodyMetricDialog> {
  late final TextEditingController _controller;
  late DateTime _day;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null && mounted) setState(() => _day = date);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    // Accept both '.' and ',' as the decimal separator.
    final normalized = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (normalized.isEmpty || value == null) {
      setState(() => _errorText = l10n.bodyMetricsValueRequired);
      return;
    }
    if (value <= 0) {
      setState(() => _errorText = l10n.bodyMetricsValuePositive);
      return;
    }
    Navigator.of(context).pop((_day, value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: _pickDay,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(materialL10n.formatMediumDate(_day)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: widget.valueLabel,
              suffixText: widget.valueSuffix,
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.commonSave)),
      ],
    );
  }
}
