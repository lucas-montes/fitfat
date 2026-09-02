import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/experiment.dart';
import '../../models/planner_recurrence.dart';
import '../../models/task.dart';
import '../../notes/providers/notes.dart';
import '../../tags/providers/tags.dart';
import '../../planner/providers/planner.dart'
    show
        linksRepositoryProvider,
        dayEntriesProvider,
        taskRepositoryProvider;
import '../../planner/repositories/task_repository.dart';
import '../../planner/screens/planner_item_form.dart';
import '../../goals/providers/goals.dart';
import '../providers/experiments.dart';
import '../providers/experiments_repository.dart';
import '../../settings/providers/settings.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../ui/cascade_delete_dialog.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../notifications/experiment_reminder.dart';
import '../ui/experiment_labels.dart';

/// Create / edit a self-tracking experiment: name, hypothesis, date range,
/// lifecycle status, linked categories, and the daily check-in reminder.
/// Saving either inserts a new row or updates in place; deleting (edit mode)
/// also removes the experiment's check-ins and cancels any scheduled reminder.
final class ExperimentFormScreen extends ConsumerStatefulWidget {
  final String? experimentId;

  const ExperimentFormScreen({super.key, this.experimentId});

  @override
  ConsumerState<ExperimentFormScreen> createState() =>
      _ExperimentFormScreenState();
}

final class _ExperimentFormScreenState
    extends ConsumerState<ExperimentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();

  /// Required since the v24 merge: every experiment has a concrete end date.
  /// New experiments default to one week out.
  late DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  ExperimentStatus _status = ExperimentStatus.planned;
  Set<ExperimentCategory> _categories = {};
  List<String> _tags = [];
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;
  bool _loaded = false;
  DateTime _createdAt = DateTime.now();
  List<_TaskLink> _taskLinks = [];

  bool get _isEditing => widget.experimentId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final experiment = await ref
        .read(experimentRepositoryProvider)
        .getById(widget.experimentId!);
    if (experiment == null || !mounted) return;
    setState(() {
      _nameCtrl.text = experiment.name;
      _purposeCtrl.text = experiment.purpose ?? '';
      _startDate = experiment.startDate;
      _endDate = experiment.endDate ?? _endDate;
      _status = experiment.status;
      _categories = experiment.categories.toSet();
      _tags = List<String>.from(experiment.tags ?? const []);
      _reminderEnabled = experiment.reminderEnabled;
      _reminderTime = TimeOfDay(
        hour: experiment.reminderTimeMinutes ~/ 60,
        minute: experiment.reminderTimeMinutes % 60,
      );
      _createdAt = experiment.createdAt;
      _loaded = true;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: DateTime(2000),
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
    // The end date is required since experiments fold into the planner (v24).
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.experimentFormInvalidDates)));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(experimentRepositoryProvider);
    final scheduler = ref.read(experimentReminderSchedulerProvider);

    final experiment = Experiment(
      id: _isEditing ? widget.experimentId! : const Uuid().v7(),
      name: _nameCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim().isEmpty
          ? null
          : _purposeCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      categories: _categories.toList(),
      tags: _tags.isEmpty ? null : _tags,
      reminderEnabled: _reminderEnabled,
      reminderTimeMinutes: _reminderTime.hour * 60 + _reminderTime.minute,
      createdAt: _createdAt,
    );

    try {
      await repo.upsert(experiment);
      await scheduler.scheduleForExperiment(
        experiment,
        title: l10n.experimentReminderTitle(experiment.name),
        body: l10n.experimentReminderBody,
      );
      if (!mounted) return;
      if (!_isEditing) {
        // Commit any tasks staged in the create form, then return to the
        // Initiatives list (refreshed via invalidation below).
        final links = ref.read(linksRepositoryProvider);
        final taskRepo = ref.read(taskRepositoryProvider);
        for (final link in _taskLinks) {
          if (link is _TaskLinkExisting) {
            await links.linkTaskExperiment(link.task.id, experiment.id);
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
            await links.linkTaskExperiment(task.id, experiment.id);
            ref.invalidate(dayEntriesProvider(task.day));
          }
        }
        ref.invalidate(experimentLinkedTasksProvider(experiment.id));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ref.invalidate(experimentListProvider);
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

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final behavior = ref.read(settingsProvider).cascadeDeleteBehavior;
    final links = await ref
        .read(linksRepositoryProvider)
        .tasksForExperiment(widget.experimentId!);
    final choice = await showCascadeDeleteDialog(
      context,
      title: l10n.experimentFormDeleteConfirmTitle,
      behavior: behavior,
      linkedTaskCount: links.length,
    );
    if (choice == null || choice == CascadeChoice.cancel) return;
    final cascade = choice == CascadeChoice.cascade;

    setState(() => _saving = true);
    try {
      await ref
          .read(experimentReminderSchedulerProvider)
          .cancelForExperiment(widget.experimentId!);
      await ref
          .read(experimentRepositoryProvider)
          .delete(widget.experimentId!, cascadeTasks: cascade);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.experimentFormTitleEdit
              : l10n.experimentFormTitleNew,
        ),
      ),
      body: _isEditing && !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(FitFatTokens.spaceL),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.experimentFormNameLabel,
                      hintText: l10n.experimentFormNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.experimentFormNameRequired
                        : null,
                  ),
                  const SizedBox(height: FitFatTokens.spaceM),
                  TextFormField(
                    controller: _purposeCtrl,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.experimentFormPurposeLabel,
                      hintText: l10n.experimentFormPurposeHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceM),
                  _DateTile(
                    label: l10n.experimentFormStartLabel,
                    value: _startDate,
                    onTap: _pickStartDate,
                  ),
                  _DateTile(
                    label: l10n.experimentFormEndLabel,
                    value: _endDate,
                    onTap: _pickEndDate,
                  ),
                  const SizedBox(height: FitFatTokens.spaceL),
                  Text(
                    l10n.experimentFormCategoriesLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceS),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in ExperimentCategory.values)
                        FilterChip(
                          avatar: Icon(
                            experimentCategoryIcon(category),
                            size: 18,
                            color: scheme.primary,
                          ),
                          label: Text(experimentCategoryLabel(category, l10n)),
                          selected: _categories.contains(category),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _categories.add(category);
                            } else {
                              _categories.remove(category);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: FitFatTokens.spaceL),
                  Text(
                    l10n.plannerTagsLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: FitFatTokens.spaceS),
                  TagPicker(
                    tags: _tags,
                    onChanged: (tags) => setState(() => _tags = tags),
                  ),
                  const SizedBox(height: FitFatTokens.spaceL),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.experimentFormReminderLabel),
                    subtitle: Text(l10n.experimentFormReminderSubtitle),
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                  ),
                  if (_reminderEnabled)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.experimentFormReminderTimeLabel),
                      subtitle: Text(
                        DateFormats.formatTime(context, _reminderTime),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickReminderTime,
                    ),
                  if (_isEditing) ...[
                    const SizedBox(height: FitFatTokens.spaceL),
                    _RelatedGoalsSection(experimentId: widget.experimentId!),
                    const SizedBox(height: FitFatTokens.spaceL),
                    _RelatedTasksSection(experimentId: widget.experimentId!),
                    const SizedBox(height: FitFatTokens.spaceL),
                    _RelatedNotesSection(experimentId: widget.experimentId!),
                  ] else ...[
                    const SizedBox(height: FitFatTokens.spaceL),
                    _PendingTasksSection(
                      links: _taskLinks,
                      onChanged: (l) => setState(() => _taskLinks = l),
                      excludeExperimentId: '',
                    ),
                  ],
                  const SizedBox(height: FitFatTokens.spaceL),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.commonSave),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: FitFatTokens.spaceS),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.experimentFormDelete),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                    ),
                  ],
                ],
        ),
      ),
    );
  }
}

