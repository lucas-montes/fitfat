import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise_set.dart';
import '../../models/units.dart';
import '../../ui/units.dart';

/// What the user entered for one set's actuals.
///
/// Every field is nullable because a set can be logged as weightlifting
/// (reps + weight) or cardio (duration + distance); the unused pair stays null.
final class SetActuals {
  final int? reps;
  final double? weightKg;
  final int? actualDurationMinutes;
  final double? actualDistanceMeters;

  const SetActuals({
    this.reps,
    this.weightKg,
    this.actualDurationMinutes,
    this.actualDistanceMeters,
  });

  /// True when at least one actual value was entered. A fully blank dialog
  /// clears the set instead of logging it.
  bool get isEmpty =>
      reps == null &&
      weightKg == null &&
      actualDurationMinutes == null &&
      actualDistanceMeters == null;
}

/// Edits one set's actuals.
///
/// Extracted from the active-workout screen so the completed-workout summary
/// can reopen the exact same editor: a completed session's sets are still
/// actuals, and having a second dialog would let the two drift apart.
///
/// Fields start from the logged actual when there is one, otherwise from the
/// planned value — the active flow uses that as a suggestion, so tapping a
/// fresh set and saving records the plan as done without retyping it.
final class SetActualsDialog extends StatefulWidget {
  final ExerciseSet set;
  final AppLocalizations l10n;
  final bool isWeightlifting;
  final bool isCardio;
  final WeightUnit unit;

  const SetActualsDialog({
    super.key,
    required this.set,
    required this.l10n,
    required this.isWeightlifting,
    required this.isCardio,
    required this.unit,
  });

  @override
  State<SetActualsDialog> createState() => _SetActualsDialogState();
}

final class _SetActualsDialogState extends State<SetActualsDialog> {
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _distanceCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.set;
    _repsCtrl = TextEditingController(
      text: (s.actualReps ?? s.reps)?.toString() ?? '',
    );
    final weight = s.actualWeightKg ?? s.weightKg;
    _weightCtrl = TextEditingController(
      text: weight == null ? '' : formatWeightValue(weight, widget.unit),
    );
    _durationCtrl = TextEditingController(
      text: s.actualDurationMinutes?.toString() ?? '',
    );
    _distanceCtrl = TextEditingController(
      text: s.actualDistanceMeters?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final s = widget.set;
    final isWeightlifting = widget.isWeightlifting || !widget.isCardio;
    final isCardio = widget.isCardio;

    return AlertDialog(
      title: Text(l10n.workoutDetailSetActualsTitle(s.setNumber)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWeightlifting) ...[
              TextField(
                controller: _repsCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualRepsLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _weightCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualWeightLabelUnit(
                    weightUnitLabel(widget.unit),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
            if (isCardio) ...[
              TextField(
                controller: _durationCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualDurationLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _distanceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualDistanceLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            final weight = double.tryParse(
              _weightCtrl.text.replaceAll(',', '.'),
            );
            Navigator.of(context).pop(
              SetActuals(
                reps: int.tryParse(_repsCtrl.text),
                weightKg: weight == null
                    ? null
                    : weightToKg(weight, widget.unit),
                actualDurationMinutes: int.tryParse(_durationCtrl.text),
                actualDistanceMeters: double.tryParse(
                  _distanceCtrl.text.replaceAll(',', '.'),
                ),
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Shows [SetActualsDialog]; null means the user dismissed it.
Future<SetActuals?> showSetActualsDialog(
  BuildContext context, {
  required ExerciseSet set,
  required AppLocalizations l10n,
  required bool isWeightlifting,
  required bool isCardio,
  required WeightUnit unit,
}) {
  return showDialog<SetActuals>(
    context: context,
    builder: (_) => SetActualsDialog(
      set: set,
      l10n: l10n,
      isWeightlifting: isWeightlifting,
      isCardio: isCardio,
      unit: unit,
    ),
  );
}
