import 'package:flutter/material.dart';

import '../../../models/workout.dart' as domain;

/// A swipeable weekly calendar strip showing 7 days with planned workout dots.
class CalendarStrip extends StatefulWidget {
  const CalendarStrip({
    super.key,
    required this.weekStart,
    required this.selectedDay,
    required this.plannedWorkouts,
    required this.onWeekChanged,
    required this.onDaySelected,
  });

  /// Monday of the currently displayed week.
  final DateTime weekStart;

  /// The currently selected day.
  final DateTime selectedDay;

  /// Planned workouts for the displayed week (used to show dot indicators).
  final List<domain.PlannedWorkout> plannedWorkouts;

  /// Called when the user swipes to a new week.
  final ValueChanged<DateTime> onWeekChanged;

  /// Called when the user taps a day.
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  late PageController _pageController;
  late int _currentPage;

  // Reference Monday used to anchor page indices.
  static final _refMonday = DateTime.utc(2026, 1, 5); // arbitrary Monday

  @override
  void initState() {
    super.initState();
    _currentPage = _pageIndexForDate(widget.weekStart);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageIndexForDate(DateTime date) {
    final diff = date.difference(_refMonday).inDays;
    return diff ~/ 7;
  }

  DateTime _dateForPageIndex(int index) {
    return _refMonday.add(Duration(days: index * 7));
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    widget.onWeekChanged(_dateForPageIndex(page));
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final theme = Theme.of(context);

    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, pageIndex) {
          final weekStart = _dateForPageIndex(pageIndex);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final isToday = _isSameDay(day, DateTime.now());
                final isSelected = _isSameDay(day, widget.selectedDay);
                final hasPlanned = widget.plannedWorkouts.any(
                  (pw) => _isSameDay(pw.scheduledDate, day),
                );

                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onDaySelected(day),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (hasPlanned)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
