import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../body/screens/body_metric_dialog.dart';
import '../../budget/providers/budget_overview.dart';
import '../../diet/providers/calories.dart';
import '../../models/bmr_formula.dart';
import '../../diet/providers/meals.dart';
import '../../diet/screens/ingredient_form.dart';
import '../../diet/screens/meal_form.dart';
import '../../exercise/providers/workouts.dart';
import '../../exercise/screens/workout_form.dart';
import '../../goals/providers/goals.dart';
import '../../models/body_metrics_entry.dart';
import '../../models/body_weight_goal.dart';
import '../../models/task.dart';
import '../../models/units.dart';
import '../../planner/providers/planner.dart';
import '../../planner/screens/planner_item_detail.dart';
import '../../models/workout.dart';
import '../../settings/providers/settings.dart';
import '../../sync/local_backup.dart';
import '../../sync/sync_models.dart';
import '../../sync/sync_state_store.dart';
import '../../sync/sync_service.dart';
import '../../ui/date_formats.dart';
import '../../ui/widgets/top_banner.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../../ui/widgets/metric_card.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/dashboard.dart';
import 'wizard.dart';

final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mealsAsync = ref.watch(mealListProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final hasNoData = (mealsAsync.value?.isEmpty ?? false) && (workoutsAsync.value?.isEmpty ?? false);
    final settings = ref.watch(settingsProvider);
    if (!settings.hasSeenWizard && hasNoData) {
      return const OnboardingWizardScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardAppBar),
        actions: [IconButton(icon: const Icon(Icons.settings), tooltip: l10n.settingsAppBar, onPressed: () => context.go('/settings'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: FitFatTokens.kContentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TodayStrip(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _NutritionHeroCard(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _WeightTrendCard(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _WorkoutHeroCard(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _GoalsOverviewCard(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _ExperimentsNudgeCard(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _BudgetMiniCard(),
                  const SizedBox(height: FitFatTokens.spaceL),
                  const _SyncHubCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SyncHubCard extends ConsumerStatefulWidget {
  const _SyncHubCard();
  @override
  ConsumerState<_SyncHubCard> createState() => _SyncHubCardState();
}
final class _SyncHubCardState extends ConsumerState<_SyncHubCard> {
  bool _busySync = false;
  bool _busyBackup = false;
  String _lastSyncText() {
    final state = PrefsSyncStateStore(ref.watch(sharedPreferencesProvider));
    final times = [state.getLastSyncedAt(SyncResource.exercises), state.getLastSyncedAt(SyncResource.ingredients), state.getLastSyncedAt(SyncResource.currencies)].where((v) => v > 0).toList();
    if (times.isEmpty) return 'never';
    final last = times.reduce((a, b) => a > b ? a : b);
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last));
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  Future<void> _syncNow() async {
    if (_busySync) return;
    setState(() => _busySync = true);
    try {
      final s = ref.read(settingsProvider);
      if (s.remoteSyncBaseUrl.isEmpty) {
        if (mounted) showTopBanner(context, message: 'Sync server not configured — open Sync & Backup to set URL');
        return;
      }
      final svc = ref.read(syncServiceProvider);
      final timeout = Duration(seconds: s.apiTimeoutSeconds);
      final results = await Future.wait([
        svc.syncExercises(s.remoteSyncBaseUrl, s.remoteSyncApiKey, endpoint: s.endpointExercises, timeout: timeout),
        svc.syncIngredients(s.remoteSyncBaseUrl, s.remoteSyncApiKey, endpoint: s.endpointIngredients, timeout: timeout),
        svc.syncCurrencies(s.remoteSyncBaseUrl, s.remoteSyncApiKey, s.baseCurrency, endpoint: s.endpointCurrencies, timeout: timeout),
      ]);
      final errors = results.where((r) => !r.ok && r.error != null).map((r) {
        final e = r.error!;
        return e.contains('TimeoutException') ? 'Server not reachable — check URL/key or increase timeout in Settings → Advanced (${s.apiTimeoutSeconds}s)' : e;
      }).toList();
      if (!mounted) return;
      if (errors.isNotEmpty) showTopBanner(context, message: errors.join('\n'));
      setState(() {});
    } finally {
      if (mounted) setState(() => _busySync = false);
    }
  }
  Future<void> _backupNow() async {
    if (_busyBackup) return;
    setState(() => _busyBackup = true);
    try {
      await exportWholeDb(context);
    } catch (e) {
      if (mounted) showTopBanner(context, message: '$e');
    } finally {
      if (mounted) setState(() => _busyBackup = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.sync, size: 20, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text('Sync & Backup', style: theme.textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: () => context.go('/sync'), icon: const Icon(Icons.chevron_right, size: 18), label: const Text('Open'))]),
      const SizedBox(height: FitFatTokens.spaceS),
      Text('Last sync: ${_lastSyncText()}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: FitFatTokens.spaceM),
      Wrap(spacing: FitFatTokens.spaceS, runSpacing: FitFatTokens.spaceS, children: [
        FilledButton.icon(onPressed: _busySync ? null : _syncNow, icon: _busySync ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_sync, size: 18), label: const Text('Sync now')),
        OutlinedButton.icon(onPressed: _busyBackup ? null : _backupNow, icon: _busyBackup ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.backup, size: 18), label: const Text('Backup')),
      ]),
    ])));
  }
}

/// Calories, P/C/F and fiber as five identical rows.
///
/// They used to differ: calories got a headline number, a target tick and
/// headroom, macros got a plain bar. One shape for all five means a glance down
/// the list compares like with like, and the only difference left is the one
/// that matters — calories are the one row you can meaningfully overshoot, so
/// only that bar changes colour.
final class _NutritionHeroCard extends ConsumerWidget {
  const _NutritionHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final metaAsync = ref.watch(calorieTargetMetaProvider);
    final consumedAsync = ref.watch(todayCaloriesProvider);
    final macrosAsync = ref.watch(todayMacrosProvider);
    final targetsAsync = ref.watch(macroTargetsProvider);
    return metaAsync.when(
      loading: () => const Card(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Text('Error'))),
      data: (meta) => Card(
        child: Padding(
          padding: const EdgeInsets.all(FitFatTokens.spaceL),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.local_fire_department, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: FitFatTokens.spaceS),
              Text(l10n.dashboardCalorieTarget, style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: FitFatTokens.spaceM),
            consumedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.dashboardError('$e')),
              data: (consumed) => _MacroTargetRow(
                label: l10n.dashboardMacroCalories,
                color: theme.colorScheme.primary,
                consumed: consumed,
                target: meta.target,
                unit: 'kcal',
                // Calorie overshoot is information, not a failure state: a full
                // red bar reads as "you are over", where a clamped bar would
                // hide how far over.
                overflowColor: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            targetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.dashboardError('$e')),
              data: (targets) => macrosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(l10n.dashboardError('$e')),
                data: (macros) => Column(children: [
                  _MacroTargetRow(label: l10n.dashboardMacroProtein, color: theme.colorScheme.primary, consumed: macros.protein, target: targets.protein),
                  const SizedBox(height: FitFatTokens.spaceM),
                  _MacroTargetRow(label: l10n.dashboardMacroCarbs, color: theme.colorScheme.tertiary, consumed: macros.carbs, target: targets.carbs),
                  const SizedBox(height: FitFatTokens.spaceM),
                  _MacroTargetRow(label: l10n.dashboardMacroFat, color: theme.extension<FitFatColors>()!.warning, consumed: macros.fat, target: targets.fat),
                  const SizedBox(height: FitFatTokens.spaceM),
                  _MacroTargetRow(label: l10n.dashboardMacroFiber, color: theme.extension<FitFatColors>()!.success, consumed: macros.fiber, target: targets.fiber),
                ]),
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            const Divider(height: 1),
            const SizedBox(height: FitFatTokens.spaceS),
            _BmrTdeeFooter(meta: meta),
          ]),
        ),
      ),
    );
  }
}

