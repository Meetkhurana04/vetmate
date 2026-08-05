import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetmate/core/theme/app_theme.dart';
import 'package:vetmate/core/constants/app_constants.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);

    final userName = authState.userName ?? 'User';
    final userEmail = authState.accessToken != null
        ? (authState.userRole == AppConstants.roleDoctor
              ? 'doctor@vetmate.com'
              : 'user@vetmate.com')
        : 'user@vetmate.com';
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
                      userName.substring(0, 1).toUpperCase(),
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
                      value: '+91 9876543210',
                    ),
                    const Divider(height: 32),
                    _buildProfileItem(
                      icon: Icons.location_on_outlined,
                      title: 'Current City',
                      value: userCity,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
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
