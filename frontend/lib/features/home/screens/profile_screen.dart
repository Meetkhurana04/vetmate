import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetmate/core/theme/app_theme.dart';
import 'package:vetmate/core/constants/app_constants.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/auth/models/auth_state.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);

    final userName = authState.userName ?? 'User';
    final userEmail = authState.userEmail ?? 'user@vetmate.com';
    final userPhone = authState.userPhone ?? 'Not Configured';
    final userRole = authState.userRole == AppConstants.roleDoctor
        ? 'Veterinary Doctor'
        : 'Pet Owner';
    final userCity = locationState.when(
      data: (loc) => loc.cityName ?? 'Jaipur, Rajasthan',
      error: (_, __) => 'Jaipur, Rajasthan',
      loading: () => 'Detecting location...',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Avatar Panel
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Name and Role
            Center(
              child: Column(
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userRole,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Profile details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildProfileItem(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: userEmail,
                    ),
                    const Divider(height: 32),
                    _buildProfileItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      value: userPhone,
                    ),

                    const Divider(height: 32),
                    _buildProfileItem(
                      icon: Icons.location_searching_rounded,
                      title: 'Location',
                      value: locationState.value?.cityName != null
                          ? locationState.value!.cityName!
                          : (authState.userLatitude != null && authState.userLongitude != null
                              ? '${authState.userLatitude!.toStringAsFixed(4)}, ${authState.userLongitude!.toStringAsFixed(4)}'
                              : 'Not Configured'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _showEditProfileDialog(context, ref, authState);
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Profile Details'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Logout button
            ElevatedButton(
              onPressed: () {
                _showLogoutConfirmDialog(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shadowColor: Colors.redAccent.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded),
                  const SizedBox(width: 8),
                  Text('Logout Account'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.textLight, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, AuthState authState) {
    final nameController = TextEditingController(text: authState.userName);
    final phoneController = TextEditingController(text: authState.userPhone);
    final latController = TextEditingController(text: authState.userLatitude?.toString() ?? '');
    final lngController = TextEditingController(text: authState.userLongitude?.toString() ?? '');
    
    final isDoctor = authState.userRole == AppConstants.roleDoctor;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Profile Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latController,
                              decoration: const InputDecoration(labelText: 'Latitude'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lngController,
                              decoration: const InputDecoration(labelText: 'Longitude'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final locNotifier = ref.read(locationProvider.notifier);
                            await locNotifier.fetchLocation(requestPermission: true);
                            final updatedLoc = ref.read(locationProvider).value;
                            if (updatedLoc != null) {
                              setState(() {
                                latController.text = updatedLoc.latitude.toString();
                                lngController.text = updatedLoc.longitude.toString();
                              });
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: const Text('Detect Coordinates'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).updateProfile(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        latitude: double.tryParse(latController.text.trim()),
                        longitude: double.tryParse(lngController.text.trim()),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout Confirmation',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to log out of VetMate?'),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textLight),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