/// BMR, TDEE and — only when it is not the default equation — its name.
final class _BmrTdeeFooter extends StatelessWidget {
  final CalorieTargetMeta meta;

  const _BmrTdeeFooter({required this.meta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
      Text(
        '${l10n.settingsBmrLabel} ${meta.bmr.round()}  ·  '
        '${l10n.settingsTdeeLabel} ${meta.tdee.round()}'
        '${meta.formula == BmrFormula.katchMcArdle ? '  ·  ${meta.formula.label}' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const Spacer(),
      Text(
        // Estimated means the inputs are placeholders because nothing has been
        // measured yet, which is worth saying next to the numbers themselves.
        meta.isEstimated ? l10n.settingsEstimatedSuffix : '',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ]);
  }
}

/// The two decisions a progress row makes, extracted so they can be pinned
/// without pumping a dashboard that needs a database.
///
/// [over] is deliberately separate from the fill: a row that is over its target
/// clamps to a full bar like any other, but the caller needs to know it crossed
/// so it can change colour. Collapsing the two would lose the overshoot.
({double ratio, bool over}) macroRowState({
  required double consumed,
  required double target,
}) => (
  ratio: target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0),
  over: target > 0 && consumed > target,
);

final class _MacroTargetRow extends StatelessWidget {
  final String label;
  final Color color;
  final double consumed;
  final double target;
  final String? unit;

