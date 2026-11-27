import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/screens/dashboard.dart' show formatWeeklyDuration;
import '../../models/units.dart';
import '../../models/workout.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../providers/training.dart';
import '../repositories/training_summaries.dart';

const _tabular = [FontFeature.tabularFigures()];

/// "Nov 16–22" / "16–22 nov" (same month) or "Nov 30 – Dec 6", in the app
/// locale.
String formatWeekRange(BuildContext context, DateTime start) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final end = start.add(const Duration(days: 6));
  if (start.month == end.month) {
    final month = DateFormat.MMM(locale).format(start);
    // Day-first locales (es, fr): "16–22 nov"; month-first (en): "Nov 16–22".
    final dayFirst = (DateFormat.MMMd(locale).pattern ?? '').startsWith('d');
    return dayFirst
        ? '${start.day}–${end.day} $month'
        : '$month ${start.day}–${end.day}';
  }
  return '${DateFormat.MMMd(locale).format(start)} – '
      '${DateFormat.MMMd(locale).format(end)}';
}

/// "Tue 24" style day label.
String formatShortDay(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return '${DateFormat.E(locale).format(d)} ${d.day}';
}

/// "54 min · 6.8 t" or "42 min · 11.2 km" for one workout.
String workoutMetricLine(
  AppLocalizations l10n,
  WorkoutRowSummary s,
  WeightUnit unit,
) => [
  if (s.minutes > 0) formatWeeklyDuration(l10n, s.minutes),
  if (s.volumeKg > 0) formatVolume(s.volumeKg, unit),
  if (s.distanceKm > 0) '${s.distanceKm.toStringAsFixed(1)} km',
].join(' · ');

/// Seven dots, Monday first; filled on days with a workout.
class WeekDots extends StatelessWidget {
  const WeekDots({super.key, required this.days, this.size = 7});

  final Set<int> days;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: days.contains(i) ? scheme.primary : null,
              border: days.contains(i)
                  ? null
                  : Border.all(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                      width: 1.3,
                    ),
            ),
          ),
      ],
    );
  }
}

/// A week as one card: tinted header (dates, day dots, totals), then
/// [children] (usually [WorkoutRow]s) separated by inset dividers.
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.week,
    required this.unit,
    this.children = const [],
  });

  final WeekGroup week;
  final WeightUnit unit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totals = [
      if (week.minutes > 0) formatWeeklyDuration(l10n, week.minutes),
      if (week.volumeKg > 0) formatVolume(week.volumeKg, unit),
      if (week.distanceKm > 0) '${week.distanceKm.toStringAsFixed(1)} km',
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceL,
              FitFatTokens.spaceM,
              FitFatTokens.spaceL,
              FitFatTokens.spaceM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FitFatTokens.spaceXs,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatWeekRange(context, week.start),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    WeekDots(days: week.days),
                  ],
                ),
                if (totals.isNotEmpty)
                  Text(
                    totals,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: _tabular,
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: FitFatTokens.spaceL,
                endIndent: FitFatTokens.spaceL,
                color: scheme.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One finished workout inside a [WeekCard]: type icon, name (+PR), date ·
/// duration · volume-or-distance, and ↻ to start it again.
class WorkoutRow extends StatelessWidget {
  const WorkoutRow({
    super.key,
    required this.workout,
    required this.summary,
    required this.unit,
    required this.onTap,
    required this.onRepeat,
  });

  final Workout workout;
  final WorkoutRowSummary summary;
  final WeightUnit unit;
  final VoidCallback onTap;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = workoutMetricLine(l10n, summary, unit);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFatTokens.spaceL,
          FitFatTokens.spaceS,
          FitFatTokens.spaceXs,
          FitFatTokens.spaceS,
        ),
        child: Row(
          spacing: FitFatTokens.spaceM,
          children: [
            TrainingIcon(cardio: summary.isCardio),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      if (summary.hasPr) const PrBadge(),
                    ],
                  ),
                  Text(
                    [
                      formatShortDay(context, workout.date),
                      if (metrics.isNotEmpty) metrics,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.trainingStartAgain,
              icon: Icon(Icons.repeat, color: scheme.primary),
              onPressed: onRepeat,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tinted square icon: dumbbell for lifting, a runner for cardio.
class TrainingIcon extends StatelessWidget {
  const TrainingIcon({super.key, required this.cardio, this.icon});

  final bool cardio;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
      ),
      child: Icon(
        icon ?? (cardio ? Icons.directions_run : Icons.fitness_center),
        size: 18,
        color: scheme.primary,
      ),
    );
  }
}

class PrBadge extends StatelessWidget {
  const PrBadge({super.key, this.label = 'PR'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      color: Theme.of(context).extension<FitFatColors>()!.success,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// A fixed-width card in a horizontal row (Recent / Templates on the home).
class StartCard extends StatelessWidget {
  const StartCard({
    super.key,
    required this.icon,
    required this.title,
    required this.lines,
    required this.onStart,
    required this.onTap,
    this.badge,
  });

  final Widget icon;
  final String title;
  final List<String> lines;
  final Widget? badge;
  final VoidCallback onStart;
  final VoidCallback onTap;

  static const width = 164.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: _tabular,
    );
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [icon, const Spacer(), ?badge]),
                const SizedBox(height: FitFatTokens.spaceS),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                for (final line in lines)
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.trainingStart),
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
