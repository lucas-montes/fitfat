import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../diet/providers/meals.dart';
import '../../models/experiment.dart';
import '../../models/task.dart';
import '../../planner/providers/planner.dart';
import '../../settings/providers/settings.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/status_badge.dart';
import '../notifications/experiment_reminder.dart';
import '../providers/experiments.dart';
import '../providers/experiments_repository.dart';
import '../ui/experiment_labels.dart';
import 'experiment_form_screen.dart';

/// Experiment detail: lifecycle status + progress, the daily check-in, a
/// check-in timeline, and per-category charts of real data (workout volume,
/// calories, weight, steps) against a pre-start baseline.
final class ExperimentDetailScreen extends ConsumerStatefulWidget {
  final String experimentId;

  const ExperimentDetailScreen({super.key, required this.experimentId});

  @override
  ConsumerState<ExperimentDetailScreen> createState() =>
      _ExperimentDetailScreenState();
}

final class _ExperimentDetailScreenState
    extends ConsumerState<ExperimentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final experimentAsync = ref.watch(
      experimentByIdProvider(widget.experimentId),
    );
    final checkinsAsync = ref.watch(
      experimentCheckinsProvider(widget.experimentId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(experimentAsync.value?.name ?? l10n.tabExperiments),
        actions: [
          IconButton(
            tooltip: l10n.experimentFormTitleEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: experimentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (experiment) {
          if (experiment == null) {
            return Center(child: Text(l10n.experimentsEmptyTitle));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _HeaderCard(experiment: experiment),
              if (experiment.isActive) _StatusActions(experiment: experiment),
              _CheckinCard(
                experiment: experiment,
                existing: _todayCheckin(checkinsAsync.value),
              ),
              _ProgressCard(
                experiment: experiment,
                checkins: checkinsAsync.value ?? const [],
              ),
              _LinkedTasksSection(experimentId: widget.experimentId),
              _TrackedDataSection(experiment: experiment),
              _CheckinTimeline(
                checkins: checkinsAsync.value ?? const [],
                loading: checkinsAsync.isLoading,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExperimentFormScreen(experimentId: widget.experimentId),
      ),
    );
    if (saved == true) {
      ref.invalidate(experimentByIdProvider(widget.experimentId));
      ref.invalidate(experimentListProvider);
      ref.invalidate(experimentCheckinsProvider(widget.experimentId));
    }
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static ExperimentCheckin? _todayCheckin(List<ExperimentCheckin>? checkins) {
    if (checkins == null) return null;
    for (final checkin in checkins) {
      if (sameDay(checkin.day, DateTime.now())) return checkin;
    }
    return null;
  }
}

final class _HeaderCard extends StatelessWidget {
  final Experiment experiment;

  const _HeaderCard({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    experiment.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: experimentStatusLabel(experiment.status, l10n),
                  color: experimentStatusColor(context, experiment.status),
                ),
              ],
            ),
            if (experiment.purpose != null &&
                experiment.purpose!.isNotEmpty) ...[
              const SizedBox(height: FitFatTokens.spaceS),
              Text(
                experiment.purpose!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: FitFatTokens.spaceM),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final category in experiment.categories)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      experimentCategoryIcon(category),
                      size: 16,
                      color: scheme.primary,
                    ),
                    label: Text(
                      experimentCategoryLabel(category, l10n),
                      style: theme.textTheme.labelSmall,
                    ),
                    side: BorderSide(color: scheme.outlineVariant),
                    backgroundColor: scheme.surface,
                  ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            Text(
              '${l10n.experimentFormStartLabel}: '
              '${DateFormats.formatDate(context, experiment.startDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (experiment.endDate != null)
              Text(
                '${l10n.experimentFormEndLabel}: '
                '${DateFormats.formatDate(context, experiment.endDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: FitFatTokens.spaceS),
            Text(
              l10n.experimentDaysElapsed(
                DateTime.now().difference(experiment.startDate).inDays,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatusActions extends ConsumerWidget {
  final Experiment experiment;

  const _StatusActions({required this.experiment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Future<void> setStatus(ExperimentStatus status, {DateTime? endDate}) async {
      final updated = Experiment(
        id: experiment.id,
        name: experiment.name,
        purpose: experiment.purpose,
        startDate: experiment.startDate,
        endDate: status == ExperimentStatus.done
            ? endDate ?? DateTime.now()
            : experiment.endDate,
        status: status,
        categories: experiment.categories,
        reminderEnabled: experiment.reminderEnabled,
        reminderTimeMinutes: experiment.reminderTimeMinutes,
        createdAt: experiment.createdAt,
      );
      await ref.read(experimentRepositoryProvider).upsert(updated);
      await ref
          .read(experimentReminderSchedulerProvider)
          .scheduleForExperiment(
            updated,
            title: l10n.experimentReminderTitle(updated.name),
            body: l10n.experimentReminderBody,
          );
      ref.invalidate(experimentByIdProvider(experiment.id));
      ref.invalidate(experimentListProvider);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () =>
                  setStatus(ExperimentStatus.done, endDate: DateTime.now()),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.experimentDetailMarkDone),
            ),
          ),
          const SizedBox(width: FitFatTokens.spaceS),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setStatus(ExperimentStatus.aborted),
              icon: const Icon(Icons.block),
              label: Text(l10n.experimentDetailAbort),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Intermediary tasks linked to this experiment. Each tile unlinks on tap;
/// the header button opens a searchable picker that links existing planner
/// tasks (never other experiments).
final class _LinkedTasksSection extends ConsumerWidget {
  final String experimentId;

  const _LinkedTasksSection({required this.experimentId});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TaskPickerSheet(experimentId: experimentId),
    );
    ref.invalidate(experimentLinkedTasksProvider(experimentId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(experimentLinkedTasksProvider(experimentId));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.experimentLinkedTasksTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.link, size: 18),
                  label: Text(l10n.experimentLinkTask),
                  onPressed: () => _openPicker(context, ref),
                ),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            tasksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(l10n.errorWithMessage('$e')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Text(
                    l10n.experimentNoLinkedTasks,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final (:item, label: _) in tasks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          item.done
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: item.done
                              ? TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.outline,
                                )
                              : null,
                        ),
                        subtitle: Text(
                          DateFormats.formatDate(context, item.day),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.experimentUnlinkTask,
                          icon: const Icon(Icons.link_off, size: 20),
                          onPressed: () async {
                            await ref
                                .read(linksRepositoryProvider)
                                .unlinkTaskExperiment(experimentId, item.id);
                            ref.invalidate(
                              experimentLinkedTasksProvider(experimentId),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable sheet listing plain planner tasks; tapping a result links it to
/// the experiment, tapping an already-linked one unlinks it.
final class _TaskPickerSheet extends ConsumerStatefulWidget {
  final String experimentId;

  const _TaskPickerSheet({required this.experimentId});

  @override
  ConsumerState<_TaskPickerSheet> createState() => _TaskPickerSheetState();
}

final class _TaskPickerSheetState extends ConsumerState<_TaskPickerSheet> {
  final _controller = TextEditingController();
  List<Task>? _results;
  Set<String> _linkedIds = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final results = await ref
        .read(taskRepositoryProvider)
        .searchTasks(_controller.text);
    final linked = await ref
        .read(linksRepositoryProvider)
        .tasksForExperiment(widget.experimentId);
    if (!mounted) return;
    setState(() {
      _results = results;
      _linkedIds = {for (final t in linked) t.item.id};
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.experimentSearchTasksHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  onChanged: (_) => _search(),
                ),
              ),
              Expanded(
                child: _results == null
                    ? const Center(child: CircularProgressIndicator())
                    : _results!.isEmpty
                    ? Center(child: Text(l10n.experimentNoLinkedTasks))
                    : ListView(
                        children: [
                          for (final task in _results!)
                            ListTile(
                              leading: Icon(
                                _linkedIds.contains(task.id)
                                    ? Icons.link
                                    : Icons.add_link,
                                size: 20,
                              ),
                              title: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormats.formatDate(context, task.day),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onTap: () async {
                                final links = ref.read(linksRepositoryProvider);
                                final wasLinked = _linkedIds.contains(task.id);
                                if (wasLinked) {
                                  await links.unlinkTaskExperiment(
                                    widget.experimentId,
                                    task.id,
                                  );
                                } else {
                                  await links.linkTaskExperiment(
                                    task.id,
                                    widget.experimentId,
                                  );
                                }
                                await _search();
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProgressCard extends StatelessWidget {
  final Experiment experiment;
  final List<ExperimentCheckin> checkins;

  const _ProgressCard({required this.experiment, required this.checkins});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;

    final totalDays = experiment.endDate == null
        ? null
        : experiment.endDate!.difference(experiment.startDate).inDays + 1;
    final elapsedDays = DateTime.now().difference(experiment.startDate).inDays;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.experimentDetailProgressTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            if (totalDays != null && totalDays > 0) ...[
              LinearProgressIndicator(
                value: (elapsedDays / totalDays).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              Text(
                '${_rounded((elapsedDays / totalDays).clamp(0.0, 1.0))}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: FitFatTokens.spaceS),
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.experimentDetailCheckinCount(checkins.length),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _rounded(double value) => (value * 100).toStringAsFixed(0);
}

final class _CheckinCard extends ConsumerStatefulWidget {
  final Experiment experiment;
  final ExperimentCheckin? existing;

  const _CheckinCard({required this.experiment, this.existing});

  @override
  ConsumerState<_CheckinCard> createState() => _CheckinCardState();
}

final class _CheckinCardState extends ConsumerState<_CheckinCard> {
  final _noteCtrl = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CheckinCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existing?.id != widget.existing?.id) {
      final existing = widget.existing;
      _rating = existing?.rating ?? 0;
      _noteCtrl.text = existing?.note ?? '';
    }
  }

  void _syncExisting() {
    final existing = widget.existing;
    _rating = existing?.rating ?? 0;
    _noteCtrl.text = existing?.note ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating == 0) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(experimentRepositoryProvider)
          .upsertCheckin(
            experimentId: widget.experiment.id,
            day: DateTime.now(),
            rating: _rating,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      ref.invalidate(experimentCheckinsProvider(widget.experiment.id));
      if (!mounted) return;
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!_initialized) _syncExisting();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.experimentDetailCheckin,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.experimentDetailCheckinToday,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: FitFatTokens.spaceS),
            Text(
              l10n.experimentDetailCheckinRatingLabel,
              style: theme.textTheme.bodySmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: i <= _rating
                          ? Colors.amber
                          : theme.colorScheme.outline,
                      size: 32,
                    ),
                    onPressed: _saving
                        ? null
                        : () => setState(() => _rating = i),
                  ),
              ],
            ),
            Center(
              child: Text(
                l10n.experimentDetailCheckinRatingHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            TextFormField(
              controller: _noteCtrl,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.experimentDetailCheckinNoteLabel,
                hintText: l10n.experimentDetailCheckinNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            FilledButton(
              onPressed: _saving || _rating == 0 ? null : _save,
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TrackedDataSection extends ConsumerWidget {
  final Experiment experiment;

  const _TrackedDataSection({required this.experiment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final baselineDays = ref.watch(settingsProvider).experimentBaselineDays;
    final baselineStart = experiment.startDate.subtract(
      Duration(days: baselineDays),
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.experimentDetailTrackedTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            Text(
              '${l10n.experimentDetailBaselineTitle}: '
              '${DateFormats.formatShortDate(context, baselineStart)} – '
              '${DateFormats.formatShortDate(context, experiment.startDate.subtract(const Duration(days: 1)))}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            for (final category in experiment.categories) ...[
              _CategoryChart(
                category: category,
                experiment: experiment,
                baselineStart: baselineStart,
              ),
              const SizedBox(height: FitFatTokens.spaceM),
            ],
          ],
        ),
      ),
    );
  }
}

final class _CategoryChart extends ConsumerWidget {
  final ExperimentCategory category;
  final Experiment experiment;
  final DateTime baselineStart;

  const _CategoryChart({
    required this.category,
    required this.experiment,
    required this.baselineStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (category) {
      ExperimentCategory.workout => _WorkoutChart(
        experiment: experiment,
        baselineStart: baselineStart,
      ),
      ExperimentCategory.diet => _DietChart(
        experiment: experiment,
        baselineStart: baselineStart,
      ),
      ExperimentCategory.body => _BodyChart(
        experiment: experiment,
        baselineStart: baselineStart,
      ),
      ExperimentCategory.steps => _StepsChart(
        experiment: experiment,
        baselineStart: baselineStart,
      ),
    };
  }
}

final class _WorkoutChart extends ConsumerWidget {
  final Experiment experiment;
  final DateTime baselineStart;

  const _WorkoutChart({required this.experiment, required this.baselineStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final volumesAsync = ref.watch(workoutDailyVolumesProvider(baselineStart));

    return volumesAsync.when(
      loading: () => const _ChartLoading(),
      error: (e, _) => _ChartError(message: l10n.errorWithMessage('$e')),
      data: (volumes) {
        final primary = volumes
            .where((v) => !v.day.isBefore(experiment.startDate))
            .map((v) => (v.day, v.volumeKg))
            .toList();
        final baseline = _mean(
          volumes
              .where((v) => v.day.isBefore(experiment.startDate))
              .map((v) => v.volumeKg),
        );
        return _SeriesChart(
          title: l10n.experimentChartWorkout,
          primary: primary,
          color: Theme.of(context).colorScheme.primary,
          baseline: baseline,
        );
      },
    );
  }
}

final class _DietChart extends ConsumerWidget {
  final Experiment experiment;
  final DateTime baselineStart;

  const _DietChart({required this.experiment, required this.baselineStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mealsAsync = ref.watch(mealListProvider);

    return mealsAsync.when(
      loading: () => const _ChartLoading(),
      error: (e, _) => _ChartError(message: l10n.errorWithMessage('$e')),
      data: (meals) {
        final byDay = <DateTime, ({double kcal, double protein})>{};
        for (final meal in meals) {
          if (meal.eatenAt.isBefore(baselineStart)) continue;
          final day = DateTime(
            meal.eatenAt.year,
            meal.eatenAt.month,
            meal.eatenAt.day,
          );
          final current = byDay[day] ?? (kcal: 0.0, protein: 0.0);
          byDay[day] = (
            kcal: current.kcal + meal.totalCalories,
            protein:
                current.protein +
                meal.items.fold(0.0, (sum, item) => sum + item.protein),
          );
        }
        final days = byDay.keys.toList()..sort();
        final primary = <(DateTime, double)>[];
        final secondary = <(DateTime, double)>[];
        for (final day in days) {
          if (day.isBefore(experiment.startDate)) continue;
          primary.add((day, byDay[day]!.kcal));
          secondary.add((day, byDay[day]!.protein));
        }
        final baseline = _mean(
          byDay.entries
              .where((e) => e.key.isBefore(experiment.startDate))
              .map((e) => e.value.kcal),
        );
        return _SeriesChart(
          title: l10n.experimentChartDiet,
          primary: primary,
          secondary: secondary,
          secondaryTitle: l10n.experimentChartDietProtein,
          color: Theme.of(context).colorScheme.primary,
          secondaryColor: Theme.of(context).colorScheme.tertiary,
          baseline: baseline,
        );
      },
    );
  }
}

final class _BodyChart extends ConsumerWidget {
  final Experiment experiment;
  final DateTime baselineStart;

  const _BodyChart({required this.experiment, required this.baselineStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(bodyMetricsProvider);

    return entriesAsync.when(
      loading: () => const _ChartLoading(),
      error: (e, _) => _ChartError(message: l10n.errorWithMessage('$e')),
      data: (entries) {
        final logged = entries.where((e) => e.weightKg != null).toList();
        final primary = logged
            .where((e) => !e.day.isBefore(experiment.startDate))
            .map((e) => (e.day, e.weightKg!))
            .toList();
        final baseline = _mean(
          logged
              .where((e) => e.day.isBefore(experiment.startDate))
              .map((e) => e.weightKg!),
        );
        return _SeriesChart(
          title: l10n.experimentChartWeight,
          primary: primary,
          color: Theme.of(context).colorScheme.secondary,
          baseline: baseline,
        );
      },
    );
  }
}

final class _StepsChart extends ConsumerWidget {
  final Experiment experiment;
  final DateTime baselineStart;

  const _StepsChart({required this.experiment, required this.baselineStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stepsAsync = ref.watch(stepsDailyProvider(baselineStart));

    return stepsAsync.when(
      loading: () => const _ChartLoading(),
      error: (e, _) => _ChartError(message: l10n.errorWithMessage('$e')),
      data: (steps) {
        final primary = steps
            .where((s) => !s.day.isBefore(experiment.startDate))
            .map((s) => (s.day, s.steps.toDouble()))
            .toList();
        final baseline = _mean(
          steps
              .where((s) => s.day.isBefore(experiment.startDate))
              .map((s) => s.steps.toDouble()),
        );
        return _SeriesChart(
          title: l10n.experimentChartSteps,
          primary: primary,
          color: Theme.of(context).colorScheme.primary,
          baseline: baseline,
        );
      },
    );
  }
}

final class _CheckinTimeline extends StatelessWidget {
  final List<ExperimentCheckin> checkins;
  final bool loading;

  const _CheckinTimeline({required this.checkins, required this.loading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.experimentDetailCheckinsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (checkins.isEmpty)
              Text(
                l10n.experimentDetailNoData,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final checkin in checkins.reversed)
                _CheckinRow(checkin: checkin),
          ],
        ),
      ),
    );
  }
}

final class _CheckinRow extends StatelessWidget {
  final ExperimentCheckin checkin;

  const _CheckinRow({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormats.formatDate(context, checkin.day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (checkin.note != null && checkin.note!.isNotEmpty)
                  Text(checkin.note!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(l10n.experimentRatingOf5(checkin.rating)),
            backgroundColor: checkin.rating >= 4
                ? Colors.green.withValues(alpha: 0.2)
                : checkin.rating <= 2
                ? Colors.red.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

final class _SeriesChart extends StatelessWidget {
  final String title;
  final List<(DateTime, double)> primary;
  final List<(DateTime, double)>? secondary;
  final String? secondaryTitle;
  final Color color;
  final Color? secondaryColor;
  final double? baseline;

  const _SeriesChart({
    required this.title,
    required this.primary,
    required this.color,
    this.secondary,
    this.secondaryTitle,
    this.secondaryColor,
    this.baseline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (primary.length < 2 && (secondary == null || secondary!.length < 2)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.experimentDetailNoData,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final values = [
      ...primary.map((s) => s.$2),
      ...?secondary?.map((s) => s.$2),
    ];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = maxValue == minValue ? 1.0 : (maxValue - minValue) * 0.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (baseline != null)
              Text(
                _formatValue(baseline!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (secondaryTitle != null)
          Text(
            secondaryTitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 6),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: minValue - padding,
              maxY: maxValue + padding,
              lineBarsData: [
                _lineBar(primary, color),
                if (secondary != null)
                  _lineBar(
                    secondary!,
                    secondaryColor ?? theme.colorScheme.tertiary,
                  ),
              ],
              extraLinesData: baseline == null
                  ? const ExtraLinesData()
                  : ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: baseline!,
                          color: theme.colorScheme.onSurfaceVariant,
                          strokeWidth: 1,
                          dashArray: [6, 4],
                        ),
                      ],
                    ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: primary.length <= 8,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        value.toInt(),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormats.formatShortDate(context, date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      s.x.toInt(),
                    );
                    return LineTooltipItem(
                      '${DateFormats.formatShortDate(context, date)}\n'
                      '${_formatValue(s.y)}',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _lineBar(List<(DateTime, double)> spots, Color c) =>
      LineChartBarData(
        spots: spots
            .map((s) => FlSpot(s.$1.millisecondsSinceEpoch.toDouble(), s.$2))
            .toList(),
        isCurved: true,
        color: c,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.08)),
      );

  static String _formatValue(double value) {
    if (value >= 10000) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

final class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 80,
    child: Center(child: CircularProgressIndicator()),
  );
}

final class _ChartError extends StatelessWidget {
  final String message;

  const _ChartError({required this.message});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

double? _mean(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return null;
  return list.reduce((a, b) => a + b) / list.length;
}