  /// Paints the bar this colour once [consumed] passes [target]. Null keeps the
  /// bar clamped at full, which is what the macro rows want.
  final Color? overflowColor;

  const _MacroTargetRow({
    required this.label,
    required this.color,
    required this.consumed,
    required this.target,
    this.unit,
    this.overflowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = macroRowState(consumed: consumed, target: target);
    final ratio = state.ratio;
    final over = state.over;
    final valueText = l10n.dashboardMacroProgress(
      consumed.toStringAsFixed(0),
      target.toStringAsFixed(0),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          unit == null ? valueText : '$valueText $unit',
          style: theme.textTheme.bodySmall?.copyWith(
            color: over && overflowColor != null
                ? overflowColor
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ]),
      const SizedBox(height: FitFatTokens.spaceXs),
      ClipRRect(
        borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: 8,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(
            over && overflowColor != null ? overflowColor! : color,
          ),
        ),
      ),
    ]);
  }
}

final class _WeightTrendCard extends ConsumerWidget {
  const _WeightTrendCard();
  Future<void> _addWeight(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showBodyMetricDialog(context, dialogTitle: l10n.bodyMetricsDialogWeightTitle, valueLabel: l10n.bodyMetricsWeightLabel, valueSuffix: 'kg');
    if (result == null || !context.mounted) return;
    final (day, value) = result;
    await ref.read(bodyMetricsRepositoryProvider).upsert(day, weightKg: value);
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(latestBodyMetricsProvider);
  }
  Future<void> _addHeight(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showBodyMetricDialog(context, dialogTitle: l10n.bodyMetricsDialogHeightTitle, valueLabel: l10n.bodyMetricsHeightLabel, valueSuffix: 'cm');
    if (result == null || !context.mounted) return;
    final (day, value) = result;
    await ref.read(bodyMetricsRepositoryProvider).upsert(day, heightCm: value);
    ref.invalidate(bodyMetricsProvider);
    ref.invalidate(latestBodyMetricsProvider);
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(bodyMetricsProvider);
    final latestAsync = ref.watch(latestBodyMetricsProvider);
    final settings = ref.watch(settingsProvider);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Expanded(child: Text(l10n.dashboardWeightTrend, style: theme.textTheme.titleMedium)), if (settings.bodyWeightGoal != null) Text(l10n.bodyMetricsGoal(switch (settings.bodyWeightGoal!) {BodyWeightGoal.lose => l10n.settingsGoalLose, BodyWeightGoal.maintain => l10n.settingsGoalMaintain, BodyWeightGoal.gain => l10n.settingsGoalGain}), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary))]),
      const SizedBox(height: FitFatTokens.spaceM),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _addWeight(context, ref), icon: const Icon(Icons.add), label: Text(l10n.bodyMetricsAddWeight))), const SizedBox(width: FitFatTokens.spaceS), Expanded(child: OutlinedButton.icon(onPressed: () => _addHeight(context, ref), icon: const Icon(Icons.add), label: Text(l10n.bodyMetricsAddHeight)))]),
      const SizedBox(height: FitFatTokens.spaceM),
      latestAsync.when(loading: () => const SizedBox.shrink(), error: (e, _) => Text(l10n.dashboardError('$e')), data: (latest) {
        if (latest == null) return const SizedBox.shrink();
        final parts = <String>[if (latest.weightKg != null) l10n.bodyMetricsLatestWeight(formatWeightValue(latest.weightKg!, settings.weightUnit), weightUnitLabel(settings.weightUnit)), if (latest.heightCm != null) l10n.bodyMetricsLatestHeight(formatLengthValue(latest.heightCm!, settings.lengthUnit), lengthUnitLabel(settings.lengthUnit))];
        if (parts.isEmpty) return const SizedBox.shrink();
        return Padding(padding: const EdgeInsets.only(bottom: FitFatTokens.spaceM), child: Text(parts.join('  ·  '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)));
      }),
      entriesAsync.when(loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())), error: (e, _) => Text(l10n.dashboardError('$e')), data: (entries) => _WeightEvolution(entries: entries, unit: settings.weightUnit, goal: settings.bodyWeightGoal)),
    ])));
  }
}

