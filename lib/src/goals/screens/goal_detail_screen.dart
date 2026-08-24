import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../ui/tokens.dart';
import '../providers/goals.dart';
import 'goal_form_screen.dart';

/// Detail view for a single [Goal]: status, priority tags, target progress
/// bar, a per-day progress log, and lifecycle actions (activate / done /
/// abort / reopen / edit / delete).
final class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goalAsync = ref.watch(goalByIdProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) => _onAction(context, ref, action),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.goalsEdit),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.commonDelete),
                ),
              ),
            ],
          ),
        ],
      ),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (goal) {
          if (goal == null) {
            return Center(child: Text(l10n.goalsMissing));
          }
          return _GoalDetailView(goal: goal);
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(goalRepositoryProvider);
    switch (action) {
      case 'edit':
        if (!context.mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => GoalFormScreen(goalId: goalId)),
        );
        ref.invalidate(goalByIdProvider(goalId));
        ref.invalidate(goalListProvider);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.goalsDeleteConfirmTitle),
            content: Text(l10n.goalsDeleteConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await repo.deleteGoal(goalId);
        ref.invalidate(goalListProvider);
        if (context.mounted) Navigator.of(context).pop(true);
    }
  }
}

String goalStatusLabel(GoalStatus status, AppLocalizations l10n) =>
    switch (status) {
      GoalStatus.planned => l10n.goalsStatusPlanned,
      GoalStatus.active => l10n.goalsStatusActive,
      GoalStatus.done => l10n.goalsStatusDone,
      GoalStatus.aborted => l10n.goalsStatusAborted,
    };

final class _GoalDetailView extends ConsumerStatefulWidget {
  final Goal goal;

  const _GoalDetailView({required this.goal});

  @override
  ConsumerState<_GoalDetailView> createState() => _GoalDetailViewState();
}

final class _GoalDetailViewState extends ConsumerState<_GoalDetailView> {
  void _refresh() {
    ref.invalidate(goalByIdProvider(widget.goal.id));
    ref.invalidate(latestGoalProgressProvider(widget.goal.id));
    ref.invalidate(goalProgressProvider(widget.goal.id));
    ref.invalidate(goalListProvider);
  }

  Future<void> _setStatus(GoalStatus status) async {
    await ref
        .read(goalRepositoryProvider)
        .setGoalStatus(widget.goal.id, status);
    _refresh();
  }

