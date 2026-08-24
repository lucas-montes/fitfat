import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../ui/tokens.dart';
import '../providers/goals.dart';

/// Create / edit a [Goal]: title, description, priority tags, date range,
/// lifecycle status, and an optional measurable target. Saving inserts a new
/// row or updates in place.
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
  final _unitCtrl = TextEditingController();

  late DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  GoalStatus _status = GoalStatus.planned;
  GoalTargetType _targetType = GoalTargetType.none;
  List<String> _tags = [];
  bool _saving = false;
  bool _loaded = false;
  DateTime _createdAt = DateTime.now();

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
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final goal = await ref
        .read(goalRepositoryProvider)
        .getGoalById(widget.goalId!);
    if (goal == null || !mounted) return;
    setState(() {
      _titleCtrl.text = goal.title;
      _descriptionCtrl.text = goal.description ?? '';
      _startDate = goal.startDate;
      _endDate = goal.endDate;
      _status = goal.status;
      _targetType = goal.targetType;
      if (goal.targetValue != null) {
        _targetCtrl.text = _formatNumber(goal.targetValue!);
      }
      _unitCtrl.text = goal.unit ?? '';
      _tags = List<String>.from(goal.tags ?? const []);
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await ref
          .read(goalRepositoryProvider)
          .upsertGoal(
            Goal(
              id: _isEditing ? widget.goalId! : const Uuid().v7(),
              title: _titleCtrl.text.trim(),
              description: _descriptionCtrl.text.trim().isEmpty
                  ? null
                  : _descriptionCtrl.text.trim(),
              tags: _tags.isEmpty ? null : _tags,
              startDate: _startDate,
              endDate: _endDate,
              status: _status,
              targetType: _targetType,
              targetValue: _targetType == GoalTargetType.numeric
                  ? target
                  : null,
              unit:
                  _targetType == GoalTargetType.numeric &&
                      _unitCtrl.text.trim().isNotEmpty
                  ? _unitCtrl.text.trim()
                  : null,
              createdAt: _createdAt,
              updatedAt: now,
            ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                  const SizedBox(height: FitFatTokens.spaceS),
                  DropdownButtonFormField<GoalStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: l10n.goalsFormStatusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final s in GoalStatus.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(switch (s) {
                            GoalStatus.planned => l10n.goalsStatusPlanned,
                            GoalStatus.active => l10n.goalsStatusActive,
                            GoalStatus.done => l10n.goalsStatusDone,
                            GoalStatus.aborted => l10n.goalsStatusAborted,
                          }),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: FitFatTokens.spaceM),
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
                  if (_targetType == GoalTargetType.numeric) ...[
                    const SizedBox(height: FitFatTokens.spaceM),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
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
