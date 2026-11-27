import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../models/planner_recurrence.dart';
import '../../ui/tokens.dart';

/// What the quick-add sheet produces for one task.
typedef QuickTask = ({
  String title,
  DateTime day,
  int? startMinutes,
  int? endMinutes,
  PlannerRecurrence? recurrence,
  String? goalId,
});

/// "More options" from the sheet, with the title typed so far.
final class QuickMoreOptions {
  QuickMoreOptions(this.title);
  final String title;
}

/// + on Today: a title field and chips for day, time, repeat and goal. Add
/// hands the task to [onAdd] and clears the field for the next one; More
/// options closes the sheet and returns the title for the full form.
Future<QuickMoreOptions?> showQuickAddSheet(
  BuildContext context, {
  required DateTime day,
  required List<Goal> goals,
  required Future<void> Function(QuickTask task) onAdd,
}) {
  return showModalBottomSheet<QuickMoreOptions>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _QuickAddBody(day: day, goals: goals, onAdd: onAdd),
    ),
  );
}

enum _Repeat { none, daily, weekly, monthly }

class _QuickAddBody extends StatefulWidget {
  const _QuickAddBody({
    required this.day,
    required this.goals,
    required this.onAdd,
  });

  final DateTime day;
  final List<Goal> goals;
  final Future<void> Function(QuickTask task) onAdd;

  @override
  State<_QuickAddBody> createState() => _QuickAddBodyState();
}

class _QuickAddBodyState extends State<_QuickAddBody> {
  final _title = TextEditingController();
  late DateTime _day = widget.day;
  TimeOfDay? _start;
  TimeOfDay? _end;
  _Repeat _repeat = _Repeat.none;
  Goal? _goal;
  int _added = 0;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  PlannerRecurrence? get _recurrence => switch (_repeat) {
    _Repeat.none => null,
    _Repeat.daily => const PlannerRecurrence(type: PlannerRecurrenceType.daily),
    _Repeat.weekly => PlannerRecurrence(
      type: PlannerRecurrenceType.weekly,
      weekdays: {_day.weekday},
    ),
    _Repeat.monthly => PlannerRecurrence(
      type: PlannerRecurrenceType.monthly,
      monthDay: _day.day,
    ),
  };

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    await widget.onAdd((
      title: title,
      day: _day,
      startMinutes: _start == null ? null : _start!.hour * 60 + _start!.minute,
      endMinutes: _end == null ? null : _end!.hour * 60 + _end!.minute,
      recurrence: _recurrence,
      goalId: _goal?.id,
    ));
    if (!mounted) return;
    setState(() {
      _added++;
      _title.clear();
      _start = null;
      _end = null;
      _repeat = _Repeat.none;
      _goal = null;
    });
  }

  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _day = d);
  }

  Future<void> _pickTime() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _start ?? TimeOfDay.now(),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime:
          _end ?? TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
      helpText: AppLocalizations.of(context)!.quickAddEndTime,
    );
    setState(() {
      _start = start;
      _end = end;
    });
  }

  Future<void> _pickRepeat() async {
    final l10n = AppLocalizations.of(context)!;
    final r = await showModalBottomSheet<_Repeat>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (v, label) in [
              (_Repeat.none, l10n.quickAddRepeatNone),
              (_Repeat.daily, l10n.quickAddRepeatDaily),
              (_Repeat.weekly, l10n.quickAddRepeatWeekly),
              (_Repeat.monthly, l10n.quickAddRepeatMonthly),
            ])
              ListTile(
                title: Text(label),
                trailing: v == _repeat ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(v),
              ),
          ],
        ),
      ),
    );
    if (r != null) setState(() => _repeat = r);
  }

  Future<void> _pickGoal() async {
    final l10n = AppLocalizations.of(context)!;
    final g = await showModalBottomSheet<Goal?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.quickAddNoGoal),
              onTap: () => Navigator.of(ctx).pop(null),
            ),
            for (final goal in widget.goals)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(goal.title),
                trailing: goal.id == _goal?.id ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(goal),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _goal = g);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mat = MaterialLocalizations.of(context);
    final today = DateTime.now();
    final isToday =
        _day.year == today.year &&
        _day.month == today.month &&
        _day.day == today.day;
    final dayLabel = isToday
        ? l10n.plannerToday
        : DateFormat.MMMEd(locale).format(_day);
    final timeLabel = _start == null
        ? l10n.quickAddTime
        : _end == null
        ? mat.formatTimeOfDay(_start!)
        : '${mat.formatTimeOfDay(_start!)}–${mat.formatTimeOfDay(_end!)}';
    final repeatLabel = switch (_repeat) {
      _Repeat.none => l10n.quickAddRepeat,
      _Repeat.daily => l10n.quickAddRepeatDaily,
      _Repeat.weekly => l10n.quickAddRepeatWeekly,
      _Repeat.monthly => l10n.quickAddRepeatMonthly,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFatTokens.spaceL,
          0,
          FitFatTokens.spaceL,
          FitFatTokens.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FitFatTokens.spaceM,
          children: [
            TextField(
              key: const ValueKey('quickAddTitle'),
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: _added == 0
                    ? l10n.quickAddHint
                    : l10n.quickAddAnother(_added),
              ),
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() {}),
            ),
            Wrap(
              spacing: FitFatTokens.spaceS,
              runSpacing: FitFatTokens.spaceXs,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event_outlined, size: 16),
                  label: Text(dayLabel),
                  onPressed: _pickDay,
                ),
                InputChip(
                  avatar: const Icon(Icons.schedule, size: 16),
                  label: Text(timeLabel),
                  selected: _start != null,
                  onPressed: _pickTime,
                  onDeleted: _start == null
                      ? null
                      : () => setState(() {
                          _start = null;
                          _end = null;
                        }),
                ),
                InputChip(
                  avatar: const Icon(Icons.repeat, size: 16),
                  label: Text(repeatLabel),
                  selected: _repeat != _Repeat.none,
                  onPressed: _pickRepeat,
                ),
                if (widget.goals.isNotEmpty)
                  InputChip(
                    avatar: const Icon(Icons.flag_outlined, size: 16),
                    label: Text(_goal?.title ?? l10n.quickAddGoal),
                    selected: _goal != null,
                    onPressed: _pickGoal,
                  ),
              ],
            ),
            Row(
              spacing: FitFatTokens.spaceS,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(QuickMoreOptions(_title.text.trim())),
                    child: Text(l10n.quickAddMore),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('quickAddSubmit'),
                    onPressed: _title.text.trim().isEmpty ? null : _submit,
                    child: Text(l10n.quickAddAdd),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