final class _WeightEvolution extends StatelessWidget {
  final List<BodyMetricsEntry> entries;
  final WeightUnit unit;
  final BodyWeightGoal? goal;
  const _WeightEvolution({required this.entries, required this.unit, this.goal});
  List<(DateTime, double)> get _points => [for (final entry in entries) if (entry.weightKg != null) (entry.day, weightFromKg(entry.weightKg!, unit))];
  String _deltaText(double delta, WeightUnit unit) {
    final sign = delta > 0 ? '+' : '';
    return '$sign${formatWeightValue(delta.abs(), unit)} ${weightUnitLabel(unit)}';
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final points = _points;
    final color = theme.colorScheme.primary;
    if (points.isEmpty) return Text(l10n.bodyMetricsEmptyWeight, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    if (points.length == 1) return Text(l10n.bodyMetricsValueKg(formatWeightValue(entries.first.weightKg!, unit), weightUnitLabel(unit)), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color));
    final now = DateTime.now();
    final delta7 = _computeDelta(points, now, 7);
    final delta30 = _computeDelta(points, now, 30);
    final projection = _computeProjection(points, goal);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 160, child: _WeightLineChart(points: points)),
      const SizedBox(height: FitFatTokens.spaceS),
      Wrap(spacing: FitFatTokens.spaceM, children: [
        if (delta7 != null) Text('${_deltaText(delta7, unit)} (7d)', style: theme.textTheme.bodySmall?.copyWith(color: delta7 < 0 ? theme.extension<FitFatColors>()!.success : theme.extension<FitFatColors>()!.warning)),
        if (delta30 != null) Text('${_deltaText(delta30, unit)} (30d)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (projection != null) Text(projection, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
      ]),
    ]);
  }
  double? _computeDelta(List<(DateTime, double)> points, DateTime now, int days) {
    if (points.length < 2) return null;
    final cutoff = now.subtract(Duration(days: days));
    final recent = points.where((p) => p.$1.isAfter(cutoff)).toList();
    if (recent.length < 2) return null;
    return recent.last.$2 - recent.first.$2;
  }
  String? _computeProjection(List<(DateTime, double)> points, BodyWeightGoal? goal) {
    if (goal == null || points.length < 2) return null;
    final first = points.first.$2;
    final last = points.last.$2;
    final days = points.last.$1.difference(points.first.$1).inDays;
    if (days <= 0) return null;
    final slopePerDay = (last - first) / days;
    if (slopePerDay == 0) return null;
    if (goal == BodyWeightGoal.lose && slopePerDay >= 0) return null;
    if (goal == BodyWeightGoal.gain && slopePerDay <= 0) return null;
    if (goal == BodyWeightGoal.maintain) return 'Stable trend';
    final weeksToGoal = (last - first).abs() > 0 ? '→ trending ${slopePerDay < 0 ? 'down' : 'up'}' : null;
    return weeksToGoal;
  }
}

