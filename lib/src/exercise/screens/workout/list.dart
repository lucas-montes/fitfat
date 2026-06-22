import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/workout_list.dart';
import '../../providers/workout_history.dart';
import '../../providers/active_workout.dart';
import '../../../models/workout.dart';

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
        _TodayCard(
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
              itemBuilder: (_, i) => _UpcomingCard(
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

        // ── History ──
        const SizedBox(height: 24),
        Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (history.isNotEmpty)
          ...history.map((w) => _HistoryItem(workout: w))
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
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

// ─────────────────────────────────────────────────────────────────────────────
// Elapsed timer widget (live-ticking)
// ─────────────────────────────────────────────────────────────────────────────

/// A widget that displays a live-ticking elapsed time since [startedAt].
class _ElapsedTimerWidget extends StatefulWidget {
  final DateTime startedAt;
  final TextStyle? style;

  const _ElapsedTimerWidget({required this.startedAt, this.style});

  @override
  State<_ElapsedTimerWidget> createState() => _ElapsedTimerWidgetState();
}

class _ElapsedTimerWidgetState extends State<_ElapsedTimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    return Text(_formatDuration(elapsed), style: widget.style);
  }
}

/// Format a [Duration] as HH:MM:SS or MM:SS.
String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's card
// ─────────────────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Workout? activeWorkout;
  final Workout? todayWorkout;
  final VoidCallback onResumeActive;
  final void Function(String id) onStartScheduled;
  final VoidCallback onStartFreeform;

  const _TodayCard({
    required this.l10n,
    this.activeWorkout,
    this.todayWorkout,
    required this.onResumeActive,
    required this.onStartScheduled,
    required this.onStartFreeform,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeWorkout != null && activeWorkout!.isActive) ...[
              // ── Active workout resume card ──
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeWorkout!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        _ElapsedTimerWidget(
                          startedAt: activeWorkout!.startedAt!,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onResumeActive,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.resumeWorkout),
                ),
              ),
            ] else if (todayWorkout != null) ...[
              // ── Today's scheduled workout ──
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayWorkout!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.today} · ${DateFormat('HH:mm').format(todayWorkout!.scheduledDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onStartScheduled(todayWorkout!.id),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startWorkout),
                ),
              ),
            ] else ...[
              // ── Empty state — no active workout, no today's workout ──
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 28,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.noPlannedWorkoutsForDay,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onStartFreeform,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startBlankSeance),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upcoming carousel card
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Workout workout;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.l10n,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = workout.scheduledDate!;
    final dayLabel = DateFormat('E').format(date); // e.g. "Wed"
    final dateLabel = DateFormat('MMM d').format(date); // e.g. "Jun 19"

    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  workout.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.startWorkout,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History list item
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryItem extends StatelessWidget {
  final Workout workout;

  const _HistoryItem({required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEE, MMM d',
    ).format(workout.completedAt ?? workout.startedAt!);
    final dur = workout.duration;
    final durationStr = _formatDuration(dur);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(workout.name),
        subtitle: Text('$dateStr · $durationStr'),
        onTap: () => context.push('/workout-history/${workout.id}'),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '${h}h ${m}min';
    }
    return '${m}min';
  }
}
