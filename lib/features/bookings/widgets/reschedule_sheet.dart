import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RescheduleSheet extends StatefulWidget {
  final dynamic booking;
  final void Function(String newDate, String newSlot) onConfirm;

  const RescheduleSheet({
    super.key,
    required this.booking,
    required this.onConfirm,
  });

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late DateTime selectedDate;
  String? selectedSlot;

  late DateTime _originalBookingDate;
  late TimeOfDay _originalBookingStartTime;

  late DateTime _minDate;
  late DateTime _maxDate;

  final List<String> timeSlots = const [
    "9 AM - 12 PM",
    "12 PM - 3 PM",
    "3 PM - 6 PM",
    "6 PM - 8 PM",
  ];

  final Map<String, TimeOfDay> slotStartTimes = const {
    "9 AM - 12 PM": TimeOfDay(hour: 9, minute: 0),
    "12 PM - 3 PM": TimeOfDay(hour: 12, minute: 0),
    "3 PM - 6 PM": TimeOfDay(hour: 15, minute: 0),
    "6 PM - 8 PM": TimeOfDay(hour: 18, minute: 0),
  };

  DateTime get _originalBookingDateTime => DateTime(
        _originalBookingDate.year,
        _originalBookingDate.month,
        _originalBookingDate.day,
        _originalBookingStartTime.hour,
        _originalBookingStartTime.minute,
      );

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    String rawDate = (widget.booking.bookingDate ?? "").trim();
    DateTime parsedDate;

    if (rawDate.isEmpty) {
      parsedDate = DateTime(now.year, now.month, now.day);
    } else {
      try {
        parsedDate = DateFormat("yyyy-MM-dd").parse(rawDate);
      } catch (e) {
        parsedDate = DateTime(now.year, now.month, now.day);
      }
    }

    _originalBookingDate =
        DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

    String rawTime = (widget.booking.bookingTime ?? "").trim();
    if (rawTime.isEmpty) {
      _originalBookingStartTime = const TimeOfDay(hour: 0, minute: 0);
    } else {
      _originalBookingStartTime = _parseBookingTime(rawTime);
    }

    final today = DateTime(now.year, now.month, now.day);
    _minDate =
        today.isAfter(_originalBookingDate) ? today : _originalBookingDate;

    _maxDate = _minDate.add(const Duration(days: 30));

    selectedDate = _minDate;
  }

  TimeOfDay _parseBookingTime(String raw) {
    String s = raw.trim();

    if (s.contains('-')) {
      s = s.split('-').first.trim();
    }

    final formats = ["h:mm a", "hh:mm a", "h a", "hh a"];
    for (var f in formats) {
      try {
        final dt = DateFormat(f).parse(s);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }

    try {
      final parts = s.split(":");
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {}

    return const TimeOfDay(hour: 0, minute: 0);
  }

  bool _isSlotAllowedFor(DateTime date, String slotLabel) {
    final start = slotStartTimes[slotLabel]!;
    final slotDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      start.hour,
      start.minute,
    );

    return slotDateTime.isAfter(_originalBookingDateTime);
  }

  List<String> _slotsForDate(DateTime date) {
    if (DateUtils.isSameDay(date, _originalBookingDate)) {
      return timeSlots.where((s) => _isSlotAllowedFor(date, s)).toList();
    }

    return List<String>.from(timeSlots);
  }

  @override
  Widget build(BuildContext context) {
    final availableSlots = _slotsForDate(selectedDate);

    if (selectedSlot != null && !availableSlots.contains(selectedSlot)) {
      selectedSlot = null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Reschedule Booking",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Choose a new date and time for your service",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: _minDate,
                  lastDate: _maxDate,
                  builder: (ctx, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF1f3b73),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    selectedSlot = null;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF2E6FF2),
                  border: Border.all(color: Colors.grey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat("yyyy-MM-dd").format(selectedDate),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (availableSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "No slots available for this day. Please choose another date.",
                  style: TextStyle(color: Colors.red.shade400),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: GridView.builder(
                  itemCount: availableSlots.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (ctx, i) {
                    final slot = availableSlots[i];
                    final sel = selectedSlot == slot;

                    return GestureDetector(
                      onTap: () => setState(() {
                        selectedSlot = slot;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: sel ? const Color(0xFF2E6FF2) : Colors.white,
                          border: Border.all(
                            color: sel ? const Color(0xFF2E6FF2) : Colors.grey,
                          ),
                          boxShadow: [
                            if (sel)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            slot,
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedSlot == null
                  ? null
                  : () {
                      // FIRST close sheet
                      Navigator.pop(context);

                      // THEN callback
                      widget.onConfirm(
                        DateFormat("yyyy-MM-dd").format(selectedDate),
                        selectedSlot!,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedSlot == null
                    ? Colors.blueGrey.shade300
                    : const Color(0xFF2E6FF2),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: selectedSlot == null ? 0 : 5,
              ),
              child: const Text(
                "Confirm Reschedule",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