final class _WeightLineChart extends StatelessWidget {
  final List<(DateTime, double)> points;
  const _WeightLineChart({required this.points});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final values = points.map((s) => s.$2).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = maxValue == minValue ? 1.0 : (maxValue - minValue) * 0.2;
    return CustomPaint(size: Size.infinite, painter: _WeightLinePainter(points: points, color: color, gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), minY: minValue - padding, maxY: maxValue + padding));
  }
}
final class _WeightLinePainter extends CustomPainter {
  final List<(DateTime, double)> points; final Color color; final Color gridColor; final double minY; final double maxY;
  const _WeightLinePainter({required this.points, required this.color, required this.gridColor, required this.minY, required this.maxY});
  @override
  void paint(Canvas canvas, Size size) {
    final startEpoch = points.first.$1.millisecondsSinceEpoch.toDouble();
    final endEpoch = points.last.$1.millisecondsSinceEpoch.toDouble();
    final epochSpan = math.max(1.0, endEpoch - startEpoch);
    final ySpan = maxY - minY;
    Offset project(double epoch, double value) {final x = (epoch - startEpoch) / epochSpan * size.width; final y = size.height - (value - minY) / ySpan * size.height; return Offset(x, y);}
    final path = Path();
    for (var i = 0; i < points.length; i++) {final p = points[i]; final o = project(p.$1.millisecondsSinceEpoch.toDouble(), p.$2); if (i == 0) path.moveTo(o.dx, o.dy); else path.lineTo(o.dx, o.dy);}
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {final y = size.height * i / 2; canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);}
    final fill = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.08)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    for (final p in points) canvas.drawCircle(project(p.$1.millisecondsSinceEpoch.toDouble(), p.$2), 3.5, dotPaint);
  }
  @override bool shouldRepaint(_WeightLinePainter oldDelegate) => oldDelegate.points != points || oldDelegate.color != color || oldDelegate.minY != minY || oldDelegate.maxY != maxY;
}

/// Renders a weekly duration in hours, keeping the minutes when they add
/// something.
///
/// The decision to keep minutes: `0.8 h` is technically correct and much harder
/// to read at a glance than `45 m`, and a sub-hour session is common enough to
/// be worth the branch.
String _formatHours(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) {
    return l10n.dashboardHoursTrainedHours((mins / 60).toStringAsFixed(1));
  }
  if (mins == 0) return l10n.dashboardHoursTrainedHours(hours.toString());
  return l10n.dashboardHoursTrainedHoursMinutes(hours.toString(), mins.toString());
}

