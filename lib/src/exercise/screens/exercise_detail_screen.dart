import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/units.dart';
import '../../notifications/rest_timer.dart';
import '../../settings/providers/settings.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../exercise_filter.dart';
import '../providers/exercises.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';

/// Exercise detail + full history (T09): media + metadata + instructions +
/// tips/faqs/keywords, then history (best set/PR, volume-over-time chart,
/// per-workout totals and planned-vs-actual metrics).
final class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    Widget statusScaffold(Widget body) => Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseDetailAppBar)),
      body: body,
    );

    return exerciseAsync.when(
      loading: () =>
          statusScaffold(const Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          statusScaffold(Center(child: Text(l10n.errorWithMessage('$e')))),
      data: (exercise) {
        if (exercise == null) {
          return statusScaffold(
            Center(child: Text(l10n.exerciseDetailNotFound)),
          );
        }
        return historyAsync.when(
          loading: () =>
              statusScaffold(const Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              statusScaffold(Center(child: Text(l10n.errorWithMessage('$e')))),
          data: (history) => _DetailView(exercise: exercise, history: history),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

final class _DetailView extends ConsumerWidget {
  final Exercise exercise;
  final List<ExerciseHistoryEntry> history;

  const _DetailView({required this.exercise, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = _HistoryMetrics.fromHistory(history);
    final unit = ref.watch(settingsProvider).weightUnit;
    final hasMedia = exercise.imagePath != null || exercise.videoPath != null;
    // Media (220) + name block + fact chips; a smaller height when the
    // exercise has no media so the collapsed header leaves no gap.
    final expandedHeight = hasMedia ? 330.0 : 112.0;

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedHeight,
              title: Text(exercise.name),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _Header(exercise: exercise),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  tabs: [
                    Tab(text: l10n.exerciseDetailTabHistory),
                    Tab(text: l10n.exerciseDetailTabDetails),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _HistoryTab(history: history, metrics: metrics, unit: unit),
              _DetailsTab(exercise: exercise),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned header: media, then name, then the quick-fact chips (type, body
/// parts, equipment). Stays visible while the History/Details tabs scroll.
final class _Header extends StatelessWidget {
  final Exercise exercise;
  const _Header({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MediaHeader(exercise: exercise),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceL,
            FitFatTokens.spaceM,
            FitFatTokens.spaceL,
            FitFatTokens.spaceS,
          ),
          child: Text(
            exercise.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL),
          child: _FactChips(exercise: exercise),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
      ],
    );
  }
}

/// Type + body-part + equipment chips. Muscles live in the Details tab.
final class _FactChips extends StatelessWidget {
  final Exercise exercise;
  const _FactChips({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = exercise.isWeightlifting
        ? l10n.exerciseTypeWeightlifting
        : l10n.exerciseTypeCardio;
    final bodyParts = splitTags(exercise.bodyPart);
    final equipments = splitTags(
      exercise.equipment,
    ).map(canonicalEquipmentTag).toList();
    if (bodyParts.isEmpty && equipments.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Chip(label: Text(typeLabel)),
      );
    }
    return Wrap(
      spacing: FitFatTokens.spaceS,
      runSpacing: FitFatTokens.spaceS,
      children: [
        Chip(label: Text(typeLabel)),
        for (final part in bodyParts) Chip(label: Text(part)),
        for (final equipment in equipments) Chip(label: Text(equipment)),
      ],
    );
  }
}

/// History tab (default): PR summary + volume/duration-over-time chart +
/// per-workout cards.
final class _HistoryTab extends StatelessWidget {
  final List<ExerciseHistoryEntry> history;
  final _HistoryMetrics metrics;
  final WeightUnit unit;

  const _HistoryTab({
    required this.history,
    required this.metrics,
    required this.unit,
  });

  /// Converts kg-based chart values into the display unit (no-op for kg).
  List<(DateTime, double)> _converted(List<(DateTime, double)> spots) => [
    for (final (date, value) in spots) (date, weightFromKg(value, unit)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceXl),
        child: Center(
          child: Text(
            l10n.exerciseDetailHistoryEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: FitFatTokens.spaceXxl),
      children: [
        _HistorySummary(metrics: metrics, unit: unit),
        if (metrics.chartSpots.isNotEmpty && metrics.chartSpots.length >= 2)
          _HistoryChart(
            title: metrics.usesWeight
                ? l10n.exerciseDetailVolumeOverTime
                : l10n.exerciseDetailDurationOverTime,
            spots: metrics.usesWeight
                ? _converted(metrics.chartSpots)
                : metrics.chartSpots,
            color: theme.colorScheme.primary,
          ),
        if (metrics.trendSpots.isNotEmpty && metrics.trendSpots.length >= 2)
          _HistoryChart(
            title: metrics.usesWeight
                ? l10n.exerciseDetailWeightTrend
                : l10n.exerciseDetailRepsTrend,
            spots: metrics.usesWeight
                ? _converted(metrics.trendSpots)
                : metrics.trendSpots,
            color: theme.colorScheme.tertiary,
          ),
        ..._buildWorkoutCards(context),
      ],
    );
  }

  /// Per-workout cards in the provider's (newest-first) order, each annotated
  /// with its total volume (display units), the previous workout's volume
  /// (null for the oldest) and whether it set a new PR (volume > every older
  /// workout — conversion-invariant since it's a ratio comparison).
  List<Widget> _buildWorkoutCards(BuildContext context) {
    final volumes = history.map((e) {
      var volume = 0.0;
      for (final set in e.sets) {
        volume += set.totalVolume;
      }
      return weightFromKg(volume, unit);
    }).toList();

    final n = history.length;
    final isPr = List<bool>.filled(n, false);
    var bestOlder = 0.0;
    for (var i = n - 1; i >= 0; i--) {
      isPr[i] = volumes[i] > bestOlder;
      if (volumes[i] > bestOlder) bestOlder = volumes[i];
    }

    return [
      for (var i = 0; i < n; i++)
        _WorkoutHistoryCard(
          entry: history[i],
          volume: volumes[i],
          previousVolume: i < n - 1 ? volumes[i + 1] : null,
          isPr: isPr[i],
          usesWeight: metrics.usesWeight,
          unit: unit,
        ),
    ];
  }
}

/// Details tab: numbered instructions, tips, structured FAQs, muscle tags.
final class _DetailsTab extends StatelessWidget {
  final Exercise exercise;
  const _DetailsTab({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.only(bottom: FitFatTokens.spaceXxl),
      children: [
        if (exercise.instructions != null && exercise.instructions!.isNotEmpty)
          _InstructionSection(
            title: l10n.exerciseDetailInstructions,
            items: exercise.instructions!,
            numbered: true,
          ),
        if (exercise.tips != null && exercise.tips!.isNotEmpty)
          _InstructionSection(
            title: l10n.exerciseDetailTips,
            items: exercise.tips!,
            numbered: false,
          ),
        if (exercise.faqs != null && exercise.faqs!.trim().isNotEmpty)
          _FaqSection(title: l10n.exerciseDetailFaqs, text: exercise.faqs!),
        _MusclesSection(exercise: exercise),
      ],
    );
  }
}

/// Renders `**bold**` Markdown segments as bold runs.
final class _RichText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _RichText({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(_spans(), style: style);
  }

  TextSpan _spans() {
    final boldStyle = style?.copyWith(fontWeight: FontWeight.bold);
    final segments = text.split('**');
    return TextSpan(
      style: style,
      children: [
        for (var i = 0; i < segments.length; i++)
          if (segments[i].isNotEmpty)
            TextSpan(text: segments[i], style: i.isOdd ? boldStyle : null),
      ],
    );
  }
}

/// Primary/secondary muscle chips (Details tab).
final class _MusclesSection extends StatelessWidget {
  final Exercise exercise;
  const _MusclesSection({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primary = splitTags(exercise.primaryMuscle);
    final secondary = splitTags(exercise.secondaryMuscle);
    if (primary.isEmpty && secondary.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (primary.isNotEmpty) ...[
            Text(
              l10n.exerciseDetailPrimaryMuscle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            Wrap(
              spacing: FitFatTokens.spaceS,
              runSpacing: FitFatTokens.spaceS,
              children: [
                for (final muscle in primary) Chip(label: Text(muscle)),
              ],
            ),
          ],
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: FitFatTokens.spaceM),
            Text(
              l10n.exerciseDetailSecondaryMuscle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            Wrap(
              spacing: FitFatTokens.spaceS,
              runSpacing: FitFatTokens.spaceS,
              children: [
                for (final muscle in secondary) Chip(label: Text(muscle)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media header (image; video when a video asset is bundled — gracefully
// falls back to the image since bundled videos are deferred/absent)
// ---------------------------------------------------------------------------

final class _MediaHeader extends StatefulWidget {
  final Exercise exercise;
  const _MediaHeader({required this.exercise});

  @override
  State<_MediaHeader> createState() => _MediaHeaderState();
}

final class _MediaHeaderState extends State<_MediaHeader> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final path = widget.exercise.videoPath;
    if (path == null) return;
    final controller = VideoPlayerController.asset(path);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
      await controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final theme = Theme.of(context);
    final imagePath = exercise.imagePath;

    // Images render BoxFit.contain on a surface backdrop (no cropping);
    // tapping the image opens a full-screen zoomable viewer.
    final Widget? image = imagePath == null
        ? null
        : GestureDetector(
            onTap: () => _openViewer(context),
            child: Container(
              height: 220,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _placeholder(theme),
              ),
            ),
          );

    final video = _controller != null && !_videoFailed
        ? Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: VideoPlayer(_controller!),
              ),
              _VideoPlayPauseButton(controller: _controller!),
            ],
          )
        : null;

    final Widget? child = video ?? image;
    if (child == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(FitFatTokens.radiusL),
      ),
      child: child,
    );
  }

  void _openViewer(BuildContext context) {
    final imagePath = widget.exercise.imagePath;
    if (imagePath == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          imagePath: imagePath,
          exerciseName: widget.exercise.name,
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
    height: 220,
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      widget.exercise.isWeightlifting
          ? Icons.fitness_center
          : Icons.directions_run,
      size: 48,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

/// Full-screen, zoomable/panable image viewer opened by tapping the detail
/// header image.
final class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String exerciseName;

  const _FullScreenImageViewer({
    required this.imagePath,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(exerciseName, style: const TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

final class _VideoPlayPauseButton extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoPlayPauseButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final playing = value.isPlaying;
        return IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          onPressed: () => playing ? controller.pause() : controller.play(),
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

final class _InstructionSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool numbered;

  const _InstructionSection({
    required this.title,
    required this.items,
    required this.numbered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: FitFatTokens.spaceS),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (numbered)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: FitFatTokens.spaceS,
                        top: 2,
                      ),
                      child: Text(
                        '${i + 1}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(
                        right: FitFatTokens.spaceS,
                        top: 2,
                      ),
                      child: Text('•'),
                    ),
                  Expanded(
                    child: _RichText(
                      text: items[i],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final class _FaqSection extends StatelessWidget {
  final String title;
  final String text;

  const _FaqSection({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faqs = _parseFaqs(text);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        FitFatTokens.spaceL,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: FitFatTokens.spaceS),
          if (faqs.isEmpty)
            _RichText(
              text: text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            )
          else
            for (final faq in faqs) ...[
              _RichText(
                text: faq.$1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceXs),
              _RichText(
                text: faq.$2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceM),
            ],
        ],
      ),
    );
  }

  /// Decodes the structured `[{"q":..,"a":..}, ...]` FAQ blob. Falls back to
  /// an empty list (raw-text rendering) when it is not valid JSON.
  static List<(String, String)> _parseFaqs(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final faqs = <(String, String)>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final q = item['q'];
        final a = item['a'];
        if (q is String &&
            q.trim().isNotEmpty &&
            a is String &&
            a.trim().isNotEmpty) {
          faqs.add((q.trim(), a.trim()));
        }
      }
      return faqs;
    } catch (_) {
      return const [];
    }
  }
}

// ---------------------------------------------------------------------------
// History metrics
// ---------------------------------------------------------------------------

final class _HistoryMetrics {
  final double bestWeightKg;
  final double bestVolumeKg;
  final int bestDurationMinutes;
  final int totalWorkouts;
  final int totalSets;
  final bool usesWeight;
  final List<(DateTime, double)> chartSpots; // chronological
  final List<(DateTime, double)>
  trendSpots; // chronological (best weight OR reps)

  const _HistoryMetrics({
    required this.bestWeightKg,
    required this.bestVolumeKg,
    required this.bestDurationMinutes,
    required this.totalWorkouts,
    required this.totalSets,
    required this.usesWeight,
    required this.chartSpots,
    required this.trendSpots,
  });

  factory _HistoryMetrics.fromHistory(List<ExerciseHistoryEntry> history) {
    var bestWeight = 0.0;
    var bestVolume = 0.0;
    var bestDuration = 0;
    var totalSets = 0;
    var usesWeight = false;

    final byDate = [...history]
      ..sort((a, b) => a.workout.date.compareTo(b.workout.date));

    for (final entry in history) {
      totalSets += entry.sets.length;
      for (final set in entry.sets) {
        if (set.weightKg != null || set.actualWeightKg != null) {
          usesWeight = true;
        }
        if (set.effectiveWeightKg > bestWeight) {
          bestWeight = set.effectiveWeightKg;
        }
        if (set.totalVolume > bestVolume) bestVolume = set.totalVolume;
        if (set.effectiveDurationMinutes > bestDuration) {
          bestDuration = set.effectiveDurationMinutes;
        }
      }
    }

    // Chronological spots with a consistent unit (volume for weighted
    // exercises, otherwise duration).
    final unitIsWeight = usesWeight;
    final ordered = <(DateTime, double)>[];
    final trend = <(DateTime, double)>[];
    for (final entry in byDate) {
      var volume = 0.0;
      var duration = 0;
      var bestCellWeight = 0.0;
      var effectiveReps = 0;
      for (final set in entry.sets) {
        volume += set.totalVolume;
        duration += set.effectiveDurationMinutes;
        if (set.effectiveWeightKg > bestCellWeight) {
          bestCellWeight = set.effectiveWeightKg;
        }
        effectiveReps += set.effectiveReps;
      }
      ordered.add((
        entry.workout.date,
        unitIsWeight ? volume : duration.toDouble(),
      ));
      trend.add((
        entry.workout.date,
        unitIsWeight ? bestCellWeight : effectiveReps.toDouble(),
      ));
    }

    return _HistoryMetrics(
      bestWeightKg: bestWeight,
      bestVolumeKg: bestVolume,
      bestDurationMinutes: bestDuration,
      totalWorkouts: history.length,
      totalSets: totalSets,
      usesWeight: usesWeight,
      chartSpots: ordered,
      trendSpots: trend,
    );
  }
}

final class _HistorySummary extends StatelessWidget {
  final _HistoryMetrics metrics;
  final WeightUnit unit;

  const _HistorySummary({required this.metrics, required this.unit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final bestLabel = metrics.usesWeight
        ? l10n.exerciseDetailBestWeight
        : l10n.exerciseDetailBestDuration;
    final bestValue = metrics.usesWeight
        ? l10n.workoutSummaryValueKg(
            formatWeightValue(metrics.bestWeightKg, unit),
            weightUnitLabel(unit),
          )
        : l10n.workoutDetailPlannedSetDuration(
            '${metrics.bestDurationMinutes}',
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(label: bestLabel, value: bestValue, theme: theme),
          ),
          Expanded(
            child: _StatTile(
              label: l10n.exerciseDetailTotalWorkouts,
              value: '${metrics.totalWorkouts}',
              theme: theme,
            ),
          ),
          Expanded(
            child: _StatTile(
              label: l10n.exerciseDetailTotalSets,
              value: '${metrics.totalSets}',
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

final class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatTile({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFatTokens.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

final class _HistoryChart extends StatelessWidget {
  final String title;
  final List<(DateTime, double)> spots; // chronological, >= 2 points
  final Color color;

  const _HistoryChart({
    required this.title,
    required this.spots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = spots.map((s) => s.$2).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = maxValue == minValue ? 1.0 : (maxValue - minValue) * 0.2;

    final xs = spots.map((s) => s.$1.millisecondsSinceEpoch.toDouble());
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    // ~4 evenly spaced date labels regardless of how many points exist —
    // without an explicit interval fl_chart labels every spot and they overlap.
    final xInterval = math.max((maxX - minX) / 4, 86400000.0);
    // Round the y range to human steps (1/2/2.5/5 × 10ⁿ).
    final yInterval = _niceStep((maxValue - minValue + 2 * padding) / 4);

    return Card(
      margin: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceM,
        FitFatTokens.spaceL,
        0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minValue - padding,
                  maxY: maxValue + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots
                          .map(
                            (s) => FlSpot(
                              s.$1.millisecondsSinceEpoch.toDouble(),
                              s.$2,
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: xInterval,
                        getTitlesWidget: (value, meta) {
                          if (value < minX || value > maxX) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormats.formatShortDate(context, date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            _compactAxisLabel(value),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          s.x.toInt(),
                        );
                        return LineTooltipItem(
                          '${DateFormats.formatShortDate(context, date)}\n'
                          '${s.y.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smallest "nice" step (1/2/2.5/5 × 10ⁿ) covering [raw].
double _niceStep(double raw) {
  if (raw <= 0) return 1;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (raw <= m * magnitude) return m * magnitude;
  }
  return 10 * magnitude;
}

/// Compact y-axis label: whole numbers where possible, k-suffix for thousands.
String _compactAxisLabel(double value) {
  if (value >= 1000 || value <= -1000) {
    final k = value / 1000;
    return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

// ---------------------------------------------------------------------------
// Per-workout history card
// ---------------------------------------------------------------------------

/// One historical workout for this exercise. Collapsed by default: name,
/// date, trend and summary cells. Tapping expands the adherence breakdown
/// and the full per-set grid.
final class _WorkoutHistoryCard extends StatefulWidget {
  final ExerciseHistoryEntry entry;

  /// Total volume already converted to the display unit.
  final double volume;
  final double? previousVolume;
  final bool isPr;
  final bool usesWeight;
  final WeightUnit unit;

  const _WorkoutHistoryCard({
    required this.entry,
    required this.volume,
    required this.previousVolume,
    required this.isPr,
    required this.usesWeight,
    required this.unit,
  });

  @override
  State<_WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

final class _WorkoutHistoryCardState extends State<_WorkoutHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entry = widget.entry;
    final volume = widget.volume;
    final sets = entry.sets;
    var duration = 0;
    for (final set in sets) {
      duration += set.effectiveDurationMinutes;
    }
    final completed = sets.where((s) => s.isCompleted).length;
    final totalReps = sets.fold(0, (sum, s) => sum + s.effectiveReps);
    final totalDistance = sets.fold(
      0.0,
      (sum, s) => sum + s.effectiveDistanceMeters,
    );

    final plannedVolume = sets.fold(
      0.0,
      (sum, s) => sum + (s.reps ?? 0) * (s.weightKg ?? 0),
    );
    final effectiveVolume = sets.fold(
      0.0,
      (sum, s) => sum + (s.effectiveReps * s.effectiveWeightKg),
    );
    final adherence = plannedVolume > 0
        ? ((effectiveVolume / plannedVolume) * 100).clamp(0, 999).toDouble()
        : null;
    final setsCompletedPct = sets.isEmpty
        ? null
        : ((completed / sets.length) * 100).round();

    return Card(
      margin: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceM,
        FitFatTokens.spaceL,
        0,
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(FitFatTokens.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.workout.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    DateFormats.formatShortDate(context, entry.workout.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              _TrendHeader(
                volume: volume,
                previousVolume: widget.previousVolume,
                isPr: widget.isPr,
                usesWeight: widget.usesWeight,
                unit: widget.unit,
              ),
              const SizedBox(height: FitFatTokens.spaceM),
              Row(
                children: [
                  _SummaryCell(
                    label: widget.usesWeight
                        ? l10n.workoutSummaryVolume
                        : l10n.workoutSummaryTotalDuration,
                    value: widget.usesWeight
                        ? l10n.workoutSummaryValueKg(
                            formatWeightValue(volume, widget.unit),
                            weightUnitLabel(widget.unit),
                          )
                        : formatRestDuration(Duration(minutes: duration)),
                    theme: theme,
                    alignEnd: false,
                  ),
                  _SummaryCell(
                    label: l10n.workoutSummaryTotalReps,
                    value: '$totalReps',
                    theme: theme,
                    alignEnd: true,
                  ),
                  _SummaryCell(
                    label: l10n.workoutSummaryTotalDistance,
                    value: formatDecimal(totalDistance),
                    theme: theme,
                    alignEnd: true,
                  ),
                  _SummaryCell(
                    label: l10n.exerciseDetailSetsCompleted,
                    value: '$completed/${sets.length}',
                    theme: theme,
                    alignEnd: true,
                  ),
                ],
              ),
              // Expanded-only detail: adherence bars + the full per-set grid.
              if (_expanded) ...[
                if (adherence != null) ...[
                  const SizedBox(height: FitFatTokens.spaceM),
                  Text(
                    l10n.exerciseDetailPlannedVsActual,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceS),
                  _ProgressBar(
                    label: l10n.exerciseDetailVolumeAdherence,
                    value: adherence,
                    l10n: l10n,
                    color: theme.colorScheme.primary,
                  ),
                  if (setsCompletedPct != null)
                    Padding(
                      padding: const EdgeInsets.only(top: FitFatTokens.spaceS),
                      child: _ProgressBar(
                        label: l10n.exerciseDetailSetsCompleted,
                        value: setsCompletedPct.toDouble(),
                        l10n: l10n,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                ],
                const SizedBox(height: FitFatTokens.spaceM),
                _SetGridHeader(l10n: l10n),
                const SizedBox(height: FitFatTokens.spaceXs),
                for (final set in sets)
                  _SetRow(
                    set: set,
                    usesWeight: widget.usesWeight,
                    l10n: l10n,
                    unit: widget.unit,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Δ-vs-previous-workout header: volume delta with a trend icon + "New PR"
/// badge when this workout beats every older one.
final class _TrendHeader extends StatelessWidget {
  final double volume;
  final double? previousVolume;
  final bool isPr;
  final bool usesWeight;
  final WeightUnit unit;

  const _TrendHeader({
    required this.volume,
    required this.previousVolume,
    required this.isPr,
    required this.usesWeight,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;
    final prev = previousVolume;
    final unitLabel = usesWeight ? weightUnitLabel(unit) : 'min';

    final delta = prev == null ? 0.0 : volume - prev;
    final (icon, color, label) = delta > 0
        ? (
            Icons.trending_up,
            statusColors.success,
            l10n.exerciseDetailTrendDelta(
              '+${formatDecimal(delta)}',
              unitLabel,
            ),
          )
        : delta < 0
        ? (
            Icons.trending_down,
            theme.colorScheme.error,
            l10n.exerciseDetailTrendDelta(
              '-${formatDecimal(delta.abs())}',
              unitLabel,
            ),
          )
        : (
            Icons.trending_flat,
            theme.colorScheme.outline,
            l10n.exerciseDetailTrendSame,
          );

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: FitFatTokens.spaceS),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isPr)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FitFatTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
            ),
            child: Text(
              l10n.exerciseDetailPrBadge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Right-aligned summary value/label cell for the per-workout card.
final class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool alignEnd;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.theme,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

final class _SetGridHeader extends StatelessWidget {
  final AppLocalizations l10n;

  const _SetGridHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(l10n.exerciseDetailSetHeader, style: style),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(l10n.exerciseDetailSetHeaderPlanned, style: style),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(l10n.exerciseDetailSetHeaderActual, style: style),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(l10n.exerciseDetailSetHeaderDelta, style: style),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(l10n.exerciseDetailSetHeaderRest, style: style),
        ),
      ],
    );
  }
}

final class _ProgressBar extends StatelessWidget {
  final String label;
  final double value; // 0-100
  final AppLocalizations l10n;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.l10n,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: FitFatTokens.spaceS),
        Text(
          l10n.exerciseDetailAdherenceValue(value.toStringAsFixed(0)),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

final class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final bool usesWeight;
  final AppLocalizations l10n;
  final WeightUnit unit;

  const _SetRow({
    required this.set,
    required this.usesWeight,
    required this.l10n,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unitLabel = weightUnitLabel(unit);

    final planned = usesWeight
        ? l10n.workoutDetailPlannedSetReps(
            '${set.reps ?? 0}',
            formatWeightValue(set.weightKg ?? 0, unit),
            unitLabel,
          )
        : l10n.workoutDetailPlannedSetDuration('${set.durationMinutes ?? 0}');
    final actual = usesWeight
        ? l10n.workoutDetailActualSetReps(
            '${set.actualReps ?? set.reps ?? 0}',
            formatWeightValue(set.actualWeightKg ?? set.weightKg ?? 0, unit),
            unitLabel,
          )
        : planned;

    final (deltaString, deltaColor) = _delta(context);
    final restString = _restString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFatTokens.spaceXs),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: set.isCompleted
                ? Icon(
                    Icons.check_circle,
                    size: 14,
                    color: theme.colorScheme.primary,
                  )
                : Text(
                    '${set.setNumber}',
                    style: bodyStyle,
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(planned, style: bodyStyle)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(actual, style: bodyStyle)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              deltaString,
              style: bodyStyle?.copyWith(color: deltaColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              restString ?? '—',
              style: bodyStyle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Combined reps/weight delta with a color reflecting the direction:
  /// green when all non-zero deltas improve, red when they regress, amber for
  /// mixed results and neutral for no change / unknown.
  (String, Color) _delta(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<FitFatColors>()!;

    final parts = <String>[];
    var positive = false;
    var negative = false;
    if (set.repsDelta != null) {
      final v = set.repsDelta!;
      if (v > 0) positive = true;
      if (v < 0) negative = true;
      parts.add(l10n.exerciseDetailRepsDelta(_signed(v)));
    }
    if (set.weightDelta != null) {
      final v = set.weightDelta!;
      if (v > 0) positive = true;
      if (v < 0) negative = true;
      parts.add(
        l10n.exerciseDetailWeightDelta(
          _signed(weightFromKg(v, unit)),
          weightUnitLabel(unit),
        ),
      );
    }

    if (parts.isEmpty) return ('—', theme.colorScheme.outline);
    final color = positive && !negative
        ? statusColors.success
        : negative && !positive
        ? theme.colorScheme.error
        : statusColors.warning;
    return (parts.join('·'), color);
  }

  /// Planned rest and, when recorded, the actual rest taken — e.g.
  /// `1:30 → 1:45`. Unchanged rest collapses to a single value.
  String? _restString() {
    final planned = set.restSeconds;
    final took = set.actualRestSeconds;
    if (planned == null) {
      return took == null ? null : formatRestDuration(Duration(seconds: took));
    }
    if (took == null || took == planned) {
      return formatRestDuration(Duration(seconds: planned));
    }
    return '${formatRestDuration(Duration(seconds: planned))} → '
        '${formatRestDuration(Duration(seconds: took))}';
  }

  String _signed(num value) => value > 0
      ? '+${formatDecimal(value.toDouble())}'
      : formatDecimal(value.toDouble());
}