/// Related tasks for an existing experiment: linked tasks with unlink
/// actions, plus "link existing" (search sheet) and "new task" (planner form)
/// flows. Links live in the `task_experiments` junction table.
final class _RelatedTasksSection extends ConsumerStatefulWidget {
  final String experimentId;

  const _RelatedTasksSection({required this.experimentId});

  @override
  ConsumerState<_RelatedTasksSection> createState() =>
      _RelatedTasksSectionState();
}

final class _RelatedTasksSectionState
    extends ConsumerState<_RelatedTasksSection> {
  Future<void> _unlink(String taskId) async {
    await ref
        .read(linksRepositoryProvider)
        .unlinkTaskExperiment(taskId, widget.experimentId);
    ref.invalidate(experimentLinkedTasksProvider(widget.experimentId));
  }

  Future<void> _linkExisting() async {
    final taskId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _TaskPickerSheet(excludeExperimentId: widget.experimentId),
    );
    if (taskId == null || !mounted) return;
    await ref
        .read(linksRepositoryProvider)
        .linkTaskExperiment(taskId, widget.experimentId);
    if (!mounted) return;
    ref.invalidate(experimentLinkedTasksProvider(widget.experimentId));
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
    if (recurrence != null) {
      await repo.update(task.copyWith(seriesId: task.id));
    }
    await ref
        .read(linksRepositoryProvider)
        .linkTaskExperiment(task.id, widget.experimentId);
    if (!mounted) return;
    ref.invalidate(dayEntriesProvider(task.day));
    ref.invalidate(experimentLinkedTasksProvider(widget.experimentId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(
      experimentLinkedTasksProvider(widget.experimentId),
    );

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
  final String excludeExperimentId;

  const _TaskPickerSheet({required this.excludeExperimentId});

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
        .tasksForExperiment(widget.excludeExperimentId);
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

final class _DateTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(DateFormats.formatDate(context, value)),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }
}

/// Related goals for an existing experiment: `experiment_goals` links with
/// unlink actions plus a pick-from-list flow.
final class _RelatedGoalsSection extends ConsumerStatefulWidget {
  final String experimentId;

  const _RelatedGoalsSection({required this.experimentId});

  @override
  ConsumerState<_RelatedGoalsSection> createState() =>
      _RelatedGoalsSectionState();
}

final class _RelatedGoalsSectionState
    extends ConsumerState<_RelatedGoalsSection> {
  Future<void> _pickGoal() async {
    final goalId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _GoalPickerSheet(),
    );
    if (goalId == null || !mounted) return;
    await ref
        .read(linksRepositoryProvider)
        .linkExperimentGoal(widget.experimentId, goalId);
    if (!mounted) return;
    ref.invalidate(goalsByExperimentProvider(widget.experimentId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(
      goalsByExperimentProvider(widget.experimentId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.experimentsRelatedGoals,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        goalsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(l10n.errorWithMessage('$e')),
          data: (goals) => goals.isEmpty
              ? Text(
                  l10n.experimentsNoLinkedGoals,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final (:item, label: _) in goals)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          item.isActive ? Icons.flag : Icons.flag_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: l10n.unlinkGoal,
                          icon: const Icon(Icons.link_off, size: 20),
                          onPressed: () async {
                            await ref
                                .read(linksRepositoryProvider)
                                .unlinkExperimentGoal(
                                  widget.experimentId,
                                  item.id,
                                );
                            ref.invalidate(
                              goalsByExperimentProvider(widget.experimentId),
                            );
                          },
                        ),
                      ),
                  ],
                ),
        ),
        ActionChip(
          avatar: const Icon(Icons.add_link, size: 18),
          label: Text(l10n.linkGoal),
          onPressed: _pickGoal,
        ),
      ],
    );
  }
}