final class _WorkoutHeroCard extends ConsumerWidget {
  const _WorkoutHeroCard();
  void _openDetail(BuildContext context, Workout workout) {
    if (workout.isActive) {context.go('/active-workout'); return;}
    context.go('/workout-summary/${workout.id}');
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final latestAsync = ref.watch(latestWorkoutProvider);
    final statsAsync = ref.watch(weeklyWorkoutStatsProvider);
    final weightUnit = ref.watch(settingsProvider).weightUnit;
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.fitness_center, size: 20, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text(l10n.dashboardWeeklyWorkout, style: theme.textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: () => context.go('/exercise'), icon: const Icon(Icons.chevron_right, size: 18), label: Text(l10n.tabExercise))]),
      const SizedBox(height: FitFatTokens.spaceM),
      if (activeWorkout != null) _ActiveWorkoutCardBody(workout: activeWorkout, onTap: () => _openDetail(context, activeWorkout))
      else latestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(l10n.dashboardError('$e')),
        data: (workout) {
          if (workout == null) {
            final hasSync = ref.watch(settingsProvider).remoteSyncBaseUrl.isNotEmpty;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.dashboardNoWorkouts, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: FitFatTokens.spaceM),
              Wrap(spacing: FitFatTokens.spaceS, children: [FilledButton.icon(onPressed: () => context.go('/exercise'), icon: const Icon(Icons.fitness_center, size: 18), label: Text(l10n.dashboardLatestEmptyCta)), if (hasSync) OutlinedButton.icon(onPressed: () => context.go('/exercise'), icon: const Icon(Icons.sync, size: 18), label: Text(l10n.dashboardWeeklyEmptyCtaSync))]),
            ]);
          }
          return _WorkoutCardBody(workout: workout, onTap: () => _openDetail(context, workout));
        },
      ),
      const SizedBox(height: FitFatTokens.spaceM),
      const Divider(height: 1),
      const SizedBox(height: FitFatTokens.spaceM),
      statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(l10n.dashboardError('$e')),
        data: (stats) {
          // Empty means no completed workout, not "nothing summed". Volume is
          // reps x weight, so a cardio-only week is always 0 volume, and
          // keying off volume + minutes claimed such a week was empty.
          if (stats.daysTrained == 0) {
            return Text(l10n.dashboardWeeklyEmptyBody, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
          }
          // Three tiles across a phone width, so all three use the compact
          // metric type. Days reads as x/7 because the window is the current
          // calendar week — the denominator is what makes the number mean
          // anything.
          return Row(children: [
            Expanded(child: MetricCard(compact: true, icon: Icons.event_available_outlined, title: l10n.dashboardDaysTrained, value: l10n.dashboardDaysTrainedValue(stats.daysTrained))),
            const SizedBox(width: FitFatTokens.spaceS),
            Expanded(child: MetricCard(compact: true, icon: Icons.timer_outlined, title: l10n.dashboardHoursTrained, value: _formatHours(l10n, stats.totalMinutes))),
            const SizedBox(width: FitFatTokens.spaceS),
            Expanded(child: MetricCard(compact: true, icon: Icons.calculate_outlined, title: l10n.dashboardVolume, value: formatVolume(stats.totalVolumeKg, weightUnit))),
          ]);
        },
      ),
    ])));
  }
}

final class _TodayStrip extends ConsumerWidget {
  const _TodayStrip();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(upcomingTasksProvider);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.today_outlined, size: 20, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text('Today', style: theme.textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: () => context.go('/plan'), icon: const Icon(Icons.chevron_right, size: 18), label: Text(l10n.plannerAppBar))]),
      const SizedBox(height: FitFatTokens.spaceM),
      tasksAsync.when(
        loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text(l10n.dashboardError('$e')),
        data: (tasks) {
          if (tasks.isEmpty) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.dashboardNoUpcomingTasks, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)), const SizedBox(height: FitFatTokens.spaceM), FilledButton.icon(onPressed: () => context.go('/plan'), icon: const Icon(Icons.add, size: 18), label: Text(l10n.dashboardUpcomingEmptyCta))]);
          final sorted = [...tasks]..sort((a, b) {
            final aPriority = a.tags?.length ?? 0;
            final bPriority = b.tags?.length ?? 0;
            if (aPriority != bPriority) return bPriority.compareTo(aPriority);
            final aTime = a.startTimeMinutes ?? 24*60;
            final bTime = b.startTimeMinutes ?? 24*60;
            return aTime.compareTo(bTime);
          });
          return SizedBox(height: 110, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: sorted.length.clamp(0, 10), separatorBuilder: (_, __) => const SizedBox(width: FitFatTokens.spaceS), itemBuilder: (context, index) {
            final task = sorted[index];
            return _TodayTaskChip(task: task);
          }));
        },
      ),
    ])));
  }
}

