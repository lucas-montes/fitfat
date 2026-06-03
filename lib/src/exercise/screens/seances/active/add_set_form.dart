import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

class AddSetForm extends StatefulWidget {
  const AddSetForm({
    super.key,
    required this.onAdd,
    this.initialReps,
    this.initialWeight,
  });

  final Function(int reps, double weight) onAdd;
  final int? initialReps;
  final double? initialWeight;

  @override
  State<AddSetForm> createState() => _AddSetFormState();
}

class _AddSetFormState extends State<AddSetForm> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(AddSetForm oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              label: Text(l10n.reps),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              label: Text(l10n.weightKg),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () {
            final reps = int.tryParse(_repsController.text) ?? 0;
            final weight = double.tryParse(_weightController.text) ?? 0;
            if (reps > 0 && weight > 0) {
              widget.onAdd(reps, weight);
              _repsController.clear();
              _weightController.clear();
            }
          },
          tooltip: l10n.addSet,
        ),
      ],
    );
  }
}
