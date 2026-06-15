import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../../exercise/providers/history_provider.dart';
import '../../../exercise/providers/planned_workout_provider.dart';
import 'calendar_strip.dart';
import 'start_workout_card.dart';
import 'workout_history_card.dart';
import 'day_detail_sheet.dart';

/// The Training tab — replaces the old SeancesHistoryTab.
///
/// Structure from top to bottom:
/// 1. Start workout card (plan-dependent or free-form)
/// 2. Weekly calendar strip (swipeable, planned-dot indicators)
/// 3. Timeline — today's activities (planned + completed)
/// 4. History — list of past completed workouts
class TrainingTab extends ConsumerStatefulWidget {
  const TrainingTab({super.key});

  @override
  ConsumerState<TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends ConsumerState<TrainingTab> {
  DateTime _currentWeekStart = _mondayOfWeek(DateTime.now());
  DateTime _selectedDay = DateTime.now();

  static DateTime _mondayOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  void initState() {
    super.initState();
    // Load data on first build
    Future.microtask(() {
      ref.read(plannedWorkoutProvider.notifier).loadByWeek(_currentWeekStart);
      ref.read(workoutHistoryProvider.notifier).loadHistory();
    });
  }

  void _onWeekChanged(DateTime weekStart) {
    setState(() => _currentWeekStart = weekStart);
    ref.read(plannedWorkoutProvider.notifier).loadByWeek(weekStart);
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    final plannedForDay = ref
        .read(plannedWorkoutProvider)
        .where(
          (pw) =>
              pw.scheduledDate.year == day.year &&
              pw.scheduledDate.month == day.month &&
              pw.scheduledDate.day == day.day,
        )
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DayDetailSheet(date: day, plannedWorkouts: plannedForDay),
    );
  }

  /// Returns a source-specific icon for a planned workout [source] value.
  Widget _plannedSourceIcon(String source) {
    switch (source) {
      case 'coach':
        return const Icon(Icons.school, color: Colors.indigo);
      case 'from_template':
        return const Icon(Icons.description);
      default:
        return const Icon(Icons.schedule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plannedWorkouts = ref.watch(plannedWorkoutProvider);
    final historyWorkouts = ref.watch(workoutHistoryProvider);

    // Planned workouts for today that aren't completed
    final todaysPlanned = plannedWorkouts
        .where(
          (pw) =>
              !pw.isCompleted &&
              pw.scheduledDate.year == _selectedDay.year &&
              pw.scheduledDate.month == _selectedDay.month &&
              pw.scheduledDate.day == _selectedDay.day,
        )
        .toList();

    // Completed workouts for today
    final today = DateTime.now();
    final todaysCompleted = historyWorkouts
        .where(
          (w) =>
              w.endTime != null &&
              w.endTime!.year == today.year &&
              w.endTime!.month == today.month &&
              w.endTime!.day == today.day,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Section 1: Start workout card
        StartWorkoutCard(todaysPlannedWorkouts: todaysPlanned),

        const SizedBox(height: 16),

        // Section 2: Weekly calendar strip
        Text(l10n.today, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        CalendarStrip(
          weekStart: _currentWeekStart,
          selectedDay: _selectedDay,
          plannedWorkouts: plannedWorkouts,
          onWeekChanged: _onWeekChanged,
          onDaySelected: _onDaySelected,
        ),

        const SizedBox(height: 16),

        // Section 3: Timeline — today's activity
        Text(
          l10n.todaysActivity,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (todaysPlanned.isEmpty && todaysCompleted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                l10n.noWorkoutsToday,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          // Show planned (non-completed) workouts for today
          ...todaysPlanned.map(
            (plan) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _plannedSourceIcon(plan.source),
                title: Text(plan.name),
                subtitle: Text(l10n.workout),
                trailing: Chip(
                  label: Text(l10n.today, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
          // Show completed workouts for today
          ...todaysCompleted.map((w) => WorkoutHistoryCard(workout: w)),
        ],

        const SizedBox(height: 16),

        // Section 4: History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        if (historyWorkouts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l10n.noWorkoutsYet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...historyWorkouts.map((w) => WorkoutHistoryCard(workout: w)),
      ],
    );
  }
}