final class _TodayTaskChip extends ConsumerWidget {
  final Task task;
  const _TodayTaskChip({required this.task});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(width: 200, padding: const EdgeInsets.all(FitFatTokens.spaceM), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(FitFatTokens.radiusM), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(width: 24, height: 24, child: Checkbox(value: task.done, onChanged: (v) async {
          final repo = ref.read(taskRepositoryProvider);
          await repo.update(task.copyWith(done: v ?? false, taskStatus: (v ?? false) ? TaskStatus.done : TaskStatus.pending));
          ref.invalidate(upcomingTasksProvider);
        })),
        const SizedBox(width: 4),
        Expanded(child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, decoration: task.done ? TextDecoration.lineThrough : null))),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        if (task.workoutId != null) Icon(Icons.fitness_center, size: 12, color: theme.colorScheme.primary),
        if (task.tags != null && task.tags!.isNotEmpty) ...[const SizedBox(width: 4), Expanded(child: Text(task.tags!.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))],
      ]),
      const Spacer(),
      Row(children: [
        Icon(task.workoutId != null ? Icons.fitness_center : Icons.alarm, size: 12, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(task.startTimeMinutes == null ? AppLocalizations.of(context)!.plannerAnytime : DateFormats.formatTime(context, TimeOfDay(hour: task.startTimeMinutes! ~/ 60, minute: task.startTimeMinutes! % 60)), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        InkWell(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlannerItemDetailScreen(itemId: task.id))), child: Icon(Icons.open_in_new, size: 14, color: theme.colorScheme.primary)),
      ]),
    ]));
  }
}

final class _GoalsOverviewCard extends ConsumerWidget {
  const _GoalsOverviewCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final goalsAsync = ref.watch(goalListProvider);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text(l10n.dashboardGoalsTitle, style: theme.textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: () => context.go('/plan'), icon: const Icon(Icons.chevron_right, size: 18), label: Text(l10n.dashboardGoalsCta))]),
      const SizedBox(height: FitFatTokens.spaceM),
      goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(l10n.dashboardError('$e')),
        data: (goals) {
          final active = goals.where((g) => g.isActive).take(3).toList();
          if (active.isEmpty) return Text(l10n.dashboardGoalsEmpty, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
          return Column(children: [
            for (final goal in active) ...[
              _GoalRow(goal: goal),
              const SizedBox(height: FitFatTokens.spaceM),
            ],
          ]);
        },
      ),
    ])));
  }
}

final class _GoalRow extends ConsumerWidget {
  final dynamic goal;
  const _GoalRow({required this.goal});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(latestGoalProgressProvider(goal.id as String));
    return progressAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (value) {
        final progress = goal.progressFrom(value);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(goal.title as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))), if (progress != null) Text('${(progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary))]),
          if (goal.targetValue != null) ...[const SizedBox(height: 4), Text('${value?.toStringAsFixed(1) ?? '-'} / ${goal.targetValue} ${goal.unit ?? ''}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))],
          const SizedBox(height: 4),
          if (progress != null) ClipRRect(borderRadius: BorderRadius.circular(FitFatTokens.radiusFull), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: theme.colorScheme.surfaceContainerHighest)),
        ]);
      },
    );
  }
}

final class _ExperimentsNudgeCard extends ConsumerWidget {
  const _ExperimentsNudgeCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.science_outlined, size: 20, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text(l10n.dashboardExperimentsTitle, style: theme.textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: () => context.go('/plan'), icon: const Icon(Icons.chevron_right, size: 18), label: Text(l10n.dashboardExperimentsCta))]),
      const SizedBox(height: FitFatTokens.spaceM),
      Text(l10n.dashboardExperimentsBody, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: FitFatTokens.spaceM),
      OutlinedButton.icon(onPressed: () => context.go('/plan'), icon: const Icon(Icons.science, size: 18), label: Text(l10n.dashboardExperimentsCta)),
    ])));
  }
}

final class _BudgetMiniCard extends ConsumerWidget {
  const _BudgetMiniCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(budgetOverviewProvider);
    return overviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (overview) {
        if (overview.accounts.isEmpty) return const SizedBox.shrink();
        return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.account_balance_wallet_outlined, size: 20, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text(l10n.budgetAppBar, style: theme.textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: () => context.go('/budget'), icon: const Icon(Icons.chevron_right, size: 18), label: Text(l10n.budgetViewAll))]),
          const SizedBox(height: FitFatTokens.spaceM),
          Row(children: [
            Expanded(child: MetricCard(icon: Icons.account_balance, title: l10n.budgetNetWorth, value: overview.netWorth.toStringAsFixed(2))),
            const SizedBox(width: FitFatTokens.spaceS),
            Expanded(child: MetricCard(icon: Icons.trending_up, title: l10n.budgetMonthIncome, value: overview.monthIncome.toStringAsFixed(0))),
          ]),
          const SizedBox(height: FitFatTokens.spaceS),
          Row(children: [
            Expanded(child: MetricCard(icon: Icons.trending_down, title: l10n.budgetMonthExpense, value: overview.monthExpense.toStringAsFixed(0))),
            const SizedBox(width: FitFatTokens.spaceS),
            Expanded(child: MetricCard(icon: Icons.receipt_long, title: 'Recent', value: overview.recent.length.toString())),
          ]),
        ])));
      },
    );
  }
}

