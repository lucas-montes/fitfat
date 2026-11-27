import 'package:material_ui/material_ui.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/planner_recurrence.dart';
import '../../models/workout_template.dart';
import '../providers/exercises.dart';
import '../providers/workout_templates.dart';
import '../providers/workouts.dart';
import '../../ui/widgets/empty_state.dart';
import '../widgets/cardio_fields.dart';
import '../../models/units.dart';
import '../../settings/providers/settings.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../../ui/widgets/confirm_delete.dart';
import '../providers/training.dart';
import '../repositories/training_summaries.dart';
import '../start_workout.dart';
import '../widgets/training_widgets.dart';
import 'exercise_picker_sheet.dart';

/// Workout templates: the reusable blueprints behind scheduled and repeated
/// sessions. Tap a tile to edit its blueprint; the tile menu starts a session
/// today or deletes it. Scheduled templates materialize planner tasks via
/// TaskRepository.materializeScheduledWorkouts.
/// Workout templates as cards: name (New for recent, never-started ones),
/// size and last done, the exercises with their target sets, and Start.
/// Edit, duplicate and delete live in the card's ⋮.
final class WorkoutTemplatesScreen extends ConsumerStatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  ConsumerState<WorkoutTemplatesScreen> createState() =>
      _WorkoutTemplatesScreenState();
}

final class _WorkoutTemplatesScreenState
    extends ConsumerState<WorkoutTemplatesScreen> {
  bool _searching = false;
  String _query = '';

  Future<void> _openEditor({String? id}) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => WorkoutTemplateFormScreen(initialId: id)),
  );

  Future<void> _delete(TemplateCard t) async {
    final l10n = AppLocalizations.of(context)!;
    await confirmDelete(
      context,
      itemName: t.name,
      cascade: [
        (label: l10n.trainingCascadeExercises, count: t.exercises.length),
        (label: l10n.trainingCascadeSets, count: t.setCount),
      ],
      delete: () async {
        await ref.read(workoutTemplateRepositoryProvider).delete(t.id);
        ref.invalidate(workoutTemplateListProvider);
      },
    );
  }

  Future<void> _duplicate(TemplateCard t) async {
    await ref.read(workoutTemplateRepositoryProvider).duplicate(t.id);
    ref.invalidate(workoutTemplateListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all =
        ref.watch(templateCardsProvider).value ?? const <TemplateCard>[];
    final now = DateTime.now();
    final q = _query.trim().toLowerCase();
    // New (PR) templates first, then the most recently used.
    final cards =
        [
          for (final t in all)
            if (q.isEmpty || t.name.toLowerCase().contains(q)) t,
        ]..sort((a, b) {
          final na = a.isNew(now), nb = b.isNew(now);
          if (na != nb) return na ? -1 : 1;
          final la = a.lastDone, lb = b.lastDone;
          if (la == null && lb == null) return a.name.compareTo(b.name);
          if (la == null) return 1;
          if (lb == null) return -1;
          return lb.compareTo(la);
        });

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.trainingSearchTemplates,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.templatesTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          IconButton(
            tooltip: l10n.templatesNew,
            icon: const Icon(Icons.add),
            onPressed: _openEditor,
          ),
        ],
      ),
      body: all.isEmpty
          ? EmptyState(
              icon: Icons.bookmarks_outlined,
              title: l10n.templatesEmptyTitle,
              description: l10n.templatesEmptyBody,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FitFatTokens.kContentMaxWidth,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(FitFatTokens.spaceL),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FitFatTokens.spaceM),
                  itemBuilder: (_, i) => _TemplateCardView(
                    card: cards[i],
                    isNew: cards[i].isNew(now),
                    onOpen: () => _openEditor(id: cards[i].id),
                    onStart: () =>
                        startTemplate(context, ref, templateId: cards[i].id),
                    onDuplicate: () => _duplicate(cards[i]),
                    onDelete: () => _delete(cards[i]),
                  ),
                ),
              ),
            ),
    );
  }
}

final class _TemplateCardView extends ConsumerWidget {
  const _TemplateCardView({
    required this.card,
    required this.isNew,
    required this.onOpen,
    required this.onStart,
    required this.onDuplicate,
    required this.onDelete,
  });