  Future<void> _recordProgress() async {
    final l10n = AppLocalizations.of(context)!;
    final valueCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var day = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.goalsRecordProgress),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.goal.unit == null
                      ? (widget.goal.targetType == GoalTargetType.boolean
                            ? l10n.goalsAchievedQuestion
                            : l10n.goalsCurrentValueLabel)
                      : '${l10n.goalsCurrentValueLabel} (${widget.goal.unit})',
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.goalsProgressNoteHint,
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  MaterialLocalizations.of(ctx).formatMediumDate(day),
                ),
                subtitle: Text(l10n.goalsProgressDateLabel),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: day,
                    firstDate: widget.goal.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => day = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  valueCtrl.text.replaceAll(',', '.'),
                );
                if (value == null) return;
                _pendingValue = value;
                _pendingNote = noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim();
                _pendingDay = day;
                Navigator.of(ctx).pop(true);
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    await ref
        .read(goalRepositoryProvider)
        .recordProgress(
          goalId: widget.goal.id,
          day: _pendingDay ?? DateTime.now(),
          value: _pendingValue!,
          note: _pendingNote,
        );
    _pendingValue = null;
    _pendingNote = null;
    _pendingDay = null;
    _refresh();
  }

  double? _pendingValue;
  String? _pendingNote;
  DateTime? _pendingDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goal = widget.goal;

    final latestAsync = ref.watch(latestGoalProgressProvider(goal.id));
    final logAsync = ref.watch(goalProgressProvider(goal.id));
    final latest = latestAsync.value;
    final progress = goal.progressFrom(latest);

    return ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        Text(goal.title, style: theme.textTheme.headlineSmall),
        if (goal.description != null && goal.description!.isNotEmpty) ...[
          const SizedBox(height: FitFatTokens.spaceS),
          Text(goal.description!),
        ],
        const SizedBox(height: FitFatTokens.spaceM),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusChip(status: goal.status),
            for (final tag in goal.tags ?? const <String>[]) TagChip(name: tag),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        Text(
          '${MaterialLocalizations.of(context).formatMediumDate(goal.startDate)}'
          ' → ${goal.endDate == null ? l10n.goalsNoEndDate : MaterialLocalizations.of(context).formatMediumDate(goal.endDate!)}',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: FitFatTokens.spaceXl),
        if (goal.targetType != GoalTargetType.none) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.goalsProgressSection,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _recordProgress,
                icon: const Icon(Icons.add_chart),
                label: Text(l10n.goalsRecordProgress),
              ),
            ],
          ),
          const SizedBox(height: FitFatTokens.spaceS),
          _ProgressSummary(goal: goal, latestValue: latest, progress: progress),
          const SizedBox(height: FitFatTokens.spaceL),
        ] else
          FilledButton.tonalIcon(
            onPressed: () => _setStatus(
              goal.status == GoalStatus.done
                  ? GoalStatus.active
                  : GoalStatus.done,
            ),
            icon: Icon(
              goal.status == GoalStatus.done
                  ? Icons.replay
                  : Icons.check_circle_outline,
            ),
            label: Text(
              goal.status == GoalStatus.done
                  ? l10n.goalsReopen
                  : l10n.goalsMarkDone,
            ),
          ),
        if (goal.targetType != GoalTargetType.none) ...[
          Text(l10n.goalsLogTitle, style: theme.textTheme.titleMedium),
          logAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(FitFatTokens.spaceL),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e'),
            data: (log) {
              if (log.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: FitFatTokens.spaceL,
                  ),
                  child: Text(l10n.goalsNoProgressYet),
                );
              }
              return Column(
                children: [
                  for (final entry in log)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(_entryTitle(entry)),
                      subtitle: entry.note == null ? null : Text(entry.note!),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(goalRepositoryProvider)
                              .deleteProgress(entry.id);
                          _refresh();
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        const Divider(height: FitFatTokens.spaceXl),
        Wrap(
          spacing: FitFatTokens.spaceS,
          runSpacing: FitFatTokens.spaceS,
          children: [
            if (goal.status == GoalStatus.planned)
              OutlinedButton.icon(
                onPressed: () => _setStatus(GoalStatus.active),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.goalsMarkActive),
              ),
            if (goal.status == GoalStatus.active &&
                goal.targetType != GoalTargetType.none) ...[
              OutlinedButton.icon(
                onPressed: () => _setStatus(GoalStatus.done),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l10n.goalsMarkDone),
              ),
              OutlinedButton.icon(
                onPressed: () => _setStatus(GoalStatus.aborted),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(l10n.goalsAbort),
              ),
            ],
            if (goal.status == GoalStatus.done ||
                goal.status == GoalStatus.aborted)
              OutlinedButton.icon(
                onPressed: () => _setStatus(GoalStatus.active),
                icon: const Icon(Icons.replay),
                label: Text(l10n.goalsReopen),
              ),
          ],
        ),
      ],
    );
  }

  String _entryTitle(GoalProgress entry) {
    final l10n = AppLocalizations.of(context)!;
    final date = MaterialLocalizations.of(context).formatMediumDate(entry.day);
    final unit = widget.goal.unit;
    final value = entry.value == entry.value.roundToDouble()
        ? entry.value.toInt().toString()
        : entry.value.toString();
    if (widget.goal.targetType == GoalTargetType.boolean) {
      return '$date · ${entry.value >= 1 ? l10n.goalsAchieved : l10n.goalsNotAchieved}';
    }
    return '$date · $value${unit == null ? '' : ' $unit'}';
  }
}

final class _StatusChip extends StatelessWidget {
  final GoalStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      GoalStatus.planned => (scheme.surfaceContainerHighest, scheme.onSurface),
      GoalStatus.active => (scheme.primaryContainer, scheme.onPrimaryContainer),
      GoalStatus.done => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
      GoalStatus.aborted => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        goalStatusLabel(status, l10n),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

final class _ProgressSummary extends StatelessWidget {
  final Goal goal;
  final double? latestValue;
  final double? progress;

  const _ProgressSummary({
    required this.goal,
    required this.latestValue,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (goal.targetType == GoalTargetType.boolean) {
      final achieved = (latestValue ?? 0) >= 1;
      return Row(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.radio_button_unchecked,
            color: achieved ? Colors.green.shade700 : theme.hintColor,
          ),
          const SizedBox(width: 8),
          Text(achieved ? l10n.goalsAchieved : l10n.goalsNotAchieved),
        ],
      );
    }

    String fmt(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    final currentText = latestValue == null
        ? '—'
        : '${fmt(latestValue!)}${goal.unit == null ? '' : ' ${goal.unit}'}';
    final targetText = goal.targetValue == null
        ? '—'
        : '${fmt(goal.targetValue!)}${goal.unit == null ? '' : ' ${goal.unit}'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: progress, minHeight: 10),
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.goalsCurrentValueLabel}: $currentText · '
          '${l10n.goalsTargetLabel}: $targetText',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
