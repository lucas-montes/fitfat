import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/planner_recurrence.dart';
import '../providers/planner.dart';

/// Opens the full-screen task editor (add or edit) as a pushed route and
/// resolves with a `(title, dueDate, startTimeMinutes, endTimeMinutes, notes,
/// workoutId, tags, recurrence)` record — or `null` if cancelled. The trimmed
/// title is guaranteed non-empty; an empty note or empty tag list becomes null.
/// The sheet-style drag-to-dismiss is gone: the screen has an explicit close X
/// and a Save action in the AppBar (always reachable, no scrolling).
Future<
  (
    String,
    DateTime?,
    int?,
    int?,
    String?,
    String?,
    List<String>?,
    PlannerRecurrence?,
  )?
>
showPlannerItemDialog(
  BuildContext context, {
  required String dialogTitle,
  String? initialTitle,
  DateTime? initialDueDate,
  int? initialStartTimeMinutes,
  int? initialEndTimeMinutes,
  String? initialNotes,
  String? initialWorkoutId,
  List<String>? initialTags,
  PlannerRecurrence? initialRecurrence,
}) {
  return Navigator.of(context).push<
    (
      String,
      DateTime?,
      int?,
      int?,
      String?,
      String?,
      List<String>?,
      PlannerRecurrence?,
    )
  >(
    MaterialPageRoute(
      builder: (_) => PlannerItemFormScreen(
        dialogTitle: dialogTitle,
        initialTitle: initialTitle,
        initialDueDate: initialDueDate,
        initialStartTimeMinutes: initialStartTimeMinutes,
        initialEndTimeMinutes: initialEndTimeMinutes,
        initialNotes: initialNotes,
        initialWorkoutId: initialWorkoutId,
        initialTags: initialTags,
        initialRecurrence: initialRecurrence,
      ),
    ),
  );
}

enum _EndsChoice { never, onDate, after }

final class PlannerItemFormScreen extends ConsumerStatefulWidget {
  final String dialogTitle;
  final String? initialTitle;
  final DateTime? initialDueDate;
  final int? initialStartTimeMinutes;
  final int? initialEndTimeMinutes;
  final String? initialNotes;
  final String? initialWorkoutId;
  final List<String>? initialTags;
  final PlannerRecurrence? initialRecurrence;

  const PlannerItemFormScreen({
    super.key,
    required this.dialogTitle,
    this.initialTitle,
    this.initialDueDate,
    this.initialStartTimeMinutes,
    this.initialEndTimeMinutes,
    this.initialNotes,
    this.initialWorkoutId,
    this.initialTags,
    this.initialRecurrence,
  });

  @override
  ConsumerState<PlannerItemFormScreen> createState() =>
      _PlannerItemFormScreenState();
}

