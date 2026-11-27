import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// A month or a custom range (end inclusive); both null = all time.
@immutable
final class DateFilter {
  const DateFilter({this.month, this.range});

  static const all = DateFilter();

  /// First day of the selected month.
  final DateTime? month;
  final DateTimeRange? range;

  bool get isAll => month == null && range == null;

  /// Half-open window `[from, until)`; nulls mean unbounded.
  ({DateTime? from, DateTime? until}) get window {
    if (range != null) {
      return (
        from: range!.start,
        until: range!.end.add(const Duration(days: 1)),
      );
    }
    if (month != null) {
      return (from: month, until: DateTime(month!.year, month!.month + 1));
    }
    return (from: null, until: null);
  }

  bool contains(DateTime t) {
    final w = window;
    return (w.from == null || !t.isBefore(w.from!)) &&
        (w.until == null || t.isBefore(w.until!));
  }
}

/// "All", one chip per month in [months] (newest first) and "Range", which
/// opens quick ranges plus the date-range picker. Shared by the workout and
/// meal histories.
class DateFilterChips extends StatelessWidget {
  const DateFilterChips({
    super.key,
    required this.months,
    required this.value,
    required this.onChanged,
    required this.earliest,
  });

  final List<DateTime> months;
  final DateFilter value;
  final ValueChanged<DateFilter> onChanged;

  /// Oldest day the range picker allows.
  final DateTime earliest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final thisYear = DateTime.now().year;
    String monthLabel(DateTime m) => m.year == thisYear
        ? DateFormat.MMM(locale).format(m)
        : DateFormat.yMMM(locale).format(m);
    final range = value.range;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL),
        children: [
          for (final chip in [
            ChoiceChip(
              label: Text(l10n.trainingAllTime),
              selected: value.isAll,
              onSelected: (_) => onChanged(DateFilter.all),
            ),
            for (final m in months)
              ChoiceChip(
                label: Text(monthLabel(m)),
                selected: value.month == m && range == null,
                onSelected: (_) => onChanged(DateFilter(month: m)),
              ),
            ChoiceChip(
              avatar: const Icon(Icons.date_range, size: 16),
              label: Text(
                range == null
                    ? l10n.trainingRange
                    : '${DateFormat.MMMd(locale).format(range.start)} – '
                          '${DateFormat.MMMd(locale).format(range.end)}',
              ),
              selected: range != null,
              onSelected: (_) async {
                final picked = await pickDateRange(
                  context,
                  earliest: earliest,
                  current: range,
                );
                if (picked != null) onChanged(DateFilter(range: picked));
              },
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(right: FitFatTokens.spaceS),
              child: chip,
            ),
        ],
      ),
    );
  }
}

/// Quick ranges (7 / 30 days, 3 months, this year) and "Pick dates".
Future<DateTimeRange?> pickDateRange(
  BuildContext context, {
  required DateTime earliest,
  DateTimeRange? current,
}) {
  final l10n = AppLocalizations.of(context)!;
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  DateTimeRange quick(int days) => DateTimeRange(
    start: day.subtract(Duration(days: days - 1)),
    end: day,
  );
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    builder: (ctx) => SafeArea(
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
            Text(
              l10n.trainingRange,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            Wrap(
              spacing: FitFatTokens.spaceS,
              runSpacing: FitFatTokens.spaceS,
              children: [
                for (final (label, range) in [
                  (l10n.trainingLastDays(7), quick(7)),
                  (l10n.trainingLastDays(30), quick(30)),
                  (l10n.trainingLastMonths(3), quick(91)),
                  (
                    l10n.trainingThisYear,
                    DateTimeRange(start: DateTime(day.year), end: day),
                  ),
                ])
                  ActionChip(
                    label: Text(label),
                    onPressed: () => Navigator.of(ctx).pop(range),
                  ),
              ],
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(l10n.trainingPickDates),
              onPressed: () async {
                final first = DateTime(
                  earliest.year,
                  earliest.month,
                  earliest.day,
                );
                final r = await showDateRangePicker(
                  context: ctx,
                  firstDate: first.isAfter(day) ? day : first,
                  lastDate: day,
                  initialDateRange: current,
                );
                if (r != null && ctx.mounted) Navigator.of(ctx).pop(r);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
