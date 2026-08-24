import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/experiment.dart';
import '../../planner/providers/planner.dart';
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
  Set<ExperimentCategory> _categories = {
    ExperimentCategory.workout,
    ExperimentCategory.diet,
  };
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;
  bool _loaded = false;
  DateTime _createdAt = DateTime.now();

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
        .read(plannerRepositoryProvider)
        .getExperimentById(widget.experimentId!);
    if (experiment == null || !mounted) return;
    setState(() {
      _nameCtrl.text = experiment.name;
      _purposeCtrl.text = experiment.purpose ?? '';
      _startDate = experiment.startDate;
      _endDate = experiment.endDate ?? _endDate;
      _status = experiment.status;
      _categories = experiment.categories.toSet();
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
    final repo = ref.read(plannerRepositoryProvider);
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
      reminderEnabled: _reminderEnabled,
      reminderTimeMinutes: _reminderTime.hour * 60 + _reminderTime.minute,
      createdAt: _createdAt,
    );

    try {
      await repo.upsertExperiment(experiment);
      await scheduler.scheduleForExperiment(
        experiment,
        title: l10n.experimentReminderTitle(experiment.name),
        body: l10n.experimentReminderBody,
      );
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

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.experimentFormDeleteConfirmTitle),
        content: Text(l10n.experimentFormDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(experimentReminderSchedulerProvider)
          .cancelForExperiment(widget.experimentId!);
      await ref
          .read(plannerRepositoryProvider)
          .deleteExperiment(widget.experimentId!);
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
                  const SizedBox(height: FitFatTokens.spaceM),
                  DropdownButtonFormField<ExperimentStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: l10n.experimentFormStatusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: ExperimentStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(experimentStatusLabel(s, l10n)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
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