final class _ActiveWorkoutCardBody extends StatelessWidget {
  final Workout workout; final VoidCallback onTap;
  const _ActiveWorkoutCardBody({required this.workout, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final l10n = AppLocalizations.of(context)!; final statusColors = theme.extension<FitFatColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(workout.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))), StatusBadge(label: l10n.statusActive, color: statusColors.warning)]), const SizedBox(height: FitFatTokens.spaceM), FilledButton.tonalIcon(onPressed: onTap, icon: const Icon(Icons.play_arrow), label: Text(l10n.dashboardContinueWorkout))]);
  }
}
final class _WorkoutCardBody extends StatelessWidget {
  final Workout workout; final VoidCallback onTap;
  const _WorkoutCardBody({required this.workout, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final l10n = AppLocalizations.of(context)!; final statusColors = theme.extension<FitFatColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(workout.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))), StatusBadge(label: l10n.statusCompleted, color: statusColors.success)]), const SizedBox(height: FitFatTokens.spaceXs), Text(DateFormats.formatDate(context, workout.date), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)), if (workout.duration > Duration.zero) ...[const SizedBox(height: FitFatTokens.spaceXs), Text(l10n.dashboardDurationMin(workout.duration.inMinutes), style: theme.textTheme.bodySmall)], const SizedBox(height: FitFatTokens.spaceM), OutlinedButton(onPressed: onTap, child: Text(l10n.dashboardOpenWorkout))]);
  }
}
// ignore: unused_element
final class _WelcomeHub extends ConsumerWidget {
  const _WelcomeHub();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!; final theme = Theme.of(context); final scheme = theme.colorScheme;
    return Column(children: [const SizedBox(height: FitFatTokens.spaceXl), Container(width: 72, height: 72, decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.rocket_launch, size: 36, color: scheme.onPrimaryContainer)), const SizedBox(height: FitFatTokens.spaceL), Text(l10n.dashboardWelcomeTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge), const SizedBox(height: FitFatTokens.spaceS), Text(l10n.dashboardWelcomeBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)), const SizedBox(height: FitFatTokens.spaceXl), Card(child: Column(children: [ListTile(leading: const Icon(Icons.soup_kitchen_outlined), title: Text(l10n.dashboardWelcomeActionIngredients), trailing: const Icon(Icons.chevron_right), onTap: () => _openForm(context, ref, const IngredientFormScreen())), const Divider(height: 1), ListTile(leading: const Icon(Icons.restaurant_outlined), title: Text(l10n.dashboardWelcomeActionMeals), trailing: const Icon(Icons.chevron_right), onTap: () => _openForm(context, ref, const MealFormScreen(), onSaved: () {ref.invalidate(mealListProvider); ref.invalidate(todayCaloriesProvider); ref.invalidate(todayMacrosProvider);})), const Divider(height: 1), ListTile(leading: const Icon(Icons.fitness_center), title: Text(l10n.dashboardWelcomeActionWorkouts), trailing: const Icon(Icons.chevron_right), onTap: () => _openForm(context, ref, const WorkoutFormScreen(), onSaved: () {ref.invalidate(workoutListProvider); ref.invalidate(latestWorkoutProvider);}))]))]);
  }
  Future<void> _openForm(BuildContext context, WidgetRef ref, Widget form, {VoidCallback? onSaved}) async {final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => form)); if (saved == true) onSaved?.call();}
}
