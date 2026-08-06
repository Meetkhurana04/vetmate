import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vetmate/core/theme/app_theme.dart';

class CustomMonthlyCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<String> highlightedDates; // Format: YYYY-MM-DD
  final Color highlightColor;

  const CustomMonthlyCalendar({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.highlightedDates = const {},
    this.highlightColor = AppTheme.primaryColor,
  });

  @override
  State<CustomMonthlyCalendar> createState() => _CustomMonthlyCalendarState();
}

class _CustomMonthlyCalendarState extends State<CustomMonthlyCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // Weekday of 1st day (1 = Mon, 7 = Sun)
    final firstWeekday = firstDayOfMonth.weekday;
    final totalDays = lastDayOfMonth.day;

    // Number of padding days before the first day of month (assuming Monday start)
    final leadingPadding = firstWeekday - 1;

    final List<Widget> dayWidgets = [];

    // Weekday headers
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var day in weekDays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
        ),
      );
    }

    // Leading empty slots
    for (int i = 0; i < leadingPadding; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days of the month
    for (int dayNum = 1; dayNum <= totalDays; dayNum++) {
      final cellDate = DateTime(year, month, dayNum);
      final dateStr = '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';

      final isSelected = cellDate.year == widget.selectedDate.year &&
          cellDate.month == widget.selectedDate.month &&
          cellDate.day == widget.selectedDate.day;

      final isHighlighted = widget.highlightedDates.contains(dateStr);

      final isBeforeFirst = cellDate.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day));
      final isAfterLast = cellDate.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day));
      final isEnabled = !isBeforeFirst && !isAfterLast;

      dayWidgets.add(
        GestureDetector(
          onTap: isEnabled
              ? () {
                  widget.onDateSelected(cellDate);
                }
              : null,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppTheme.primaryColor
                  : isHighlighted
                      ? widget.highlightColor.withOpacity(0.12)
                      : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isHighlighted
                        ? widget.highlightColor.withOpacity(0.5)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    '$dayNum',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected || isHighlighted ? FontWeight.bold : FontWeight.normal,
                      color: !isEnabled
                          ? Colors.grey.shade300
                          : isSelected
                              ? Colors.white
                              : isHighlighted
                                  ? widget.highlightColor
                                  : AppTheme.textDark,
                    ),
                  ),
                ),
                if (isHighlighted && !isSelected)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.highlightColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textDark),
              ),
              Text(
                monthLabel,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayWidgets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              return dayWidgets[index];
            },
          ),
        ],
      ),
    );
  }
}
