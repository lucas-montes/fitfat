import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../dashboard/providers/dashboard.dart';
import '../notifications/active_workout_notifier.dart';
import '../settings/providers/settings.dart';
import '../ui/widgets/top_banner.dart';
import 'providers/workout_templates.dart';
import 'providers/workouts.dart';

/// Starts [workoutId] now (sets startedAt, shows the ongoing notification)
/// and opens the active-workout screen. If another workout is already
/// running, opens that one instead of starting a second.
Future<void> startWorkoutNow(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final router = GoRouter.of(context);
  final overlay = Overlay.of(context);
  final notificationUp = await ref
      .read(activeWorkoutNotifierProvider)
      .startWorkoutNotification(
        workoutName: name,
        startedAt: DateTime.now(),
        l10n: l10n,
      );
  await ref.read(workoutRepositoryProvider).start(workoutId);
  ref.invalidate(workoutListProvider);
  ref.invalidate(workoutDetailProvider(workoutId));
  invalidateDashboard(ref);
  router.go('/active-workout');
  if (!notificationUp) {
    showTopBannerOverlay(overlay, message: l10n.workoutStartedNoNotification);
  }
}

/// True (and navigates to it) when a workout is already in progress.
bool _continueActive(BuildContext context, WidgetRef ref) {
  if (ref.read(activeWorkoutProvider) == null) return false;
  context.go('/active-workout');
  return true;
}

/// "Start again": a new occurrence of [sourceWorkoutId]'s routine, prefilled
/// per the replay setting, started right away.
Future<void> startRoutine(
  BuildContext context,
  WidgetRef ref, {
  required String sourceWorkoutId,
}) async {
  if (_continueActive(context, ref)) return;
  final created = await ref
      .read(workoutRepositoryProvider)
      .replayWorkout(
        sourceWorkoutId: sourceWorkoutId,
        prefill: ref.read(settingsProvider).replayPrefill,
      );
  if (!context.mounted) return;
  await startWorkoutNow(
    context,
    ref,
    workoutId: created.id,
    name: created.name,
  );
}

/// Starts a workout from template [templateId] today.
Future<void> startTemplate(
  BuildContext context,
  WidgetRef ref, {
  required String templateId,
}) async {
  if (_continueActive(context, ref)) return;
  final details = await ref.read(
    workoutTemplateDetailsProvider(templateId).future,
  );
  if (details == null || !context.mounted) return;
  final workout = await ref
      .read(workoutRepositoryProvider)
      .instantiateTemplate(details, day: DateTime.now());
  if (!context.mounted) return;
  await startWorkoutNow(
    context,
    ref,
    workoutId: workout.id,
    name: workout.name,
  );
}
