import 'package:material_ui/material_ui.dart';

/// Duration-first cardio inputs for dialogs.
///
/// Duration is the one measure every cardio session has; distance is often
/// unknown (skating, a class, a hike without a watch). So distance hides
/// behind a "+ distance" button and only renders when asked for, or when
/// [initiallyExpanded] says this set or exercise already uses one. A field
/// that is never revealed stays empty and saves as null.
final class CardioFields extends StatefulWidget {
  final TextEditingController durationController;
  final TextEditingController distanceController;
  final String durationLabel;
  final String distanceLabel;
  final String addDistanceLabel;

  /// Show the distance field from the start. Also implied when
  /// [distanceController] already holds a value.
  final bool initiallyExpanded;

  const CardioFields({
    super.key,
    required this.durationController,
    required this.distanceController,
    required this.durationLabel,
    required this.distanceLabel,
    required this.addDistanceLabel,
    this.initiallyExpanded = false,
  });

  @override
  State<CardioFields> createState() => _CardioFieldsState();
}

final class _CardioFieldsState extends State<CardioFields> {
  late bool _expanded =
      widget.initiallyExpanded || widget.distanceController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('cardio-duration'),
          controller: widget.durationController,
          decoration: InputDecoration(labelText: widget.durationLabel),
          keyboardType: TextInputType.number,
        ),
        if (_expanded)
          TextField(
            key: const ValueKey('cardio-distance'),
            controller: widget.distanceController,
            decoration: InputDecoration(labelText: widget.distanceLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          )
        else
          AddDistanceButton(
            label: widget.addDistanceLabel,
            onPressed: () => setState(() => _expanded = true),
          ),
      ],
    );
  }
}

/// The "+ distance" affordance, shared by the dialogs and the compact set
/// rows of the workout and template forms.
final class AddDistanceButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  /// Icon-only variant for tight set rows; [label] becomes the tooltip.
  final bool compact;

  const AddDistanceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        key: const ValueKey('cardio-add-distance'),
        tooltip: label,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.straighten, size: 20),
        onPressed: onPressed,
      );
    }
    return TextButton.icon(
      key: const ValueKey('cardio-add-distance'),
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
    );
  }
}
