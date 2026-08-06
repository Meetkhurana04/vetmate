import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetmate/core/constants/app_constants.dart';
import 'package:vetmate/core/theme/app_theme.dart';
import 'package:vetmate/core/validators/validators.dart';
import 'package:vetmate/core/widgets/custom_button.dart';
import 'package:vetmate/core/widgets/custom_text_field.dart';
import 'package:vetmate/features/auth/models/auth_state.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/location/providers/location_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isRegistering = false;
  bool _isDetectingLocation = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _detectCoordinates() async {
    setState(() {
      _isDetectingLocation = true;
    });
    try {
      final locNotifier = ref.read(locationProvider.notifier);
      await locNotifier.fetchLocation(requestPermission: true);
      final updatedLoc = ref.read(locationProvider).value;
      if (updatedLoc != null) {
        _latitudeController.text = updatedLoc.latitude.toString();
        _longitudeController.text = updatedLoc.longitude.toString();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Coordinates auto-detected successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to detect coordinates: $e'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final selectedRole = ref.read(roleProvider);

      if (_isRegistering) {
        final isDoctor = selectedRole == AppConstants.roleDoctor;
        ref
            .read(authProvider.notifier)
            .register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text.trim(),
              role: selectedRole,
              latitude: isDoctor ? double.tryParse(_latitudeController.text.trim()) : null,
              longitude: isDoctor ? double.tryParse(_longitudeController.text.trim()) : null,
            );
      } else {
        ref
            .read(authProvider.notifier)
            .login(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              role: selectedRole,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(roleProvider);
    final authState = ref.watch(authProvider);

    // Watch auth status changes to show error snackbars
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isDoctor = selectedRole == AppConstants.roleDoctor;
    final roleTitle = isDoctor ? 'Doctor' : 'Pet Owner';
    final screenTitle = _isRegistering
        ? '$roleTitle Register'
        : '$roleTitle Login';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // App Logo
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Dynamic Title
                Text(
                  screenTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegistering
                      ? 'Create an account to start'
                      : 'Welcome back! Sign in to continue',
                  style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Animated Form Container
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isRegistering
                        ? _buildRegisterFields()
                        : _buildLoginFields(),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: _isRegistering ? 'Register' : 'Login',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 24),

                // Form Switch Trigger
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegistering
                          ? 'Already have an account? '
                          : "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                        });
                      },
                      child: Text(
                        _isRegistering ? 'Login' : 'Register',
                        style:  TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
),
      ),
    ),
  );
}

  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login_fields'),
      children: [
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: validatePassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Forgot Password flow simulated.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child:  Text(
              'Forgot Password?',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      key: const ValueKey('register_fields'),
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          validator: validateName,
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: kPhoneLength,
          validator: validatePhone,
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: validatePassword,
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Confirm your password';
            if (val != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _latitudeController,
                label: 'Latitude',
                hint: 'e.g. 26.9124',
                prefixIcon: Icons.location_searching_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validateLatitude,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _longitudeController,
                label: 'Longitude',
                hint: 'e.g. 75.7873',
                prefixIcon: Icons.location_searching_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validateLongitude,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isDetectingLocation ? null : _detectCoordinates,
            icon: _isDetectingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Auto-detect Coordinates'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
