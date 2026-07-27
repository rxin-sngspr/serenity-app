import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _tappedDate;

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
    final datesAsync = ref.watch(calendarDatesProvider(_currentMonth));
    final today = DateTime.now();

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Build calendar grid
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth = lastDay.day;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurface),
          onPressed: _prevMonth,
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurface),
            onPressed: _nextMonth,
          ),
        ],
      ),
      body: datesAsync.when(
        data: (dates) {
          final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

          return Column(
            children: [
              // Weekday headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: weekdays.map((d) {
                    return Expanded(
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
              ),
              // Day grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (context, index) {
                      final day = index - startWeekday + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const SizedBox.shrink();
                      }

                      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                      final dateKey =
                          '${date.year}-${date.month}-${date.day}';
                      final hasEntries = dates.contains(dateKey);
                      final isToday = date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day;

                      return GestureDetector(
                        onTap: hasEntries
                            ? () {
                                setState(() => _tappedDate = date);
                                // Brief highlight animation then pop
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  if (mounted) context.pop(date);
                                });
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _tappedDate != null &&
                                    _tappedDate!.year == date.year &&
                                    _tappedDate!.month == date.month &&
                                    _tappedDate!.day == date.day
                                ? theme.colorScheme.primary
                                : isToday
                                    ? theme.colorScheme.primaryContainer.withAlpha(153)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                  color: _tappedDate != null &&
                                          _tappedDate!.year == date.year &&
                                          _tappedDate!.month == date.month &&
                                          _tappedDate!.day == date.day
                                      ? Colors.white
                                      : isToday
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (hasEntries)
                                Text(
                                  '\u2665',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _tappedDate != null &&
                                            _tappedDate!.year == date.year &&
                                            _tappedDate!.month == date.month &&
                                            _tappedDate!.day == date.day
                                        ? Colors.white
                                        : theme.colorScheme.primary,
                                    height: 1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
