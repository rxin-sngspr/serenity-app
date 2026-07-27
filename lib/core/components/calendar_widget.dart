import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Inline compact calendar matching the visualizer .calendar-widget spec.
///
/// Compact month grid with heart dots on entry days.
class CalendarWidget extends StatefulWidget {
  final Set<String> datesWithEntries;
  final ValueChanged<DateTime>? onDayTapped;
  final DateTime? selectedDate;

  const CalendarWidget({
    super.key,
    required this.datesWithEntries,
    this.onDayTapped,
    this.selectedDate,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _prevMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth = lastDay.day;

    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Responsive calendar grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / 7;

              return Column(
                children: [
                  // Weekday headers
                  Row(
                    children: weekdays.map((d) {
                      return SizedBox(
                        width: cellSize,
                        child: Center(
                          child: Text(
                            d,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),

                  // Day grid
                  ...List.generate((startWeekday + daysInMonth + 6) ~/ 7, (rowIndex) {
                    return Row(
                      children: List.generate(7, (colIndex) {
                        final dayIndex = rowIndex * 7 + colIndex - startWeekday + 1;
                        if (dayIndex < 1 || dayIndex > daysInMonth) {
                          return SizedBox(width: cellSize, height: cellSize);
                        }

                        final date = DateTime(
                          _currentMonth.year,
                          _currentMonth.month,
                          dayIndex,
                        );
                        final dateKey = '${date.year}-${date.month}-${date.day}';
                        final hasEntries = widget.datesWithEntries.contains(dateKey);
                        final isToday = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final isTapped = widget.selectedDate != null &&
                            widget.selectedDate!.year == date.year &&
                            widget.selectedDate!.month == date.month &&
                            widget.selectedDate!.day == date.day;

                        return SizedBox(
                          width: cellSize,
                          height: cellSize,
                          child: GestureDetector(
                            onTap: () => widget.onDayTapped?.call(date),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isTapped
                                    ? theme.colorScheme.primary
                                    : isToday
                                        ? theme.colorScheme.secondary.withAlpha(51)
                                        : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayIndex',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight:
                                          hasEntries ? FontWeight.w600 : FontWeight.w400,
                                      color: isTapped
                                          ? Colors.white
                                          : hasEntries
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (hasEntries)
                                    Text(
                                      '\u2665',
                                      style: TextStyle(
                                        fontSize: 5,
                                        color: isTapped
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                        height: 1,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
