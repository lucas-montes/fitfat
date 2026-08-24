import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../tags/providers/tags.dart';
import '../../tags/screens/tag_manager_screen.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/goals.dart';
import 'goal_detail_screen.dart';

/// The Planner tab's "Goals" view: a horizontally scrolling **Priorities**
/// bar (the shared tag vocabulary, ranked) above the goals list. Tapping a
/// priority filters the list; the pencil opens the vocabulary manager.
final class GoalsView extends ConsumerStatefulWidget {
  const GoalsView({super.key});

  @override
  ConsumerState<GoalsView> createState() => _GoalsViewState();
}

final class _GoalsViewState extends ConsumerState<GoalsView> {
  final Set<String> _filter = {};

  Future<void> _openTagManager() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const TagManagerScreen()));
    if (!mounted) return;
    ref.invalidate(tagListProvider);
    ref.invalidate(tagNamesProvider);
    ref.invalidate(tagUsageCountsProvider);
    ref.invalidate(goalListProvider);
    setState(_filter.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(tagListProvider);
    final goalsAsync = ref.watch(goalListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Priorities bar -------------------------------------------------
        tagsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (tags) => SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final tag in tags)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(tag.name),
                            selected: _filter.contains(tag.name),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _filter.add(tag.name)
                                  : _filter.remove(tag.name);
                            }),
                            avatar: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tagDisplayColors(
                                  tag.name,
                                  explicitColorsFrom(tags),
                                ).$1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.prioritiesManage,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _openTagManager,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // --- Goals list -----------------------------------------------------
        Expanded(
          child: goalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (goals) {
              final filtered = _filter.isEmpty
                  ? goals
                  : goals
                        .where((g) => g.tags?.any(_filter.contains) ?? false)
                        .toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.flag_outlined,
                  title: goals.isEmpty
                      ? l10n.goalsEmptyAllTitle
                      : l10n.goalsEmptyFilterTitle,
                  description: goals.isEmpty
                      ? l10n.goalsEmptyAll
                      : l10n.goalsEmptyFilter,
                );
              }
              // Active first, then planned, then finished.
              statusRank(GoalStatus s) => switch (s) {
                GoalStatus.active => 0,
                GoalStatus.planned => 1,
                GoalStatus.done => 2,
                GoalStatus.aborted => 3,
              };
              filtered.sort(
                (a, b) => statusRank(a.status).compareTo(statusRank(b.status)),
              );
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(goalListProvider),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _GoalCard(goal: filtered[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _GoalCard extends ConsumerWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final latest = ref.watch(latestGoalProgressProvider(goal.id)).value;
    final progress = goal.progressFrom(latest);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: FitFatTokens.spaceM,
        vertical: 4,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => GoalDetailScreen(goalId: goal.id),
            ),
          );
          ref.invalidate(goalListProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(FitFatTokens.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusDot(context, goal.status),
                  const SizedBox(width: 6),
                  Text(
                    goalStatusLabel(goal.status, l10n),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (goal.tags != null && goal.tags!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [for (final tag in goal.tags!) TagChip(name: tag)],
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusDot(BuildContext context, GoalStatus status) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      GoalStatus.planned => scheme.outline,
      GoalStatus.active => scheme.primary,
      GoalStatus.done => Colors.green.shade600,
      GoalStatus.aborted => scheme.error,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
