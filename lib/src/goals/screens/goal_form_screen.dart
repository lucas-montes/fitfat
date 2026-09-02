import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../models/planner_recurrence.dart';
import '../../models/task.dart';
import '../../planner/providers/planner.dart';
import '../../planner/repositories/task_repository.dart';
import '../../planner/screens/planner_item_form.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../tags/providers/tags.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../notifications/goal_reminder.dart';
import '../providers/goals.dart';

/// Create / edit a [Goal]: title, description, priority tags, date range, a
/// daily reminder, an optional measurable target (baseline → value + unit),
/// and related tasks linked via the `task_goals` junction table.
///
/// The lifecycle status is deliberately not editable here: new goals start
/// active and later move through their lifecycle on the detail screen.
final class GoalFormScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const GoalFormScreen({super.key, this.goalId});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

final class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _baselineCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  late DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  GoalTargetType _targetType = GoalTargetType.none;
  List<String> _tags = [];
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;
  bool _loaded = false;
  DateTime _createdAt = DateTime.now();
  List<_TaskLink> _taskLinks = [];
  Goal? _existing;

  bool get _isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _targetCtrl.dispose();
    _baselineCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final goal = await ref
        .read(goalRepositoryProvider)
        .getGoalById(widget.goalId!);
    if (goal == null || !mounted) return;
    setState(() {
      _existing = goal;
      _titleCtrl.text = goal.title;
      _descriptionCtrl.text = goal.description ?? '';
      _startDate = goal.startDate;
      _endDate = goal.endDate;
      _targetType = goal.targetType;
      if (goal.targetValue != null) {
        _targetCtrl.text = _formatNumber(goal.targetValue!);
      }
      if (goal.baselineValue != null) {
        _baselineCtrl.text = _formatNumber(goal.baselineValue!);
      }
      _unitCtrl.text = goal.unit ?? '';
      _tags = List<String>.from(goal.tags ?? const []);
      _reminderEnabled = goal.reminderEnabled;
      _reminderTime = TimeOfDay(
        hour: goal.reminderTimeMinutes ~/ 60,
        minute: goal.reminderTimeMinutes % 60,
      );
      _createdAt = goal.createdAt;
      _loaded = true;
    });
  }

  static String _formatNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    final baseline =
        double.tryParse(_baselineCtrl.text.replaceAll(',', '.')) ??
        _existing?.baselineValue;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final goal = Goal(
        id: _isEditing ? widget.goalId! : const Uuid().v7(),
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
        startDate: _startDate,
        endDate: _endDate,
        // New goals start active; edits preserve the stored lifecycle
        // (status changes happen on the detail screen).
        status: _existing?.status ?? GoalStatus.active,
        targetType: _targetType,
        targetValue: _targetType == GoalTargetType.numeric ? target : null,
        baselineValue: _targetType == GoalTargetType.numeric ? baseline : null,
        unit:
            _targetType == GoalTargetType.numeric &&
                _unitCtrl.text.trim().isNotEmpty
            ? _unitCtrl.text.trim()
            : null,
        reminderEnabled: _reminderEnabled,
        reminderTimeMinutes: _reminderTime.hour * 60 + _reminderTime.minute,
        createdAt: _createdAt,
        updatedAt: now,
      );
      await ref.read(goalRepositoryProvider).upsertGoal(goal);
      // Reminders follow the goal's own toggle + lifecycle; the scheduler
      // cancels in place when the goal is inactive or the toggle is off.
      await ref
          .read(goalReminderSchedulerProvider)
          .scheduleForGoal(
            goal,
            title: goal.title,
            body: l10n.goalsReminderSubtitle,
          );
      if (!mounted) return;
      if (!_isEditing) {
        // Commit any tasks staged in the create form, then return to the
        // Initiatives list (refreshed via invalidation below).
        final links = ref.read(linksRepositoryProvider);
        final taskRepo = ref.read(taskRepositoryProvider);
        for (final link in _taskLinks) {
          if (link is _TaskLinkExisting) {
            await links.linkTaskGoal(link.task.id, goal.id);
          } else if (link is _TaskLinkCreate) {
            final r = link.result;
            final task = newTask(
              day: r.$2 ?? DateTime.now(),
              title: r.$1,
              startTimeMinutes: r.$3,
              endTimeMinutes: r.$4,
              notes: r.$5,
              workoutId: r.$6,
              tags: r.$7,
              recurrence: r.$8,
              carryOver: r.$9,
            );
            await taskRepo.insert(task);
            if (r.$8 != null) {
              await taskRepo.update(task.copyWith(seriesId: task.id));
            }
            await links.linkTaskGoal(task.id, goal.id);
            ref.invalidate(dayEntriesProvider(task.day));
          }
        }
        ref.invalidate(tasksByGoalProvider(goal.id));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ref.invalidate(goalListProvider);
      ref.invalidate(tagListProvider);
      ref.invalidate(tagNamesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isNumeric = _targetType == GoalTargetType.numeric;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.goalsEdit : l10n.goalsNew)),
      body: _isEditing && !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(FitFatTokens.spaceL),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.goalsFormTitleLabel,
                      hintText: l10n.goalsFormTitleHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.goalsFormTitleRequired
                        : null,
                  ),
                  const SizedBox(height: FitFatTokens.spaceM),
                  TextFormField(
                    controller: _descriptionCtrl,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.goalsFormDescriptionLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceM),
                  TagPicker(
                    tags: _tags,
                    onChanged: (t) => setState(() => _tags = t),
                  ),
                  const SizedBox(height: FitFatTokens.spaceM),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.goalsFormStartLabel),
                    subtitle: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(_startDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickStartDate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _endDate == null
                          ? l10n.goalsNoEndDate
                          : MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(_endDate!),
                    ),
                    subtitle: Text(l10n.goalsFormEndLabel),
                    trailing: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _endDate = null),
                          )
                        : const Icon(Icons.calendar_today),
                    onTap: _pickEndDate,
                  ),
                  const SizedBox(height: FitFatTokens.spaceL),
                  Text(
                    l10n.goalsTargetTypeLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceS),
                  SegmentedButton<GoalTargetType>(
                    segments: [
                      ButtonSegment(
                        value: GoalTargetType.none,
                        label: Text(l10n.goalsTargetTypeNone),
                      ),
                      ButtonSegment(
                        value: GoalTargetType.numeric,
                        icon: const Icon(Icons.tag),
                        label: Text(l10n.goalsTargetTypeNumeric),
                      ),
                      ButtonSegment(
                        value: GoalTargetType.boolean,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l10n.goalsTargetTypeBoolean),
                      ),
                    ],
                    selected: {_targetType},
                    onSelectionChanged: (s) =>
                        setState(() => _targetType = s.first),
                  ),
                  if (isNumeric) ...[
                    const SizedBox(height: FitFatTokens.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _baselineCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.goalsBaselineLabel,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v != null &&
                                    v.isNotEmpty &&
                                    double.tryParse(v.replaceAll(',', '.')) ==
                                        null
                                ? l10n.goalsTargetValueInvalid
                                : null,
                          ),
                        ),
                        const SizedBox(width: FitFatTokens.spaceM),
                        Expanded(
                          child: TextFormField(
                            controller: _targetCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.goalsTargetValueLabel,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                double.tryParse(v!.replaceAll(',', '.')) == null
                                ? l10n.goalsTargetValueInvalid
                                : null,
                          ),
                        ),
                        const SizedBox(width: FitFatTokens.spaceM),
                        Expanded(
                          child: TextFormField(
                            controller: _unitCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.goalsUnitLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: FitFatTokens.spaceL),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.goalsReminderLabel),
                    subtitle: Text(l10n.goalsReminderSubtitle),
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                  ),
                  if (_reminderEnabled)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.goalsReminderTimeLabel),
                      subtitle: Text(
                        DateFormats.formatTime(context, _reminderTime),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickReminderTime,
                    ),
                  if (_isEditing) ...[
                    const SizedBox(height: FitFatTokens.spaceL),
                    _RelatedTasksSection(goalId: widget.goalId!),
                  ] else ...[
                    const SizedBox(height: FitFatTokens.spaceL),
                    _PendingTasksSection(
                      links: _taskLinks,
                      onChanged: (l) => setState(() => _taskLinks = l),
                      excludeGoalId: '',
                    ),
                  ],
                  const SizedBox(height: FitFatTokens.spaceL),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.commonSave),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Related tasks for an existing goal: linked tasks with unlink actions,