  final TemplateCard card;
  final bool isNew;
  final VoidCallback onOpen;
  final VoidCallback onStart;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  String _target(TemplateExerciseLine e, WeightUnit unit) {
    final parts = <String>[
      if (e.reps != null) '${e.sets} × ${e.reps}' else '${e.sets}×',
      if (e.weightKg != null && e.weightKg! > 0)
        '${formatWeightValue(e.weightKg!, unit)} ${weightUnitLabel(unit)}',
      if (e.durationMinutes != null) '${e.durationMinutes} min',
      if (e.distanceMeters != null)
        '${(e.distanceMeters! / 1000).toStringAsFixed(1)} km',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final unit = ref.watch(settingsProvider).weightUnit;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceL,
            FitFatTokens.spaceXs,
            FitFatTokens.spaceXs,
            FitFatTokens.spaceL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: FitFatTokens.spaceS,
                children: [
                  Flexible(
                    child: Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (isNew) PrBadge(label: l10n.trainingNew),
                  const Spacer(),
                  PopupMenuButton<VoidCallback>(
                    onSelected: (f) => f(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: onOpen,
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: onDuplicate,
                        child: Text(l10n.templatesDuplicate),
                      ),
                      PopupMenuItem(
                        value: onDelete,
                        child: Text(
                          l10n.commonDelete,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                [
                  l10n.trainingTemplateSize(
                    card.exercises.length,
                    card.setCount,
                  ),
                  card.lastDone == null
                      ? l10n.trainingNeverDone
                      : l10n.trainingLast(
                          formatShortDay(context, card.lastDone!),
                        ),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              Padding(
                padding: const EdgeInsets.only(right: FitFatTokens.spaceM),
                child: Column(
                  spacing: 2,
                  children: [
                    for (final e in card.exercises)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            _target(e, unit),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceM),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(l10n.trainingStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create / edit a template blueprint: name, optional repeat rule, and the
/// exercise blocks with their planned sets. Saving writes the header plus a
/// full blueprint replace.
final class WorkoutTemplateFormScreen extends ConsumerStatefulWidget {
  final String? initialId;

  const WorkoutTemplateFormScreen({super.key, this.initialId});

  @override
  ConsumerState<WorkoutTemplateFormScreen> createState() =>
      _WorkoutTemplateFormScreenState();
}

class _SetDraft {
  final reps = TextEditingController();
  final weightKg = TextEditingController();
  final restSeconds = TextEditingController();
  final durationMinutes = TextEditingController();
  final distanceMeters = TextEditingController();

  /// True once "+ distance" was tapped (or a distance was loaded).
  bool distanceExpanded = false;

  void dispose() {
    reps.dispose();
    weightKg.dispose();
    restSeconds.dispose();
    durationMinutes.dispose();
    distanceMeters.dispose();
  }
}

class _BlockDraft {
  final String exerciseId;
  final List<_SetDraft> sets = [_SetDraft()];

  _BlockDraft(this.exerciseId);
}

class _WorkoutTemplateFormScreenState
    extends ConsumerState<WorkoutTemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _intervalDaysCtrl = TextEditingController();
  PlannerRecurrenceType? _repeatType;
  final Set<int> _weekdays = {};
  List<_BlockDraft> _blocks = [];
  bool _saving = false;
  bool _loaded = false;
  DateTime _startDate = DateTime.now();

  bool get _isEditing => widget.initialId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _intervalDaysCtrl.dispose();
    for (final block in _blocks) {
      for (final set in block.sets) {
        set.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _load() async {
    final details = await ref.read(
      workoutTemplateDetailsProvider(widget.initialId!).future,
    );
    if (details == null || !mounted) return;
    final t = details.template;
    // Seed drafts from the stored blueprint.
    for (final block in _blocks) {
      for (final set in block.sets) {
        set.dispose();
      }
    }
    setState(() {
      _nameCtrl.text = t.name;
      _startDate = t.startDate;
      final rule = t.recurrence;
      if (rule != null && rule.isValid) {
        _repeatType = rule.type;
        _weekdays.addAll(rule.weekdays ?? const {});
        if (rule.intervalDays != null) {
          _intervalDaysCtrl.text = rule.intervalDays.toString();
        }
      } else {
        _repeatType = null;
      }
      _blocks = [
        for (final block in details.blocks)
          _BlockDraft(block.exercise.exerciseId)
            ..sets.clear()
            ..sets.addAll([
              for (final set in block.sets)
                _SetDraft()
                  ..reps.text = set.reps?.toString() ?? ''
                  ..weightKg.text = _num(set.weightKg)
                  ..restSeconds.text = set.restSeconds == null
                      ? ''
                      : (set.restSeconds! / 60).toString()
                  ..durationMinutes.text = set.durationMinutes?.toString() ?? ''
                  ..distanceMeters.text = _num(set.distanceMeters),
            ]),
      ];
      _loaded = true;
    });
  }

  static String _num(double? v) => v == null
      ? ''
      : v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString();

  int? _parseInt(String raw) => int.tryParse(raw.trim());
  double? _parseDouble(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// Parses the rest field (minutes, decimal allowed) into seconds, mirroring
  /// the workout session form. Empty or unparseable input → null.
  int? _parseRestMinutes(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final minutes = double.tryParse(t);
    if (minutes == null || minutes <= 0) return null;
    return (minutes * 60).round();
  }

  void _addExercises() async {
    final picked = await showExercisePickerSheet(
      context,
      initialSelected: _blocks.map((b) => b.exerciseId).toSet(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Keep existing order; append newly picked in selection order.
      final existing = _blocks.map((b) => b.exerciseId).toSet();
      for (final id in picked) {
        if (!existing.contains(id)) _blocks.add(_BlockDraft(id));
      }
      _blocks.removeWhere((b) => !picked.contains(b.exerciseId));
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_blocks.isEmpty) {
      showTopBanner(context, message: l10n.workoutFormSelectExercise);
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final rule = switch (_repeatType) {
        PlannerRecurrenceType.weekly when _weekdays.isNotEmpty =>
          PlannerRecurrence(type: _repeatType!, weekdays: _weekdays),
        PlannerRecurrenceType.interval
            when (_parseInt(_intervalDaysCtrl.text) ?? 0) > 1 =>
          PlannerRecurrence(
            type: _repeatType!,
            intervalDays: _parseInt(_intervalDaysCtrl.text),
          ),
        PlannerRecurrenceType.daily => PlannerRecurrence(
          type: PlannerRecurrenceType.daily,
        ),
        _ => null,
      };
      var templateId = widget.initialId;
      if (templateId == null) {
        templateId = const Uuid().v7();
        await ref
            .read(workoutTemplateRepositoryProvider)
            .upsert(
              WorkoutTemplate(
                id: templateId,
                name: _nameCtrl.text.trim(),
                startDate: _startDate,
                recurrence: rule,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        final existing = await ref.read(
          workoutTemplateDetailsProvider(templateId).future,
        );
        await ref
            .read(workoutTemplateRepositoryProvider)
            .upsert(
              (existing?.template ??
                      WorkoutTemplate(
                        id: templateId,
                        name: '',
                        startDate: _startDate,
                        createdAt: now,
                        updatedAt: now,
                      ))
                  .copyWith(
                    name: _nameCtrl.text.trim(),
                    recurrence: rule,
                    updatedAt: now,
                  ),
            );
      }

      // Resolve exercise names for the snapshot-free blueprint (ids only).
      final blocks = <TemplateBlock>[];
      final exercises = await ref.read(exerciseListProvider.future);
      final byId = {for (final e in exercises) e.id: e};
      for (final draft in _blocks) {
        blocks.add(
          TemplateBlock(
            exercise: WorkoutTemplateExercise(
              id: 'draft',
              templateId: templateId,
              exerciseId: draft.exerciseId,
              sortOrder: blocks.length,
            ),
            sets: [
              for (final set in draft.sets)
                WorkoutTemplateSet(
                  id: 'draft',
                  templateExerciseId: 'draft',
                  setNumber: 0,
                  reps: _parseInt(set.reps.text),
                  weightKg: _parseDouble(set.weightKg.text),
                  restSeconds: _parseRestMinutes(set.restSeconds.text),
                  durationMinutes: _parseInt(set.durationMinutes.text),
                  distanceMeters: _parseDouble(set.distanceMeters.text),
                ),
            ],
          ),
        );
        // Keep names resolvable later even if the catalog renames: nothing
        // stored — display joins by id like sessions do.
        byId[draft.exerciseId]?.name;
      }

      await ref
          .read(workoutTemplateRepositoryProvider)
          .replaceBlueprint(templateId, blocks);
      ref.invalidate(workoutTemplateListProvider);
      ref.invalidate(workoutTemplateDetailsProvider(templateId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showTopBanner(context, message: l10n.errorWithMessage('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.templatesEdit : l10n.templatesNew),
        actions: [
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.workoutFormSaving : l10n.commonSave),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isEditing && !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    autofocus: !_isEditing,
                    decoration: InputDecoration(
                      labelText: l10n.workoutFormNameLabel,
                      hintText: l10n.workoutFormNameHint,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.workoutFormNameRequired
                        : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.plannerViewWeek, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<PlannerRecurrenceType?>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: null,
                        icon: const Icon(Icons.event_busy_outlined),
                        tooltip: l10n.templatesScheduleOff,
                      ),
                      ButtonSegment(
                        value: PlannerRecurrenceType.daily,
                        icon: const Icon(Icons.today_outlined),
                        tooltip: l10n.templatesScheduleDaily,
                      ),
                      ButtonSegment(
                        value: PlannerRecurrenceType.weekly,
                        icon: const Icon(Icons.date_range_outlined),
                        tooltip: l10n.plannerRepeatSummaryWeekly(''),
                      ),
                      ButtonSegment(
                        value: PlannerRecurrenceType.interval,
                        icon: const Icon(Icons.update_outlined),
                        tooltip: l10n.templatesScheduleInterval('N'),
                      ),
                    ],
                    selected: {_repeatType},
                    onSelectionChanged: (s) =>
                        setState(() => _repeatType = s.first),
                  ),
                  if (_repeatType == PlannerRecurrenceType.weekly)
                    Wrap(
                      spacing: 6,
                      children: [
                        for (var wd = 1; wd <= 7; wd++)
                          FilterChip(
                            label: Text(
                              MaterialLocalizations.of(
                                context,
                              ).narrowWeekdays[wd % 7],
                            ),
                            selected: _weekdays.contains(wd),
                            onSelected: (on) => setState(() {
                              on ? _weekdays.add(wd) : _weekdays.remove(wd);
                            }),
                          ),
                      ],
                    ),
                  if (_repeatType == PlannerRecurrenceType.interval)
                    TextFormField(
                      controller: _intervalDaysCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.templatesScheduleInterval(''),
                      ),
                    ),
                  const Divider(height: 32),
                  FilledButton.icon(
                    onPressed: _addExercises,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.workoutFormAddExercise),
                  ),
                  const SizedBox(height: 8),
                  exercisesAsync.maybeWhen(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    orElse: () => Column(
                      children: [
                        for (final (i, block) in _blocks.indexed)
                          _BlockCard(
                            key: ValueKey(block.exerciseId),
                            index: i,
                            block: block,
                            onChanged: () => setState(() {}),
                            onRemove: () => setState(() => _blocks.removeAt(i)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

final class _BlockCard extends ConsumerWidget {
  final int index;
  final _BlockDraft block;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _BlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exercise = ref
        .watch(exerciseListProvider)
        .value
        ?.where((e) => e.id == block.exerciseId)
        .firstOrNull;
    final isCardio = exercise?.isCardio ?? false;
    final distanceHistory =
        ref
            .watch(exerciseDistanceHistoryProvider)
            .value
            ?.contains(block.exerciseId) ??
        false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final exercises = ref.watch(exerciseListProvider).value;
                      final name = exercises
                          ?.where((e) => e.id == block.exerciseId)
                          .firstOrNull
                          ?.name;
                      return Text(
                        name ?? '…',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                  onPressed: onRemove,
                ),
              ],
            ),
            for (final (j, set) in block.sets.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${j + 1}', textAlign: TextAlign.center),
                    ),
                    if (isCardio) ...[
                      Expanded(
                        child: TextFormField(
                          controller: set.durationMinutes,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: l10n.workoutFormDurationLabel,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      // Duration-first: distance only when asked for, or
                      // already used by this set or exercise.
                      if (set.distanceExpanded ||
                          distanceHistory ||
                          set.distanceMeters.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: set.distanceMeters,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: l10n.workoutFormDistanceLabel,
                            ),
                            onChanged: (_) {
                              set.distanceExpanded = true;
                              onChanged();
                            },
                          ),
                        ),
                      ] else
                        AddDistanceButton(
                          label: l10n.cardioAddDistance,
                          compact: true,
                          onPressed: () {
                            set.distanceExpanded = true;
                            onChanged();
                          },
                        ),
                    ] else ...[
                      Expanded(
                        child: TextFormField(
                          controller: set.reps,
                          keyboardType: const TextInputType.numberWithOptions(),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: l10n.workoutFormRepsLabel,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: set.weightKg,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: l10n.workoutFormWeightLabel,
                          ),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: set.restSeconds,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.workoutFormRestLabel,
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        set.dispose();
                        block.sets.removeAt(j);
                        onChanged();
                      },
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () {
                block.sets.add(_SetDraft());
                onChanged();
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.templatesAddSet),
            ),
          ],
        ),
      ),
    );
  }
}
