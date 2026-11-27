import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/workout.dart';
import '../../settings/providers/settings.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/training.dart';
import '../providers/workouts.dart';
import '../repositories/training_summaries.dart';
import '../start_workout.dart';
import '../widgets/training_widgets.dart';

/// Every finished workout, one card per calendar week (dates, day dots,
/// totals) with the week's workouts as rows. Filter by month chips or a date
/// range; search by name.
final class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key, this.autofocusSearch = false});

  final bool autofocusSearch;

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

final class _WorkoutHistoryScreenState
    extends ConsumerState<WorkoutHistoryScreen> {
  late bool _searching = widget.autofocusSearch;
  String _query = '';

  /// First day of the selected month, or null.
  DateTime? _month;

  /// Selected custom range (end inclusive), or null.
  DateTimeRange? _range;

  ({DateTime? from, DateTime? until}) get _window {
    if (_range != null) {
      return (
        from: _range!.start,
        until: _range!.end.add(const Duration(days: 1)),
      );
    }
    if (_month != null) {
      return (from: _month, until: DateTime(_month!.year, _month!.month + 1));
    }
    return (from: null, until: null);
  }

  Future<void> _pickRange(List<Workout> workouts) async {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    DateTimeRange quick(int days) => DateTimeRange(
      start: day.subtract(Duration(days: days - 1)),
      end: day,
    );
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceL,
            0,
            FitFatTokens.spaceL,
            FitFatTokens.spaceL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FitFatTokens.spaceM,
            children: [
              Text(
                l10n.trainingRange,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              Wrap(
                spacing: FitFatTokens.spaceS,
                runSpacing: FitFatTokens.spaceS,
                children: [
                  for (final (label, range) in [
                    (l10n.trainingLastDays(7), quick(7)),
                    (l10n.trainingLastDays(30), quick(30)),
                    (l10n.trainingLastMonths(3), quick(91)),
                    (
                      l10n.trainingThisYear,
                      DateTimeRange(start: DateTime(day.year), end: day),
                    ),
                  ])
                    ActionChip(
                      label: Text(label),
                      onPressed: () => Navigator.of(ctx).pop(range),
                    ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(l10n.trainingPickDates),
                onPressed: () async {
                  final first = workouts.isEmpty
                      ? DateTime(day.year - 1)
                      : workouts
                            .map((w) => w.date)
                            .reduce((a, b) => a.isBefore(b) ? a : b);
                  final r = await showDateRangePicker(
                    context: ctx,
                    firstDate: DateTime(first.year, first.month, first.day),
                    lastDate: day,
                    initialDateRange: _range,
                  );
                  if (r != null && ctx.mounted) Navigator.of(ctx).pop(r);
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _month = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final unit = ref.watch(settingsProvider).weightUnit;
    final workouts = ref.watch(workoutListProvider).value ?? const <Workout>[];
    final summaries =
        ref.watch(workoutRowSummariesProvider).value ??
        const <String, WorkoutRowSummary>{};
    final w = _window;
    final weeks = groupWeeks(
      workouts,
      summaries,
      from: w.from,
      until: w.until,
      query: _query,
    );

    // Months that have a finished workout, newest first.
    final months = <DateTime>{
      for (final x in workouts)
        if (x.isCompleted) DateTime(x.date.year, x.date.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final thisYear = DateTime.now().year;
    String monthLabel(DateTime m) => m.year == thisYear
        ? DateFormat.MMM(locale).format(m)
        : DateFormat.yMMM(locale).format(m);

    final chips = SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL),
        children: [
          for (final chip in [
            ChoiceChip(
              label: Text(l10n.trainingAllTime),
              selected: _month == null && _range == null,
              onSelected: (_) => setState(() {
                _month = null;
                _range = null;
              }),
            ),
            for (final m in months)
              ChoiceChip(
                label: Text(monthLabel(m)),
                selected: _month == m && _range == null,
                onSelected: (_) => setState(() {
                  _month = m;
                  _range = null;
                }),
              ),
            ChoiceChip(
              avatar: const Icon(Icons.date_range, size: 16),
              label: Text(
                _range == null
                    ? l10n.trainingRange
                    : '${DateFormat.MMMd(locale).format(_range!.start)} – '
                          '${DateFormat.MMMd(locale).format(_range!.end)}',
              ),
              selected: _range != null,
              onSelected: (_) => _pickRange(workouts),
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(right: FitFatTokens.spaceS),
              child: chip,
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.trainingSearchWorkouts,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.trainingWorkouts),
        actions: [
          IconButton(
            tooltip: l10n.commonSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: FitFatTokens.spaceXs),
          chips,
          Expanded(
            child: weeks.isEmpty
                ? EmptyState(
                    icon: Icons.fitness_center,
                    title: l10n.trainingNoMatchTitle,
                    description: l10n.trainingNoMatchBody,
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: FitFatTokens.kContentMaxWidth,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(FitFatTokens.spaceL),
                        itemCount: weeks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: FitFatTokens.spaceM),
                        itemBuilder: (_, i) => WeekCard(
                          week: weeks[i],
                          unit: unit,
                          children: [
                            for (final (workout, summary) in weeks[i].workouts)
                              WorkoutRow(
                                workout: workout,
                                summary: summary,
                                unit: unit,
                                onTap: () => context.go(
                                  '/workout-summary/${workout.id}',
                                ),
                                onRepeat: () => startRoutine(
                                  context,
                                  ref,
                                  sourceWorkoutId: workout.id,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