/// plus "link existing" (search sheet) and "new task" (planner form) flows.
/// Links live in the `task_goals` junction table.
final class _RelatedTasksSection extends ConsumerStatefulWidget {
  final String goalId;

  const _RelatedTasksSection({required this.goalId});

  @override
  ConsumerState<_RelatedTasksSection> createState() =>
      _RelatedTasksSectionState();
}

final class _RelatedTasksSectionState
    extends ConsumerState<_RelatedTasksSection> {
  Future<void> _unlink(String taskId) async {
    await ref
        .read(linksRepositoryProvider)
        .unlinkTaskGoal(taskId, widget.goalId);
    ref.invalidate(tasksByGoalProvider(widget.goalId));
  }

  Future<void> _linkExisting() async {
    final taskId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _TaskPickerSheet(excludeGoalId: widget.goalId),
    );
    if (taskId == null || !mounted) return;
    await ref.read(linksRepositoryProvider).linkTaskGoal(taskId, widget.goalId);
    if (!mounted) return;
    ref.invalidate(tasksByGoalProvider(widget.goalId));
  }

  Future<void> _createAndLink() async {
    final result = await showPlannerItemDialog(
      context,
      dialogTitle: AppLocalizations.of(context)!.plannerAddTask,
      initialDueDate: DateTime.now(),
    );
    if (result == null || !mounted) return;
    final (
      title,
      dueDate,
      startTimeMinutes,
      endTimeMinutes,
      notes,
      workoutId,
      tags,
      recurrence,
      carryOver,
    ) = result;
    final task = newTask(
      day: dueDate ?? DateTime.now(),
      title: title,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      notes: notes,
      workoutId: workoutId,
      tags: tags,
      recurrence: recurrence,
      carryOver: carryOver,
    );
    final repo = ref.read(taskRepositoryProvider);
    await repo.insert(task);
    // A recurring task stores one anchor (seriesId == its own id).
    if (recurrence != null) {
      await repo.update(task.copyWith(seriesId: task.id));
    }
    await ref
        .read(linksRepositoryProvider)
        .linkTaskGoal(task.id, widget.goalId);
    if (!mounted) return;
    ref.invalidate(dayEntriesProvider(task.day));
    ref.invalidate(tasksByGoalProvider(widget.goalId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksByGoalProvider(widget.goalId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalsRelatedTasks,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        tasksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(l10n.errorWithMessage('$e')),
          data: (tasks) => tasks.isEmpty
              ? Text(
                  l10n.goalsNoLinkedTasks,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final (:item, label: _) in tasks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          item.done
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: item.done
                              ? TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.outline,
                                )
                              : null,
                        ),
                        trailing: IconButton(
                          tooltip: l10n.experimentUnlinkTask,
                          icon: const Icon(Icons.link_off, size: 20),
                          onPressed: () => _unlink(item.id),
                        ),
                      ),
                  ],
                ),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_link, size: 18),
              label: Text(l10n.experimentLinkTask),
              onPressed: _linkExisting,
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.plannerAddTask),
              onPressed: _createAndLink,
            ),
          ],
        ),
      ],
    );
  }
}

