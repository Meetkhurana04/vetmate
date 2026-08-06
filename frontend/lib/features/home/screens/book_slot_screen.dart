import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vetmate/core/theme/app_theme.dart';
import 'package:vetmate/core/widgets/custom_button.dart';
import 'package:vetmate/features/home/screens/home_screen.dart';
import 'package:vetmate/core/widgets/custom_monthly_calendar.dart';
import 'package:vetmate/features/home/models/clinic_model.dart';
import 'package:vetmate/features/home/providers/clinic_provider.dart';
import 'package:vetmate/features/home/providers/booking_provider.dart';

class BookSlotScreen extends ConsumerStatefulWidget {
  final String clinicId;

  const BookSlotScreen({super.key, required this.clinicId});

  @override
  ConsumerState<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends ConsumerState<BookSlotScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlotId;
  String? _selectedSlotTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bookingProvider.notifier)
          .fetchSlotsForClinicAndDate(widget.clinicId, _selectedDate);
      ref.read(bookingProvider.notifier).resetBookingStatus();
    });
  }

  void _handleBooking(ClinicModel clinic, BookingState bookingState) async {
    if (_selectedSlotId == null || _selectedSlotTime == null) return;

    final selectedDate = _selectedDate;

    final success = await ref
        .read(bookingProvider.notifier)
        .bookAppointment(
          clinic: clinic,
          slotId: _selectedSlotId!,
          slotTime: _selectedSlotTime!,
          date: selectedDate,
        );

    if (success && mounted) {
      _showSuccessDialog(clinic);
    } else if (bookingState.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingState.error!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog(ClinicModel clinic) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryColor,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Slot Locked Successfully!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your appointment slot at ${clinic.name} is reserved. We have successfully triggered the API locking protocol.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'View Appointments',
                  onPressed: () {
                    ref.read(homeTabIndexProvider.notifier).state = 1;
                    Navigator.pop(context); // Close dialog
                    context.pop(); // Pop booking screen
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    context.pop(); // Pop booking screen
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicState = ref.watch(clinicProvider);
    final bookingState = ref.watch(bookingProvider);

    // Look up the clinic
    ClinicModel? clinic;
    try {
      clinic = clinicState.allClinics.firstWhere(
        (c) => c.id == widget.clinicId,
      );
    } catch (_) {
      // Fallback in case list is empty/loading
    }

    if (clinic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final slots = bookingState.clinicSlots[widget.clinicId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Slot',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clinic Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    clinic.image,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clinic.doctorName,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clinic.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clinic.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textLight,
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Main Interactive Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Select Date Label
                  Text(
                    'Select Date',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date Selection Calendar
                  CustomMonthlyCalendar(
                    selectedDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    highlightedDates: bookingState.myAppointments
                        .where((apt) => apt.status == 'ACTIVE')
                        .map((apt) => DateFormat('yyyy-MM-dd').format(apt.date))
                        .toSet(),
                    highlightColor: AppTheme.primaryColor,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                        _selectedSlotId = null;
                        _selectedSlotTime = null;
                      });
                      ref
                          .read(bookingProvider.notifier)
                          .fetchSlotsForClinicAndDate(widget.clinicId, date);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Select Time Slot Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Slot (20-Min)',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '9:00 AM - 6:00 PM',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Slots Grid
                  if (bookingState.isLoadingSlots)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    )
                  else if (slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No appointment slots available on this date.',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                          ),
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final isSelected = _selectedSlotId == slot.id;

                        // Styling states
                        Color bgColor = Colors.white;
                        Color textColor = AppTheme.textDark;
                        Color borderColor = Colors.grey.shade200;
                        Widget? suffixIcon;
                        String statusLabel = '';

                        if (slot.isBooked) {
                          // Already Booked - Disabled
                          bgColor = Colors.grey.shade100;
                          textColor = Colors.grey.shade400;
                          borderColor = Colors.grey.shade200;
                          statusLabel = 'Booked';
                          suffixIcon = Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: Colors.grey.shade400,
                          );
                        } else if (!slot.isAvailable) {
                          // Lunch Break (1 PM - 2 PM) - Disabled
                          bgColor = const Color(
                            0xFFFFF3E0,
                          ); // very soft light orange
                          textColor = Colors.orange.shade800;
                          borderColor = Colors.orange.shade100;
                          statusLabel = 'Break';
                        } else if (isSelected) {
                          // Selected by user
                          bgColor = AppTheme.primaryColor;
                          textColor = Colors.white;
                          borderColor = AppTheme.primaryColor;
                        }

                        final bool isClickable =
                            slot.isAvailable && !slot.isBooked;

                        return GestureDetector(
                          onTap: isClickable
                              ? () {
                                  setState(() {
                                    _selectedSlotId = slot.id;
                                    _selectedSlotTime = slot.time;
                                  });
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      slot.time,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    if (suffixIcon != null) ...[
                                      const SizedBox(width: 4),
                                      suffixIcon,
                                    ],
                                  ],
                                ),
                                if (statusLabel.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: textColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Button Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedSlotTime != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selected Slot:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          '${DateFormat('EEEE, d MMM').format(_selectedDate)} at $_selectedSlotTime',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomButton(
                    text: 'Confirm Booking',
                    isLoading: bookingState.isLocking,
                    // Disabled if no slot is selected
                    onPressed: _selectedSlotId != null
                        ? () => _handleBooking(clinic!, bookingState)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