final class _PlannerItemFormScreenState
    extends ConsumerState<PlannerItemFormScreen> {
  late final TextEditingController _controller;
  late final TextEditingController _notesController;
  late final TextEditingController _tagController;
  late final TextEditingController _intervalDaysController;
  late final TextEditingController _monthDayController;
  late final TextEditingController _countController;
  late DateTime? _dueDate;
  late int? _startTimeMinutes;
  late int? _endTimeMinutes;
  String? _errorText;
  String? _selectedWorkoutId;
  final List<String> _tags = [];
  List<String> _allTags = [];

  PlannerRecurrenceType? _repeatType;
  final Set<int> _weekdays = {};
  _EndsChoice _endsChoice = _EndsChoice.never;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _tagController = TextEditingController();
    _dueDate = widget.initialDueDate;
    _startTimeMinutes = widget.initialStartTimeMinutes;
    _endTimeMinutes = widget.initialEndTimeMinutes;
    _selectedWorkoutId = widget.initialWorkoutId;
    _tags.addAll(widget.initialTags ?? const []);
    _intervalDaysController = TextEditingController();
    _monthDayController = TextEditingController();
    _countController = TextEditingController();
    final r = widget.initialRecurrence;
    if (r != null) {
      _repeatType = r.type;
      _weekdays.addAll(r.weekdays ?? const {});
      if (r.intervalDays != null) {
        _intervalDaysController.text = r.intervalDays.toString();
      }
      if (r.monthDay != null) _monthDayController.text = r.monthDay.toString();
      if (r.count != null) _countController.text = r.count.toString();
      if (r.endDate != null) {
        _endsChoice = _EndsChoice.onDate;
        _endDate = r.endDate;
      } else if (r.count != null) {
        _endsChoice = _EndsChoice.after;
      } else {
        _endsChoice = _EndsChoice.never;
      }
    }
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final tags = await ref.read(plannerRepositoryProvider).distinctTags();
    if (mounted) setState(() => _allTags = tags);
  }

  List<String> get _suggestions =>
      _allTags.where((t) => !_tags.contains(t)).toList();

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _intervalDaysController.dispose();
    _monthDayController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _addTagFromField() {
    final tag = _tagController.text.trim();
    _tagController.clear();
    _addTag(tag);
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags.add(t));
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  PlannerRecurrence? _buildRecurrence() {
    final type = _repeatType;
    if (type == null) return null;
    if (type == PlannerRecurrenceType.weekly && _weekdays.isEmpty) return null;
    final intervalDays = type == PlannerRecurrenceType.interval
        ? int.tryParse(_intervalDaysController.text)
        : null;
    if (type == PlannerRecurrenceType.interval &&
        (intervalDays == null || intervalDays < 1)) {
      return null;
    }
    final monthDay = type == PlannerRecurrenceType.monthly
        ? int.tryParse(_monthDayController.text)
        : null;
    if (type == PlannerRecurrenceType.monthly &&
        (monthDay == null || monthDay < 1 || monthDay > 31)) {
      return null;
    }
    final count = _endsChoice == _EndsChoice.after
        ? int.tryParse(_countController.text)
        : null;
    return PlannerRecurrence(
      type: type,
      weekdays: type == PlannerRecurrenceType.weekly ? {..._weekdays} : null,
      intervalDays: intervalDays,
      monthDay: monthDay,
      endDate: _endsChoice == _EndsChoice.onDate ? _endDate : null,
      count: count,
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = l10n.plannerTaskRequired);
      return;
    }
    final recurrence = _buildRecurrence();
    if (_repeatType != null && recurrence == null) {
      setState(() => _errorText = l10n.plannerRepeatInvalid);
      return;
    }
    final notes = _notesController.text.trim();
    final tags = _tags.isEmpty ? null : List<String>.from(_tags);
    Navigator.of(context).pop((
      title,
      _dueDate,
      _startTimeMinutes,
      _endTimeMinutes,
      notes.isEmpty ? null : notes,
      _selectedWorkoutId,
      tags,
      recurrence,
    ));
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null && mounted) setState(() => _dueDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null && mounted) setState(() => _endDate = date);
  }

  Future<void> _pickStartTime() async {
    final initial = _startTimeMinutes == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: _startTimeMinutes! ~/ 60,
            minute: _startTimeMinutes! % 60,
          );
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null && mounted) {
      setState(() => _startTimeMinutes = time.hour * 60 + time.minute);
    }
  }

  Future<void> _pickEndTime() async {
    final initial = _endTimeMinutes == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: _endTimeMinutes! ~/ 60,
            minute: _endTimeMinutes! % 60,
          );
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null && mounted) {
      setState(() => _endTimeMinutes = time.hour * 60 + time.minute);
    }
  }

  void _clearDueDate() => setState(() {
    _dueDate = null;
  });

  void _clearStartTime() => setState(() => _startTimeMinutes = null);

  void _clearEndTime() => setState(() => _endTimeMinutes = null);

  Widget _buildWorkoutField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workoutsAsync = ref.watch(workoutListProvider);
    return workoutsAsync.when(
      loading: () => Text(l10n.plannerWorkoutHint),
      error: (_, _) => Text(l10n.plannerWorkoutHint),
      data: (workouts) => DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedWorkoutId,
          isExpanded: true,
          hint: Text(l10n.plannerWorkoutHint),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.plannerWorkoutNone),
            ),
            if (_selectedWorkoutId != null &&
                !workouts.any((w) => w.id == _selectedWorkoutId))
              DropdownMenuItem<String?>(
                value: _selectedWorkoutId,
                child: Text(l10n.plannerLinkedWorkout),
              ),
            for (final w in workouts)
              DropdownMenuItem<String?>(
                value: w.id,
                child: Text(
                  w.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedWorkoutId = value),
        ),
      ),
    );
  }

  Widget _buildRepeatField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final repeatOptions = <(PlannerRecurrenceType?, String)>[
      (null, l10n.plannerRepeatNone),
      (PlannerRecurrenceType.daily, l10n.plannerRepeatDaily),
      (PlannerRecurrenceType.weekly, l10n.plannerRepeatWeekly),
      (PlannerRecurrenceType.interval, l10n.plannerRepeatInterval),
      (PlannerRecurrenceType.monthly, l10n.plannerRepeatMonthly),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<PlannerRecurrenceType?>(
            value: _repeatType,
            isExpanded: true,
            items: [
              for (final (type, label) in repeatOptions)
                DropdownMenuItem<PlannerRecurrenceType?>(
                  value: type,
                  child: Text(label),
                ),
            ],
            onChanged: (value) => setState(() => _repeatType = value),
          ),
        ),
        if (_repeatType == PlannerRecurrenceType.weekly) ...[
          const SizedBox(height: 4),
          Text(l10n.plannerRepeatWeekdays),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var w = 1; w <= 7; w++)
                FilterChip(
                  label: Text(materialL10n.narrowWeekdays[w % 7]),
                  selected: _weekdays.contains(w),
                  onSelected: (selected) => setState(
                    () => selected ? _weekdays.add(w) : _weekdays.remove(w),
                  ),
                ),
            ],
          ),
        ],
        if (_repeatType == PlannerRecurrenceType.interval) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.plannerRepeatEvery),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _intervalDaysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Text(l10n.plannerRepeatDays),
            ],
          ),
        ],
        if (_repeatType == PlannerRecurrenceType.monthly) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _monthDayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.plannerRepeatMonthDay,
              isDense: true,
            ),
          ),
        ],
        if (_repeatType != null) ...[
          const SizedBox(height: 12),
          Text(l10n.plannerRepeatEnds),
          const SizedBox(height: 4),
          SegmentedButton<_EndsChoice>(
            segments: [
              ButtonSegment(
                value: _EndsChoice.never,
                label: Text(l10n.plannerRepeatEndsNever),
              ),
              ButtonSegment(
                value: _EndsChoice.onDate,
                label: Text(l10n.plannerRepeatEndsOnDate),
              ),
              ButtonSegment(
                value: _EndsChoice.after,
                label: Text(l10n.plannerRepeatEndsAfter),
              ),
            ],
            selected: {_endsChoice},
            onSelectionChanged: (s) => setState(() => _endsChoice = s.first),
          ),
          if (_endsChoice == _EndsChoice.onDate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _endDate == null
                    ? l10n.plannerRepeatEndsOnDate
                    : materialL10n.formatMediumDate(_endDate!),
              ),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _endDate = null),
                    )
                  : null,
              onTap: _pickEndDate,
            ),
          if (_endsChoice == _EndsChoice.after)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.plannerRepeatOccurrences),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final isEdit = widget.initialTitle != null;
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.dialogTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: _submit,
              child: Text(isEdit ? l10n.commonSave : l10n.plannerAddTask),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.plannerTaskLabel,
                hintText: l10n.plannerTaskHint,
                errorText: _errorText,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const Divider(height: 24),
          ExpansionTile(
            leading: const Icon(Icons.notes),
            title: Text(l10n.plannerNotesLabel),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.plannerTaskHint,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _tagController,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: l10n.plannerTagsLabel,
                    hintText: l10n.plannerTagsHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: l10n.plannerTagsAdd,
                      onPressed: _addTagFromField,
                    ),
                  ),
                  onSubmitted: (_) => _addTagFromField(),
                ),
                const SizedBox(height: 8),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _tags)
                        InputChip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (_suggestions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _suggestions)
                        ActionChip(
                          label: Text(tag),
                          onPressed: () => _addTag(tag),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat_outlined),
            title: Text(l10n.plannerRepeatLabel),
            subtitle: _repeatType == null
                ? null
                : _buildRepeatField(context),
            onTap: () => setState(
              () => _repeatType = _repeatType ?? PlannerRecurrenceType.daily,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(
              _dueDate == null
                  ? l10n.plannerDueDateNone
                  : materialL10n.formatMediumDate(_dueDate!),
            ),
            trailing: _dueDate != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.plannerDueDateClear,
                    onPressed: _clearDueDate,
                  )
                : null,
            onTap: _pickDueDate,
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(
              _startTimeMinutes == null
                  ? l10n.plannerStartTimeNone
                  : materialL10n.formatTimeOfDay(
                      TimeOfDay(
                        hour: _startTimeMinutes! ~/ 60,
                        minute: _startTimeMinutes! % 60,
                      ),
                    ),
            ),
            subtitle: Text(l10n.plannerStartTimeLabel),
            trailing: _startTimeMinutes != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.plannerStartTimeClear,
                    onPressed: _clearStartTime,
                  )
                    : null,
            onTap: _pickStartTime,
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(
              _endTimeMinutes == null
                  ? l10n.plannerEndTimeNone
                  : materialL10n.formatTimeOfDay(
                      TimeOfDay(
                        hour: _endTimeMinutes! ~/ 60,
                        minute: _endTimeMinutes! % 60,
                      ),
                    ),
            ),
            subtitle: Text(l10n.plannerEndTimeLabel),
            trailing: _endTimeMinutes != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.plannerEndTimeClear,
                    onPressed: _clearEndTime,
                  )
                    : null,
            onTap: _pickEndTime,
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.fitness_center, size: 24),
              const SizedBox(width: 16),
              Expanded(child: _buildWorkoutField(context)),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}