/// Searchable sheet listing planner tasks; tapping a result pops with the
/// task id to link.
final class _TaskPickerSheet extends ConsumerStatefulWidget {
  final String excludeGoalId;

  const _TaskPickerSheet({required this.excludeGoalId});

  @override
  ConsumerState<_TaskPickerSheet> createState() => _TaskPickerSheetState();
}

final class _TaskPickerSheetState extends ConsumerState<_TaskPickerSheet> {
  final _controller = TextEditingController();
  List<Task>? _results;
  Set<String> _linkedIds = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final results = await ref
        .read(taskRepositoryProvider)
        .searchTasks(_controller.text);
    final linked = await ref
        .read(linksRepositoryProvider)
        .tasksForGoal(widget.excludeGoalId);
    if (!mounted) return;
    setState(() {
      _results = results;
      _linkedIds = {for (final t in linked) t.item.id};
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.experimentSearchTasksHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  onChanged: (_) => _search(),
                ),
              ),
              Expanded(
                child: _results == null
                    ? const Center(child: CircularProgressIndicator())
                    : _results!.isEmpty
                    ? Center(child: Text(l10n.goalsNoLinkedTasks))
                    : ListView(
                        children: [
                          for (final task in _results!)
                            ListTile(
                              leading: Icon(
                                _linkedIds.contains(task.id)
                                    ? Icons.link
                                    : Icons.add_link,
                                size: 20,
                              ),
                              title: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context).pop(task.id),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pending task-link intents collected in the create form, committed to the
/// database only after the goal is first saved (it needs an id).
sealed class _TaskLink {
  const _TaskLink();
}

final class _TaskLinkExisting extends _TaskLink {
  final Task task;
  const _TaskLinkExisting(this.task);
}

final class _TaskLinkCreate extends _TaskLink {
  final (
    String,
    DateTime?,
    int?,
    int?,
    String?,
    String?,
    List<String>?,
    PlannerRecurrence?,
    bool,
  ) result;
  const _TaskLinkCreate(this.result);
}

/// Create-mode "Related tasks" editor: links existing tasks or stages new
/// ones locally, committed when the goal is saved.
final class _PendingTasksSection extends ConsumerWidget {
  final List<_TaskLink> links;
  final ValueChanged<List<_TaskLink>> onChanged;
  final String excludeGoalId;

  const _PendingTasksSection({
    required this.links,
    required this.onChanged,
    required this.excludeGoalId,
  });

  Future<void> _linkExisting(BuildContext context, WidgetRef ref) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _TaskPickerSheet(excludeGoalId: excludeGoalId),
    );
    if (id == null || !context.mounted) return;
    final task = await ref.read(taskRepositoryProvider).getById(id);
    if (task == null || !context.mounted) return;
    onChanged([...links, _TaskLinkExisting(task)]);
  }

  Future<void> _createNew(BuildContext context, WidgetRef ref) async {
    final result = await showPlannerItemDialog(
      context,
      dialogTitle: AppLocalizations.of(context)!.plannerAddTask,
      initialDueDate: DateTime.now(),
    );
    if (result == null || !context.mounted) return;
    onChanged([...links, _TaskLinkCreate(result)]);
  }

  String _title(_TaskLink link) => switch (link) {
    _TaskLinkExisting(:final task) => task.title,
    _TaskLinkCreate(:final result) => result.$1,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.goalsRelatedTasks,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        links.isEmpty
            ? Text(
                l10n.goalsNoLinkedTasks,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Column(
                children: [
                  for (final link in links)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        Icons.radio_button_unchecked,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        _title(link),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () =>
                            onChanged(links.where((l) => l != link).toList()),
                      ),
                    ),
                ],
              ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_link, size: 18),
              label: Text(l10n.experimentLinkTask),
              onPressed: () => _linkExisting(context, ref),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.plannerAddTask),
              onPressed: () => _createNew(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
