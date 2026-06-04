import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../providers/dashboard.dart';

// ---------------------------------------------------------------------------
// Shared compact card shell for water / steps / weight status cards.
// Provides consistent visual language: tinted background, rounded corners,
// icon header, optional InkWell tap.
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Water intake status card
// ---------------------------------------------------------------------------

class WaterStatusCard extends ConsumerWidget {
  const WaterStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final waterState = ref.watch(waterTrackerProvider);
    final todayMl = waterState.getTodayMl();
    final goalMl = waterState.dailyGoalMl;
    final progress = goalMl > 0 ? (todayMl / goalMl).clamp(0.0, 1.0) : 0.0;

    // 7-day data for mini chart: newest last
    final last7 = waterState.getLastNDays(7).reversed.toList();
    final barValues = last7
        .map((e) => goalMl > 0 ? (e.value / goalMl).clamp(0.0, 1.0) : 0.0)
        .toList();

    return GestureDetector(
      onDoubleTap: () =>
          ref.read(waterTrackerProvider.notifier).removeWater(250),
      onLongPress: () => _showCustomWaterDialog(context, ref, l10n),
      child: _StatusCard(
        icon: Icons.water_drop,
        color: Colors.blue,
        onTap: () => ref.read(waterTrackerProvider.notifier).addWater(250),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Value line ──
            Text(
              '${(todayMl / 1000).toStringAsFixed(1)} / '
              '${(goalMl / 1000).toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // ── Linear progress bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1.0
                      ? Colors.blue
                      : Colors.blue.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // ── 7-day mini chart ──
            _MiniBarChart(values: barValues, color: Colors.blue, height: 20),
          ],
        ),
      ),
    );
  }

  void _showCustomWaterDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final ctrl = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Water'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount in ml',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.remove),
            label: Text(l10n.remove),
            onPressed: () {
              final ml = int.tryParse(ctrl.text.trim());
              if (ml != null && ml > 0) {
                ref.read(waterTrackerProvider.notifier).removeWater(ml);
              }
              Navigator.pop(ctx);
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.add),
            onPressed: () {
              final ml = int.tryParse(ctrl.text.trim());
              if (ml != null && ml > 0) {
                ref.read(waterTrackerProvider.notifier).addWater(ml);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step tracker status card
// ---------------------------------------------------------------------------

class StepStatusCard extends ConsumerWidget {
  const StepStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepState = ref.watch(stepTrackerProvider);

    // Show a one-time snackbar when permission is denied
    ref.listen(stepTrackerProvider, (prev, next) {
      if (next.permissionDenied && (prev == null || !prev.permissionDenied)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Step tracking needs activity recognition permission. '
              'Enable it in Settings → Apps → fitfat → Permissions.',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    });

    final todaySteps = stepState.getTodaySteps();
    final dailyGoal = stepState.dailyGoal;
    final progress = dailyGoal > 0
        ? (todaySteps / dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    // 7-day data for mini chart: oldest first, newest last
    final today = DateTime.now();
    final barValues = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final steps = stepState.dailyTotals[key] ?? 0;
      return dailyGoal > 0 ? (steps / dailyGoal).clamp(0.0, 1.0) : 0.0;
    });

    return _StatusCard(
      icon: Icons.directions_walk,
      color: Colors.green,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Steps today: ${todaySteps.toStringAsFixed(0)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Value line ──
          Text(
            '${(todaySteps / 1000).toStringAsFixed(1)}k / '
            '${(dailyGoal / 1000).toStringAsFixed(1)}k',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // ── Linear progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0
                    ? Colors.green
                    : Colors.green.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // ── 7-day mini chart ──
          _MiniBarChart(values: barValues, color: Colors.green, height: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body weight status card
// ---------------------------------------------------------------------------

class WeightStatusCard extends ConsumerWidget {
  const WeightStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(bodyWeightEntriesProvider);

    return entriesAsync.when(
      loading: () => _StatusCard(
        icon: Icons.monitor_weight,
        color: Colors.amber,
        child: const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, _) => _StatusCard(
        icon: Icons.monitor_weight,
        color: Colors.amber,
        child: const SizedBox(height: 50),
      ),
      data: (entries) {
        final ordered = [...entries]..sort((a, b) => b.date.compareTo(a.date));
        final latest = ordered.isNotEmpty ? ordered.first : null;
        final previous = ordered.length > 1 ? ordered[1] : null;

        // Trend arrow
        Widget? trend;
        if (latest != null && previous != null) {
          final delta = latest.weightKg - previous.weightKg;
          if (delta.abs() < 0.05) {
            trend = Text(
              '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            );
          } else if (delta > 0) {
            trend = Text(
              '↑',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
              ),
            );
          } else {
            trend = Text(
              '↓',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            );
          }
        }

        // 7-day mini chart: normalize values to 0.0-1.0 within min-max range
        Widget? chart;
        if (ordered.length >= 2) {
          final last7 = ordered.take(7).toList();
          final minW = last7
              .map((e) => e.weightKg)
              .reduce((a, b) => a < b ? a : b);
          final maxW = last7
              .map((e) => e.weightKg)
              .reduce((a, b) => a > b ? a : b);
          final range = maxW - minW;
          final barValues = last7.reversed.map((e) {
            if (range < 0.01) return 0.5; // flat line → middle
            return ((e.weightKg - minW) / range).clamp(0.0, 1.0);
          }).toList();
          chart = _MiniBarChart(
            values: barValues,
            color: Colors.amber,
            height: 20,
          );
        }

        return _StatusCard(
          icon: Icons.monitor_weight,
          color: Colors.amber,
          onTap: () => _logWeight(context, ref),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Value line with trend ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    latest?.weightKg.toStringAsFixed(1) ?? '—',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (trend != null) ...[const SizedBox(width: 2), trend],
                ],
              ),
              if (chart != null) ...[const SizedBox(height: 6), chart],
            ],
          ),
        );
      },
    );
  }

  Future<void> _logWeight(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Log Weight'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (kg) …',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final w = double.tryParse(ctrl.text.trim());
                if (w != null && w > 0) Navigator.pop(ctx, w);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null && context.mounted) {
      await ref.read(bodyWeightTrackerProvider).addEntry(result);
    }
  }
}

// ---------------------------------------------------------------------------
// 7-bar mini chart used for recent history (water, steps, weight).
// Takes normalized values (0.0–1.0) and renders thin rounded bars with an
// opacity gradient (oldest → newest = 0.3 → 1.0).
// ---------------------------------------------------------------------------

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.values,
    required this.color,
    this.height = 24,
  });

  /// Normalized values (0.0–1.0). Newest value should be last (index n-1).
  final List<double> values;

  /// Theme color for the bars.
  final Color color;

  /// Overall chart height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final barCount = values.length;
          final gap = 2.0;
          final barWidth = barCount > 1
              ? (totalWidth - (barCount - 1) * gap) / barCount
              : totalWidth;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final t = barCount > 1 ? i / (barCount - 1) : 1.0;
              final opacity = 0.3 + t * 0.7;
              final barH = (values[i].clamp(0.0, 1.0) * height).clamp(
                0.0,
                height,
              );

              return Padding(
                padding: EdgeInsets.only(right: i < barCount - 1 ? gap : 0),
                child: Container(
                  width: barWidth,
                  height: barH,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: opacity),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
