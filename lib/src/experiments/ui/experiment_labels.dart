import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/theme_extensions.dart';
import '../../models/experiment.dart';

/// Localized label for an [ExperimentStatus].
String experimentStatusLabel(ExperimentStatus status, AppLocalizations l10n) =>
    switch (status) {
      ExperimentStatus.planned => l10n.experimentStatusPlanned,
      ExperimentStatus.active => l10n.experimentStatusActive,
      ExperimentStatus.done => l10n.experimentStatusDone,
      ExperimentStatus.aborted => l10n.experimentStatusAborted,
    };

/// Accent color used for an [ExperimentStatus] badge.
Color experimentStatusColor(BuildContext context, ExperimentStatus status) {
  final theme = Theme.of(context);
  final colors = theme.extension<FitFatColors>()!;
  return switch (status) {
    ExperimentStatus.planned => theme.colorScheme.outline,
    ExperimentStatus.active => colors.warning,
    ExperimentStatus.done => colors.success,
    ExperimentStatus.aborted => theme.colorScheme.error,
  };
}

/// Localized label for an [ExperimentCategory].
String experimentCategoryLabel(
  ExperimentCategory category,
  AppLocalizations l10n,
) => switch (category) {
  ExperimentCategory.workout => l10n.experimentCategoryWorkout,
  ExperimentCategory.diet => l10n.experimentCategoryDiet,
  ExperimentCategory.body => l10n.experimentCategoryBody,
  ExperimentCategory.steps => l10n.experimentCategorySteps,
};

/// Icon used for an [ExperimentCategory].
IconData experimentCategoryIcon(ExperimentCategory category) =>
    switch (category) {
      ExperimentCategory.workout => Icons.fitness_center,
      ExperimentCategory.diet => Icons.restaurant,
      ExperimentCategory.body => Icons.monitor_weight_outlined,
      ExperimentCategory.steps => Icons.directions_walk,
    };
