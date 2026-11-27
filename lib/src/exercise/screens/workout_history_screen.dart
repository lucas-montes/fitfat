import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/workout.dart';
import '../../settings/providers/settings.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/date_filter_chips.dart';
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

  DateFilter _filter = DateFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = ref.watch(settingsProvider).weightUnit;
    final workouts = ref.watch(workoutListProvider).value ?? const <Workout>[];
    final summaries =
        ref.watch(workoutRowSummariesProvider).value ??
        const <String, WorkoutRowSummary>{};
    final w = _filter.window;
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
    final earliest = workouts.isEmpty
        ? DateTime.now()
        : workouts.map((w) => w.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final chips = DateFilterChips(
      months: months,
      value: _filter,
      earliest: earliest,
      onChanged: (f) => setState(() => _filter = f),
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
