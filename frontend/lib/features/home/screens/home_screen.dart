import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vetmate/core/constants/app_constants.dart';
import 'package:vetmate/core/theme/app_theme.dart';
import 'package:vetmate/core/widgets/custom_button.dart';
import 'package:vetmate/core/widgets/empty_state.dart';
import 'package:vetmate/core/widgets/loading_indicator.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/home/models/clinic_model.dart';
import 'package:vetmate/features/home/providers/clinic_provider.dart';
import 'package:vetmate/features/home/widgets/clinic_card.dart';
import 'package:vetmate/features/home/widgets/distance_slider.dart';
import 'package:vetmate/features/home/screens/appointments_screen.dart';
import 'package:vetmate/features/home/screens/pets_screen.dart';
import 'package:vetmate/features/home/screens/profile_screen.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';
import 'package:vetmate/features/location/models/location_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDoctor = authState.userRole == AppConstants.roleDoctor;

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
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month_rounded),
        label: 'Appointments',
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

    int correctedIndex = _currentIndex;
    if (correctedIndex >= navItems.length) {
      correctedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(index: correctedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
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
              backgroundColor: Colors.white,
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
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_off_rounded,
                          color: Colors.redAccent,
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
                        style: const TextStyle(
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
                        child: const Text(
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
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
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
          // Current Location Badge
          locationState.when(
            data: (location) => InkWell(
              onTap: () {
                ref
                    .read(locationProvider.notifier)
                    .fetchLocation(requestPermission: true);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location.cityName ?? 'Jaipur',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.textDark,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications is empty.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
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
              // Search Clinics Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) {
                    ref.read(clinicProvider.notifier).setSearchQuery(val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search Clinics',
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
                    'Nearby Clinics',
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
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (clinicState.filteredClinics.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: EmptyState(
                    title: 'No Clinics Found',
                    description:
                        'No veterinary clinics match your selected filters. Try increasing your distance limit or modifying search keywords.',
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
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${clinic.rating} Rating',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(
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
                  const Text(
                    'Address',
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

class _DoctorDashboardView extends ConsumerWidget {
  const _DoctorDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);
    final clinicState = ref.watch(clinicProvider);

    ref.listen<ClinicState>(clinicProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final userName = authState.userName ?? 'User';
    final displayName = userName.startsWith('Dr.') ? userName : 'Dr. $userName';

    // Filter clinics managed by this doctor
    final myClinics = clinicState.allClinics
        .where(
          (clinic) =>
              clinic.doctorName.toLowerCase().contains(userName.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
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
                  const Text(
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
          // Current Location Badge
          locationState.when(
            data: (location) => InkWell(
              onTap: () {
                ref
                    .read(locationProvider.notifier)
                    .fetchLocation(requestPermission: true);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location.cityName ?? 'Jaipur',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(clinicProvider.notifier).fetchClinics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              Text(
                'Doctor Dashboard',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your veterinary clinics and appointments.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),

              // Statistics Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'My Clinics',
                      value: '${myClinics.length}',
                      icon: Icons.store_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Appointments',
                      value: '3', // Mock pending bookings
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Clinics Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Clinics (${myClinics.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showAddClinicBottomSheet(context);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Add New',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // List of clinics
              if (clinicState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: LoadingIndicator(),
                  ),
                )
              else if (myClinics.isEmpty)
                EmptyState(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'No Clinics Found',
                  description:
                      "You haven't listed any clinics yet. Tap 'Add New' to create your first veterinary clinic.",
                  actionText: 'Add First Clinic',
                  onActionPressed: () {
                    _showAddClinicBottomSheet(context);
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myClinics.length,
                  itemBuilder: (context, index) {
                    final clinic = myClinics[index];
                    return ClinicCard(clinic: clinic);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddClinicBottomSheet(context);
        },
        label: const Text('Add Clinic'),
        icon: const Icon(Icons.add_business_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              color: color.withOpacity(0.1),
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
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClinicBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddClinicSheet(),
    );
  }
}

class _AddClinicSheet extends ConsumerStatefulWidget {
  const _AddClinicSheet();

  @override
  ConsumerState<_AddClinicSheet> createState() => _AddClinicSheetState();
}

class _AddClinicSheetState extends ConsumerState<_AddClinicSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isOpen = true;
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locNotifier = ref.read(locationProvider.notifier);
      await locNotifier.fetchLocation(requestPermission: true);

      final updatedLoc = ref.read(locationProvider).value;
      if (updatedLoc != null) {
        _latController.text = updatedLoc.latitude.toString();
        _lngController.text = updatedLoc.longitude.toString();
        _addressController.text = updatedLoc.cityName ?? '';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully loaded current location!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        throw Exception('Location is not available.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load location: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = ref.read(authProvider);
      final userName = authState.userName ?? 'Doctor';
      final displayName = 'Dr. $userName';

      final clinic = ClinicModel(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        doctorName: displayName,
        latitude: double.parse(_latController.text),
        longitude: double.parse(_lngController.text),
        rating: 4.5, // Default new clinic rating
        address: _addressController.text.trim(),
        isOpen: _isOpen,
        image: 'assets/images/happy_paws.png',
      );

      ref.read(clinicProvider.notifier).addClinic(clinic);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${clinic.name} successfully added!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add New Clinic',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name',
                  hintText: 'e.g. Happy Paws Clinic',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the clinic name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g. C-Scheme, Jaipur',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the clinic address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: 'e.g. 26.9124',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: 'e.g. 75.7873',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _isGettingLocation
                      ? 'Fetching GPS...'
                      : 'Auto-detect Current Location',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          color: _isOpen ? Colors.green : Colors.redAccent,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clinic Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Show as open for bookings',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isOpen,
                      onChanged: (val) {
                        setState(() {
                          _isOpen = val;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(text: 'Save Clinic', onPressed: _submit),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
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
  }
}
