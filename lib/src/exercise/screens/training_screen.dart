import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/workout.dart';
import '../../settings/providers/settings.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/section_header.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/training.dart';
import '../providers/workouts.dart';
import '../repositories/training_summaries.dart';
import '../start_workout.dart';
import '../widgets/training_widgets.dart';
import 'exercise_list.dart';
import 'workout_form.dart';
import 'workout_history_screen.dart';
import 'workout_templates_screen.dart';

/// The Exercise tab root, built around starting a workout: the unfinished
/// workout on top, then a Recent row (each named workout once) and a
/// Templates row, each with "All".
final class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unit = ref.watch(settingsProvider).weightUnit;
    final active = ref.watch(activeWorkoutProvider);
    final routines =
        ref.watch(recentRoutinesProvider).value ?? const <RecentRoutine>[];
    final templates =
        ref.watch(templateCardsProvider).value ?? const <TemplateCard>[];
    final now = DateTime.now();

    Widget rowHeader(String label, VoidCallback onAll) => SectionHeader(
      label,
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceXs,
        FitFatTokens.spaceL,
        0,
        FitFatTokens.spaceXs,
      ),
      trailingWidget: TextButton(
        onPressed: onAll,
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: Text(l10n.trainingAll),
      ),
    );

    Widget hRow(List<Widget> cards) => SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: FitFatTokens.spaceS),
        itemBuilder: (_, i) => cards[i],
      ),
    );

    Widget hint(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFatTokens.spaceS),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l10n.trainingTitle),
            actions: [
              IconButton(
                tooltip: l10n.commonSearch,
                icon: const Icon(Icons.search),
                onPressed: () => _push(
                  context,
                  const WorkoutHistoryScreen(autofocusSearch: true),
                ),
              ),
              IconButton(
                tooltip: l10n.workoutListManageBtn,
                icon: const Icon(Icons.fitness_center),
                onPressed: () => _push(context, const ExerciseListScreen()),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceL,
              0,
              FitFatTokens.spaceL,
              96,
            ),
            sliver: SliverList.list(
              children: [
                if (active != null) _ActiveStrip(workout: active),
                rowHeader(
                  l10n.trainingRecent,
                  () => _push(context, const WorkoutHistoryScreen()),
                ),
                if (routines.isEmpty)
                  hint(l10n.trainingNoWorkouts)
                else
                  hRow([
                    for (final r in routines.take(10))
                      StartCard(
                        icon: TrainingIcon(cardio: r.summary.isCardio),
                        title: r.latest.name,
                        lines: [
                          workoutMetricLine(l10n, r.summary, unit),
                          l10n.trainingLastDone(
                            formatShortDay(context, r.latest.date),
                            r.count,
                          ),
                        ],
                        onTap: () =>
                            context.go('/workout-summary/${r.latest.id}'),
                        onStart: () => startRoutine(
                          context,
                          ref,
                          sourceWorkoutId: r.latest.id,
                        ),
                      ),
                  ]),
                rowHeader(
                  l10n.templatesTitle,
                  () => _push(context, const WorkoutTemplatesScreen()),
                ),
                if (templates.isEmpty)
                  hint(l10n.trainingNoTemplates)
                else
                  hRow([
                    for (final t in templates)
                      StartCard(
                        icon: const TrainingIcon(
                          cardio: false,
                          icon: Icons.bookmarks_outlined,
                        ),
                        title: t.name,
                        badge: t.isNew(now)
                            ? PrBadge(label: l10n.trainingNew)
                            : null,
                        lines: [
                          l10n.trainingTemplateSize(
                            t.exercises.length,
                            t.setCount,
                          ),
                          t.lastDone == null
                              ? l10n.trainingNeverDone
                              : l10n.trainingLast(
                                  formatShortDay(context, t.lastDone!),
                                ),
                        ],
                        onTap: () => _push(
                          context,
                          WorkoutTemplateFormScreen(initialId: t.id),
                        ),
                        onStart: () =>
                            startTemplate(context, ref, templateId: t.id),
                      ),
                  ]),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: l10n.trainingNewWorkout,
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
          );
          if (saved == true) ref.invalidate(workoutListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// The workout in progress, with Continue. Only shown on the training home.
final class _ActiveStrip extends StatelessWidget {
  const _ActiveStrip({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final warning = theme.extension<FitFatColors>()!.warning;
    return Card(
      margin: const EdgeInsets.only(top: FitFatTokens.spaceXs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
        side: BorderSide(color: warning.withValues(alpha: 0.6), width: 1.5),
      ),
      child: InkWell(
        onTap: () => context.go('/active-workout'),
        child: Padding(
          padding: const EdgeInsets.all(FitFatTokens.spaceM),
          child: Row(
            spacing: FitFatTokens.spaceM,
            children: [
              Icon(Icons.timer_outlined, color: warning),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: FitFatTokens.spaceS,
                      children: [
                        Flexible(
                          child: Text(
                            workout.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        StatusBadge(label: l10n.statusActive, color: warning),
                      ],
                    ),
                    Text(
                      l10n.trainingRunningFor(workout.duration.inMinutes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.go('/active-workout'),
                child: Text(l10n.dashboardContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
