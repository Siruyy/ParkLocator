import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/view/venue_detail_page.dart';

class BookForLaterPage extends StatefulWidget {
  const BookForLaterPage({required this.venue, super.key});

  final Venue venue;

  static Route<void> route({required Venue venue}) {
    return MaterialPageRoute<void>(
      builder: (_) => BookForLaterPage(venue: venue),
    );
  }

  @override
  State<BookForLaterPage> createState() => _BookForLaterPageState();
}

class _BookForLaterPageState extends State<BookForLaterPage> {
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime _focusedMonth = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _focusedMonth = DateTime(_startDate.year, _startDate.month);

    // Default to next full hour
    final now = TimeOfDay.now();
    _startTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    _endTime = TimeOfDay(hour: (now.hour + 3) % 24, minute: 0);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      if (_endDate != null) {
        // Reset range if both were selected
        _startDate = date;
        _endDate = null;
      } else {
        if (date.isBefore(_startDate)) {
          // If selected date is before start, make it the new start
          _startDate = date;
        } else if (isSameDay(date, _startDate)) {
          // If same day, do nothing (or toggle off if we wanted toggle behavior)
        } else {
          // Set end date
          _endDate = date;
        }
      }
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
    });
  }

  List<TimeOfDay> _generateTimeSlots() {
    final slots = <TimeOfDay>[];
    for (var i = 0; i < 24; i++) {
      slots.add(TimeOfDay(hour: i, minute: 0));
      slots.add(TimeOfDay(hour: i, minute: 30));
    }
    return slots;
  }

  double get _totalPrice {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endBaseDate = _endDate ?? _startDate;
    var endDateTime = DateTime(
      endBaseDate.year,
      endBaseDate.month,
      endBaseDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // If same day and end time is before start time, assume next day?
    // Or just invalid? For now, let's assume if end < start on same day, it's +24h (overnight)
    // But with range selection, we should respect the dates.
    if (_endDate == null && endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final durationInHours =
        endDateTime.difference(startDateTime).inMinutes / 60.0;
    // Ensure non-negative
    final effectiveDuration = durationInHours > 0 ? durationInHours : 0.0;

    return effectiveDuration * widget.venue.pricePerHour;
  }

  String get _durationString {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endBaseDate = _endDate ?? _startDate;
    var endDateTime = DateTime(
      endBaseDate.year,
      endBaseDate.month,
      endBaseDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (_endDate == null && endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final duration = endDateTime.difference(startDateTime);
    if (duration.isNegative) return 'Invalid Time';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days days');
    if (hours > 0) parts.add('$hours hrs');
    if (minutes > 0) parts.add('$minutes mins');

    if (parts.isEmpty) return '0 mins';
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF101922)
        : const Color(0xFFF6F7F8);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const primaryColor = Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Date & Time',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Venue Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[300],
                              image: widget.venue.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.venue.imageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.venue.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: subTextColor,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        '${widget.venue.address} • ₱${widget.venue.pricePerHour.toStringAsFixed(0)} reservation',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: subTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Selection Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Date',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                color: subTextColor,
                              ),
                              onPressed: () => _changeMonth(-1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM yyyy').format(_focusedMonth),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: textColor),
                              onPressed: () => _changeMonth(1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calendar Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: _buildCalendarGrid(
                        textColor,
                        subTextColor,
                        primaryColor,
                        isDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Select Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickSelectChip(
                            label: 'Today',
                            isSelected:
                                isSameDay(_startDate, DateTime.now()) &&
                                _endDate == null,
                            onTap: () => _onDateSelected(DateTime.now()),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _QuickSelectChip(
                            label: 'Tomorrow',
                            isSelected:
                                isSameDay(
                                  _startDate,
                                  DateTime.now().add(const Duration(days: 1)),
                                ) &&
                                _endDate == null,
                            onTap: () => _onDateSelected(
                              DateTime.now().add(const Duration(days: 1)),
                            ),
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _QuickSelectChip(
                            label: 'This Weekend',
                            isSelected:
                                false, // Logic for weekend is a bit more complex, skipping visual state for now
                            onTap: () {
                              // Find next Saturday
                              var date = DateTime.now();
                              while (date.weekday != DateTime.saturday) {
                                date = date.add(const Duration(days: 1));
                              }
                              _onDateSelected(date);
                            },
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Duration Selection
                    Text(
                      'Select Duration',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ARRIVE AFTER',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _TimeDropdown(
                                value: _startTime,
                                items: _generateTimeSlots(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _startTime = val);
                                  }
                                },
                                isDark: isDark,
                                textColor: textColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXIT BEFORE',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _TimeDropdown(
                                value: _endTime,
                                items: _generateTimeSlots(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _endTime = val);
                                  }
                                },
                                isDark: isDark,
                                textColor: textColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[900]!.withValues(alpha: 0.2)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.blue[900]!.withValues(alpha: 0.3)
                              : Colors.blue[100]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total duration: ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subTextColor,
                            ),
                          ),
                          Text(
                            _durationString,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Just some padding, footer is now separate
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Price',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subTextColor,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₱${_totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₱${(_totalPrice * 1.2).toStringAsFixed(0)}', // Fake original price
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Standard Rate',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Includes VAT & Fees',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final startDateTime = DateTime(
                          _startDate.year,
                          _startDate.month,
                          _startDate.day,
                          _startTime.hour,
                          _startTime.minute,
                        );

                        final endBaseDate = _endDate ?? _startDate;
                        var endDateTime = DateTime(
                          endBaseDate.year,
                          endBaseDate.month,
                          endBaseDate.day,
                          _endTime.hour,
                          _endTime.minute,
                        );

                        if (_endDate == null &&
                            endDateTime.isBefore(startDateTime)) {
                          endDateTime = endDateTime.add(
                            const Duration(days: 1),
                          );
                        }

                        Navigator.of(context).push(
                          VenueDetailPage.route(
                            venueId: widget.venue.id,
                            startDate: startDateTime,
                            endDate: endDateTime,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Select Level',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    Color textColor,
    Color subTextColor,
    Color primaryColor,
    bool isDark,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final days = <Widget>[];

    // Day Labels
    for (var i = 0; i < 7; i++) {
      days.add(
        Center(
          child: Text(
            dayLabels[i],
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: (i >= 5) ? Colors.red[400] : subTextColor,
            ),
          ),
        ),
      );
    }

    // Empty slots before first day
    for (var i = 1; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    // Days
    for (var i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, i);

      final isStart = isSameDay(date, _startDate);
      final isEnd = _endDate != null && isSameDay(date, _endDate!);
      final isInRange =
          _endDate != null &&
          date.isAfter(_startDate) &&
          date.isBefore(_endDate!);
      final isToday = isSameDay(date, DateTime.now());

      // Visual logic
      BoxDecoration decoration;
      Color itemTextColor;

      if (isStart) {
        decoration = BoxDecoration(
          color: primaryColor,
          borderRadius: _endDate != null
              ? const BorderRadius.horizontal(left: Radius.circular(8))
              : BorderRadius.circular(8),
        );
        itemTextColor = Colors.white;
      } else if (isEnd) {
        decoration = BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(8),
          ),
        );
        itemTextColor = Colors.white;
      } else if (isInRange) {
        decoration = BoxDecoration(
          color: primaryColor.withValues(alpha: 0.2),
        );
        itemTextColor = primaryColor;
      } else {
        decoration = const BoxDecoration(
          color: Colors.transparent,
        );
        itemTextColor = isToday ? primaryColor : textColor;
      }

      days.add(
        InkWell(
          onTap: () => _onDateSelected(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: decoration,
            child: Center(
              child: Text(
                '$i',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isStart || isEnd || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: itemTextColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 4,
      children: days,
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _QuickSelectChip extends StatelessWidget {
  const _QuickSelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.2)
                : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  const _TimeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
    required this.textColor,
  });

  final TimeOfDay value;
  final List<TimeOfDay> items;
  final ValueChanged<TimeOfDay?> onChanged;
  final bool isDark;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDay>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          items: items.map((time) {
            return DropdownMenuItem(
              value: time,
              child: Text(time.format(context)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