/// Related notes for an existing experiment: `experiment_notes` links with
/// unlink actions plus a pick-from-list flow.
final class _RelatedNotesSection extends ConsumerStatefulWidget {
  final String experimentId;

  const _RelatedNotesSection({required this.experimentId});

  @override
  ConsumerState<_RelatedNotesSection> createState() =>
      _RelatedNotesSectionState();
}

final class _RelatedNotesSectionState
    extends ConsumerState<_RelatedNotesSection> {
  Future<void> _pickNote() async {
    final noteId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _NotePickerSheet(),
    );
    if (noteId == null || !mounted) return;
    await ref
        .read(linksRepositoryProvider)
        .linkExperimentNote(widget.experimentId, noteId);
    if (!mounted) return;
    ref.invalidate(notesByExperimentProvider(widget.experimentId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notesAsync = ref.watch(
      notesByExperimentProvider(widget.experimentId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.experimentsRelatedNotes,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        notesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(l10n.errorWithMessage('$e')),
          data: (notes) => notes.isEmpty
              ? Text(
                  l10n.experimentsNoLinkedNotes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final (:item, label: _) in notes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          Icons.sticky_note_2_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: l10n.unlinkNote,
                          icon: const Icon(Icons.link_off, size: 20),
                          onPressed: () async {
                            await ref
                                .read(linksRepositoryProvider)
                                .unlinkExperimentNote(
                                  widget.experimentId,
                                  item.id,
                                );
                            ref.invalidate(
                              notesByExperimentProvider(widget.experimentId),
                            );
                          },
                        ),
                      ),
                  ],
                ),
        ),
        ActionChip(
          avatar: const Icon(Icons.add_link, size: 18),
          label: Text(l10n.linkNote),
          onPressed: _pickNote,
        ),
      ],
    );
  }
}

/// Bottom sheet listing all goals; tapping one pops with its id.
final class _GoalPickerSheet extends ConsumerWidget {
  const _GoalPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goalsAsync = ref.watch(goalListProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
          data: (goals) => goals.isEmpty
              ? Center(child: Text(l10n.experimentsNoLinkedGoals))
              : ListView(
                  children: [
                    for (final goal in goals)
                      ListTile(
                        leading: Icon(
                          goal.isActive ? Icons.flag : Icons.flag_outlined,
                          size: 20,
                        ),
                        title: Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(goal.id),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing all notes (newest first); tapping one pops with its id.
final class _NotePickerSheet extends ConsumerWidget {
  const _NotePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notesAsync = ref.watch(noteListProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: notesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
          data: (notes) => notes.isEmpty
              ? Center(child: Text(l10n.experimentsNoLinkedNotes))
              : ListView(
                  children: [
                    for (final note in notes)
                      ListTile(
                        leading: const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 20,
                        ),
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(note.id),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Pending task-link intents collected in the create form, committed to the
/// database only after the experiment is first saved (it needs an id).
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
/// ones locally, committed when the experiment is saved.
final class _PendingTasksSection extends ConsumerWidget {
  final List<_TaskLink> links;
  final ValueChanged<List<_TaskLink>> onChanged;
  final String excludeExperimentId;

  const _PendingTasksSection({
    required this.links,
    required this.onChanged,
    required this.excludeExperimentId,
  });

  Future<void> _linkExisting(BuildContext context, WidgetRef ref) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _TaskPickerSheet(excludeExperimentId: excludeExperimentId),
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
