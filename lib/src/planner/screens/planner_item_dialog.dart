import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../exercise/providers/workouts.dart';

/// Shows a bottom-sheet to enter (or edit) a planner task title, optional due
/// date, optional due time (only meaningful with a due date), optional note,
/// and optional linked workout. Returns a
/// `(title, dueDate, dueTimeMinutes, notes, workoutId)` record, or `null` if
/// cancelled. The trimmed title is guaranteed non-empty; an empty note becomes
/// null; the due time is minutes since midnight.
Future<(String, DateTime?, int?, String?, String?)?> showPlannerItemDialog(
  BuildContext context, {
  required String dialogTitle,
  String? initialTitle,
  DateTime? initialDueDate,
  int? initialDueTimeMinutes,
  String? initialNotes,
  String? initialWorkoutId,
}) {
  return showModalBottomSheet<(String, DateTime?, int?, String?, String?)>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => _PlannerItemSheet(
      dialogTitle: dialogTitle,
      initialTitle: initialTitle,
      initialDueDate: initialDueDate,
      initialDueTimeMinutes: initialDueTimeMinutes,
      initialNotes: initialNotes,
      initialWorkoutId: initialWorkoutId,
    ),
  );
}

final class _PlannerItemSheet extends ConsumerStatefulWidget {
  final String dialogTitle;
  final String? initialTitle;
  final DateTime? initialDueDate;
  final int? initialDueTimeMinutes;
  final String? initialNotes;
  final String? initialWorkoutId;

  const _PlannerItemSheet({
    required this.dialogTitle,
    this.initialTitle,
    this.initialDueDate,
    this.initialDueTimeMinutes,
    this.initialNotes,
    this.initialWorkoutId,
  });

  @override
  ConsumerState<_PlannerItemSheet> createState() => _PlannerItemSheetState();
}

final class _PlannerItemSheetState extends ConsumerState<_PlannerItemSheet> {
  late final TextEditingController _controller;
  late final TextEditingController _notesController;
  late DateTime? _dueDate;
  late int? _dueTimeMinutes;
  String? _errorText;
  String? _selectedWorkoutId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _dueDate = widget.initialDueDate;
    _dueTimeMinutes = widget.initialDueTimeMinutes;
    _selectedWorkoutId = widget.initialWorkoutId;
  }

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = l10n.plannerTaskRequired);
      return;
    }
    final notes = _notesController.text.trim();
    Navigator.of(context).pop((
      title,
      _dueDate,
      _dueTimeMinutes,
      notes.isEmpty ? null : notes,
      _selectedWorkoutId,
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

  Future<void> _pickDueTime() async {
    final initial = _dueTimeMinutes == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: _dueTimeMinutes! ~/ 60,
            minute: _dueTimeMinutes! % 60,
          );
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null && mounted) {
      setState(() => _dueTimeMinutes = time.hour * 60 + time.minute);
    }
  }

  void _clearDueDate() => setState(() {
    _dueDate = null;
    _dueTimeMinutes = null;
  });

  void _clearDueTime() => setState(() => _dueTimeMinutes = null);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final isEdit = widget.initialTitle != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.dialogTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
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
                        border: const OutlineInputBorder(),
                        hintText: l10n.plannerTaskHint,
                      ),
                    ),
                  ),
                ],
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
                leading: const Icon(Icons.alarm_outlined),
                title: Text(
                  _dueTimeMinutes == null
                      ? l10n.plannerDueTimeNone
                      : materialL10n.formatTimeOfDay(
                          TimeOfDay(
                            hour: _dueTimeMinutes! ~/ 60,
                            minute: _dueTimeMinutes! % 60,
                          ),
                        ),
                ),
                enabled: _dueDate != null,
                trailing: _dueTimeMinutes != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.plannerDueTimeClear,
                        onPressed: _clearDueTime,
                      )
                    : null,
                onTap: _dueDate == null ? null : _pickDueTime,
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(isEdit ? l10n.commonSave : l10n.plannerAddTask),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
