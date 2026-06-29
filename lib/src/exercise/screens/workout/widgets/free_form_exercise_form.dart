import 'package:flutter/material.dart';

import '../../../../models/workout.dart';
import 'exercise_set_form.dart';

/// Add-set form for **free-form** (unscheduled) active workouts.
///
/// Uses the compact `ExerciseSetForm` field row. Sets are auto-completed on
/// add. The "Add Exercise" button and pill are visible for this mode.
///
/// This is a separate class from [PlannedExerciseForm] so the two can diverge
/// in layout and behavior without affecting each other.
class FreeFormExerciseForm extends StatelessWidget {
  final ExerciseDefinition exercise;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final VoidCallback onAddSet;

  const FreeFormExerciseForm({
    super.key,
    required this.exercise,
    required this.repsController,
    required this.weightController,
    required this.durationController,
    required this.notesController,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseSetForm(
      exercise: exercise,
      repsController: repsController,
      weightController: weightController,
      durationController: durationController,
      notesController: notesController,
      onAddSet: onAddSet,
    );
  }
}
