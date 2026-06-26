import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/workout_list.dart';
import '../../providers/workout_history.dart';
import '../../providers/active_workout.dart';
import '../../../models/workout.dart';
import 'widgets/history_item.dart';
import 'widgets/today_card.dart';
import 'widgets/upcoming_card.dart';

/// Training tab showing three sections:
///   1. Today's scheduled workout card (or free-form start prompt)
///   2. Upcoming scheduled workouts carousel
///   3. Completed workout history list
class WorkoutListTab extends ConsumerWidget {
  const WorkoutListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final upcomingAsync = ref.watch(workoutListProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);
    final activeAsync = ref.watch(activeWorkoutProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(workoutListProvider.notifier).loadUpcoming();
        await ref.read(workoutHistoryProvider.notifier).load();
      },
      child: _buildBody(
        context,
        ref,
        l10n,
        upcomingAsync,
        historyAsync,
        activeAsync,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<List<Workout>> upcomingAsync,
    AsyncValue<List<Workout>> historyAsync,
    AsyncValue<Workout?> activeAsync,
  ) {
    final upcoming = upcomingAsync.asData?.value;
    final history = historyAsync.asData?.value;

    // Loading state — wrapped in ListView so RefreshIndicator always has a scrollable child
    if (upcomingAsync.isLoading || historyAsync.isLoading) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    // Error states — also wrapped in ListView
    if (upcoming == null) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(child: Text('Error: ${upcomingAsync.error}')),
          ),
        ],
      );
    }
    if (history == null) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(child: Text('Error: ${historyAsync.error}')),
          ),
        ],
      );
    }

    // Split upcoming into today's workouts and later workouts
    final todayWorkouts = upcoming
        .where((w) => w.scheduledDate != null && _isToday(w.scheduledDate!))
        .toList();
    final upcomingLater = upcoming
        .where((w) => w.scheduledDate == null || !_isToday(w.scheduledDate!))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Today's Card ──
        TodayCard(
          l10n: l10n,
          activeWorkout: activeAsync.asData?.value,
          todayWorkout:
              activeAsync.asData?.value == null && todayWorkouts.isNotEmpty
              ? todayWorkouts.first
              : null,
          onResumeActive: () => context.push('/active-workout'),
          onStartScheduled: (id) async {
            await ref.read(activeWorkoutProvider.notifier).startScheduled(id);
            if (context.mounted) context.push('/active-workout');
          },
          onStartFreeform: () async {
            await ref.read(activeWorkoutProvider.notifier).startFreeform();
            if (context.mounted) context.push('/active-workout');
          },
        ),

        // ── Upcoming Carousel ──
        const SizedBox(height: 24),
        Text(l10n.workouts, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (upcomingLater.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcomingLater.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => UpcomingCard(
                l10n: l10n,
                workout: upcomingLater[i],
                onTap: () async {
                  await ref
                      .read(activeWorkoutProvider.notifier)
                      .startScheduled(upcomingLater[i].id);
                  if (context.mounted) context.push('/active-workout');
                },
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.noPlannedWorkoutsForDay,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

        // ── History (independently scrollable) ──
        const SizedBox(height: 24),
        Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: history.isNotEmpty
              ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (_, i) => HistoryItem(workout: history[i]),
                )
              : Center(
                  child: Text(
                    l10n.noHistory,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
