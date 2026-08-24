import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/experiment.dart';
import '../../ui/date_formats.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/experiments.dart';
import '../ui/experiment_labels.dart';
import 'experiment_detail_screen.dart';
import 'experiment_form_screen.dart';

/// Experiments list (the "Experiments" half of the planner's segmented view):
/// a list of self-tracking experiments, newest first. Tapping a card opens its
/// detail. Embeddable — the host supplies the app bar and FAB.
final class ExperimentsView extends ConsumerWidget {
  const ExperimentsView({super.key});

  Future<void> _openDetail(BuildContext context, String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExperimentDetailScreen(experimentId: id),
      ),
    );
  }

  /// Opens the create/edit form; returns true when something was saved so the
  /// host can refresh.
  static Future<bool> openForm(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ExperimentFormScreen()),
    );
    return saved ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final experimentsAsync = ref.watch(experimentListProvider);

    return experimentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
      data: (experiments) {
        if (experiments.isEmpty) {
          return EmptyState(
            icon: Icons.science_outlined,
            title: l10n.experimentsEmptyTitle,
            description: l10n.experimentsEmptyBody,
            ctaLabel: l10n.experimentsFab,
            onCtaPressed: () async {
              if (await openForm(context)) {
                ref.invalidate(experimentListProvider);
              }
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: experiments.length,
          itemBuilder: (context, i) => _ExperimentCard(
            experiment: experiments[i],
            onTap: () => _openDetail(context, experiments[i].id),
          ),
        );
      },
    );
  }
}

final class _ExperimentCard extends StatelessWidget {
  final Experiment experiment;
  final VoidCallback onTap;

  const _ExperimentCard({required this.experiment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;
    final elapsed = experiment.startDate.difference(DateTime.now()).abs();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          experiment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
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
            const SizedBox(height: 4),
            Text(
              DateFormats.formatDate(context, experiment.startDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (elapsed.inDays > 0)
              Text(
                l10n.experimentDaysElapsed(elapsed.inDays),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(
              label: experimentStatusLabel(experiment.status, l10n),
              color: experimentStatusColor(context, experiment.status),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
