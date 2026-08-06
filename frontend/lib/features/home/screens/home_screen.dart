import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:vetmate/core/constants/app_constants.dart';
import 'package:vetmate/core/theme/app_theme.dart';
import 'package:vetmate/core/widgets/custom_button.dart';
import 'package:vetmate/core/widgets/empty_state.dart';
import 'package:vetmate/core/widgets/loading_indicator.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/home/providers/clinic_provider.dart';
import 'package:vetmate/features/home/providers/booking_provider.dart';
import 'package:vetmate/features/home/widgets/clinic_card.dart';
import 'package:vetmate/features/home/widgets/distance_slider.dart';
import 'package:vetmate/features/home/screens/appointments_screen.dart';
import 'package:vetmate/features/home/screens/pets_screen.dart';
import 'package:vetmate/features/home/screens/profile_screen.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';
import 'package:vetmate/features/location/models/location_model.dart';
import 'package:vetmate/features/notifications/providers/notification_provider.dart';

final homeTabIndexProvider = StateProvider<int>((ref) {
  return 0;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(homeTabIndexProvider.notifier).state = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).fetchAppointments();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDoctor = authState.userRole == AppConstants.roleDoctor;
    final currentIndex = ref.watch(homeTabIndexProvider);

    final List<Widget> screens = [
      isDoctor ? const _DoctorDashboardView() : const _HomeDashboardView(),
      const AppointmentsScreen(),
      if (!isDoctor) const PetsScreen(),
      const ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.calendar_month_outlined),
        activeIcon: const Icon(Icons.calendar_month_rounded),
        label: isDoctor ? 'Apply Leave' : 'Appointments',
      ),
      if (!isDoctor)
        const BottomNavigationBarItem(
          icon: Icon(Icons.pets_outlined),
          activeIcon: Icon(Icons.pets_rounded),
          label: 'Pets',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    int correctedIndex = currentIndex;
    if (correctedIndex >= navItems.length) {
      correctedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(index: correctedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.tintColor,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: correctedIndex,
            onTap: (index) {
              ref.read(homeTabIndexProvider.notifier).state = index;
              if (index == 1) {
                ref.read(bookingProvider.notifier).fetchAppointments();
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.cardColor,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textLight,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 0,
            items: navItems,
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardView extends ConsumerStatefulWidget {
  const _HomeDashboardView();

  @override
  ConsumerState<_HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends ConsumerState<_HomeDashboardView> {
  bool _isDialogShowing = false;

  void _showLocationDialog(BuildContext context, String errorMessage) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final locationState = ref.watch(locationProvider);
            final isLoading = locationState is AsyncLoading;

            String currentError = errorMessage;
            if (locationState is AsyncError) {
              currentError = locationState.error.toString();
            }

            final isServicesDisabled = currentError.toLowerCase().contains(
              'disabled',
            );
            final isPermanentlyDenied =
                currentError.toLowerCase().contains('permanently') ||
                currentError.toLowerCase().contains('deniedforever');

            String title = 'Location Access Required';
            String desc =
                'VetMate needs your location to find nearby clinics, calculate distance in real-time, and show open hours.';
            String buttonText = 'Grant Permission';

            if (isServicesDisabled) {
              title = 'Location Services Disabled';
              desc =
                  'Location services are disabled on your device. Please open location settings to enable GPS.';
              buttonText = 'Open Location Settings';
            } else if (isPermanentlyDenied) {
              title = 'Location Access Denied';
              desc =
                  'Location permissions are permanently denied. Please open your system settings to enable location access for VetMate.';
              buttonText = 'Open App Settings';
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              backgroundColor: AppTheme.cardColor,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child:  Icon(
                          Icons.location_off_rounded,
                          color: AppTheme.dangerColor,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        desc,
                        style:  TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: buttonText,
                        isLoading: isLoading,
                        onPressed: () async {
                          if (isServicesDisabled) {
                            Navigator.pop(context);
                            _isDialogShowing = false;
                            await Geolocator.openLocationSettings();
                          } else if (isPermanentlyDenied) {
                            Navigator.pop(context);
                            _isDialogShowing = false;
                            await Geolocator.openAppSettings();
                          } else {
                            ref
                                .read(locationProvider.notifier)
                                .fetchLocation(requestPermission: true);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _isDialogShowing = false;
                              },
                        child:  Text(
                          'Not Now',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locationState = ref.read(locationProvider);
        if (locationState is AsyncError) {
          _showLocationDialog(context, locationState.error.toString());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserLocation>>(locationProvider, (previous, next) {
      next.when(
        data: (_) {
          if (_isDialogShowing) {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogShowing = false;
          }
        },
        error: (err, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showLocationDialog(context, err.toString());
            }
          });
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);
    final clinicState = ref.watch(clinicProvider);

    final userName = authState.userName ?? 'User';
    final userRole = authState.userRole;
    final isDoctor = userRole == AppConstants.roleDoctor;
    final displayName = isDoctor ? 'Dr. $userName' : userName;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 70,
        title: Row(
          children: [
            // Small Profile Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style:  TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Good Morning,',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _buildNotificationBell(context),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(clinicProvider.notifier).fetchClinics();
          ref.read(locationProvider.notifier).fetchLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TemporaryLocationSelector(),
              const SizedBox(height: 16),
              // Search Clinics Bar
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.tintColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) {
                    ref.read(clinicProvider.notifier).setSearchQuery(val);
                  },
                  decoration:  InputDecoration(
                    hintText: 'Search Doctors',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.textLight,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Distance Filter Slider
              DistanceSlider(
                value: clinicState.distanceFilter,
                onChanged: (val) {
                  ref.read(clinicProvider.notifier).setDistanceFilter(val);
                },
              ),
              const SizedBox(height: 28),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Doctors',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${clinicState.filteredClinics.length} Found',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Listings
              if (clinicState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.0),
                  child: LoadingIndicator(size: 60.0),
                )
              else if (clinicState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text(
                    clinicState.errorMessage!,
                    style:  TextStyle(color: AppTheme.dangerColor),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (clinicState.filteredClinics.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: EmptyState(
                    title: 'No Doctors Found',
                    description:
                        'No veterinary doctors match your selected filters. Try increasing your distance limit or modifying search keywords.',
                    icon: Icons.search_off_rounded,
                    actionText: 'Reset Filters',
                    onActionPressed: () {
                      ref.read(clinicProvider.notifier).setDistanceFilter(20.0);
                      ref.read(clinicProvider.notifier).setSearchQuery('');
                    },
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clinicState.filteredClinics.length,
                  itemBuilder: (context, index) {
                    final clinic = clinicState.filteredClinics[index];
                    return ClinicCard(
                      clinic: clinic,
                      onBookTap: () {
                        context.push('/book-slot/${clinic.id}');
                      },
                      onViewDetailsTap: () {
                        _showClinicDetailsDialog(context, clinic);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final notifState = ref.watch(notificationProvider);
    final items = notifState.value ?? const [];
    final unread = items.where((n) => !n.read).length;

    return Stack(
      children: [
        IconButton(
          icon:  Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.textDark,
          ),
          onPressed: () {
            ref.read(notificationProvider.notifier).fetchNotifications();
            _showNotificationsSheet(context);
          },
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:  BoxDecoration(
                color: AppTheme.dangerColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final items = ref.watch(notificationProvider).value ?? const [];
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (items.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(notificationProvider.notifier)
                                      .clearNotifications();
                                },
                                icon: const Icon(Icons.clear_all_rounded, size: 18),
                                label: const Text('Clear all'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: items.isEmpty
                          ?  Center(
                              child: Text(
                                'No notifications yet.',
                                style: TextStyle(color: AppTheme.textLight),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final n = items[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                                    child:  Icon(
                                      Icons.event_busy_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    n.message,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showClinicDetailsDialog(BuildContext context, dynamic clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(clinic.image, height: 150, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinic.doctorName,
                    style:  TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                       Icon(Icons.star, color: AppTheme.warningColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${clinic.rating} Rating',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                       Icon(
                        Icons.near_me,
                        color: AppTheme.secondaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${clinic.distance ?? 0} km away',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                   Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(clinic.address, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: clinic.isOpen
                              ? () {
                                  Navigator.pop(context);
                                  context.push('/book-slot/${clinic.id}');
                                }
                              : null,
                          child: const Text('Book'),
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
    );
  }
}

// =============================================================================
// Doctor Dashboard & Add Clinic Implementation
// =============================================================================

class _DoctorDashboardView extends ConsumerStatefulWidget {
  const _DoctorDashboardView();

  @override
  ConsumerState<_DoctorDashboardView> createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends ConsumerState<_DoctorDashboardView> {
  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _showCancelConfirmDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to cancel this appointment slot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Slot', style: TextStyle(color: AppTheme.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(bookingProvider.notifier).cancelAppointment(appointmentId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text('Appointment cancelled successfully.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                }
              },
              child: const Text('Cancel Slot'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);
    final bookingState = ref.watch(bookingProvider);

    final userName = authState.userName ?? 'User';
    final displayName = userName.startsWith('Dr.') ? userName : 'Dr. $userName';

    final allAppointments = bookingState.myAppointments;
    final filteredAppointments = allAppointments.where((apt) => _isSameDay(apt.date, _selectedDate)).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                style:  TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'Good Morning,',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bookingProvider.notifier).fetchAppointments();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctor Dashboard',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
               Text(
                'View and manage your appointments schedule.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),

              // Date Picker Selector Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.tintColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'Schedule Date Filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 14),
                      label: const Text('Change Date'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Active Bookings',
                      value: '${filteredAppointments.where((a) => a.status.toLowerCase() != 'cancelled').length}',
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Cancelled Bookings',
                      value: '${filteredAppointments.where((a) => a.status.toLowerCase() == 'cancelled').length}',
                      icon: Icons.cancel_outlined,
                      color: AppTheme.dangerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Appointments Section Header
              Text(
                'Booked Appointments',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),

              if (filteredAppointments.isEmpty)
                const EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'No Appointments on this Date',
                  description: 'You have no scheduled patient appointments on the selected date.',
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];
                    final formattedDate = DateFormat(
                      'EEEE, d MMMM yyyy',
                    ).format(appointment.date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tintColor,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppTheme.cardBorderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    appointment.clinicImage,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: AppTheme.chipColor,
                                        child:  Icon(
                                          Icons.medical_services_outlined,
                                          color: AppTheme.textLight,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment.clinicName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        appointment.doctorName, // Holds patient name for doctors
                                        style:  TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: AppTheme.dividerColor),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                     Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style:  TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          appointment.slotTime,
                                          style:  TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textLight,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (appointment.status.toLowerCase() != 'cancelled') ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child:  Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_rounded,
                                              size: 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Locked',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.dangerColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          _showCancelConfirmDialog(context, appointment.id);
                                        },
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.chipColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Cancelled',
                                          style: TextStyle(
                                            color: AppTheme.textLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            ref
                                                .read(bookingProvider.notifier)
                                                .removeCancelledAppointment(appointment.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Removed from list'),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: AppTheme.successColor,
                                              ),
                                            );
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tintColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style:  TextStyle(
              fontSize: 13,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemporaryLocationSelector extends ConsumerStatefulWidget {
  const _TemporaryLocationSelector();

  @override
  ConsumerState<_TemporaryLocationSelector> createState() => _TemporaryLocationSelectorState();
}

class _TemporaryLocationSelectorState extends ConsumerState<_TemporaryLocationSelector> {
  final _searchController = TextEditingController();
  List<UserLocation> _results = const [];
  bool _isSearching = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isSearching = true);
    try {
      await ref.read(locationProvider.notifier).fetchLocation(requestPermission: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not detect location. Try searching below.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results =
          await ref.read(locationProvider.notifier).searchLocations(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search failed. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectLocation(UserLocation location) {
    ref.read(locationProvider.notifier).setSelectedLocation(location);
    _searchController.clear();
    setState(() {
      _results = const [];
      _isExpanded = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location set to ${location.cityName}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final currentLoc = locationState.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentLoc != null && currentLoc.cityName != null
                              ? currentLoc.cityName!
                              : 'Tap to detect or search',
                          style:  TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textLight,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: AppTheme.dividerColor),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: 'Search area e.g. Sector 4, Shanti Nagar',
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _search,
                        child: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _detectLocation,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Detect My Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 12),
                     Text(
                      'Select a location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._results.map((r) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.place_outlined, color: AppTheme.primaryColor),
                          title: Text(
                            r.cityName ?? 'Location',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () => _selectLocation(r),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
