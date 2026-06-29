import 'package:flutter/material.dart';

import '../../../../models/workout.dart';
import 'exercise_set_form.dart';

/// Add-set form for **planned** (scheduled) active workouts.
///
/// Uses the compact `ExerciseSetForm` field row. Sets are saved with planned
/// values only (not auto-completed — the user completes them manually by
/// tapping the check icon on the tile).
///
/// The "Add Exercise" entry points are hidden in this mode because planned
/// workouts have a fixed exercise list determined at schedule time.
///
/// This is a separate class from [FreeFormExerciseForm] so the two can diverge
/// in layout and behavior without affecting each other.
class PlannedExerciseForm extends StatelessWidget {
  final ExerciseDefinition exercise;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final VoidCallback onAddSet;

  const PlannedExerciseForm({
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
