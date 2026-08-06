import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/core/services/http_service.dart';
import 'package:vetmate/features/auth/models/auth_state.dart';
import 'package:vetmate/features/auth/repository/auth_repository.dart';

// Role selection provider for the "Choose Role" page
final roleProvider = StateProvider<String>((ref) {
  return ''; // Empty initially, set to 'doctor' or 'petOwner'
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return AuthRepository(httpService: httpService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  Timer? _tokenRefreshTimer;

  AuthNotifier(this._repository) : super(const AuthState()) {
    restoreSession();
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    // Refresh token every 30 minutes
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      refreshSessionToken();
    });
  }

  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  @override
  void dispose() {
    _stopTokenRefreshTimer();
    super.dispose();
  }

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final session = await _repository.getSession();
      final accessToken = session['accessToken'];
      final refreshToken = session['refreshToken'];
      final userRole = session['userRole'];
      final userName = session['userName'];
      final userId = session['userId'];
      final userEmail = session['userEmail'];
      final userPhone = session['userPhone'];
      final userLatitude = session['userLatitude'] != null ? double.tryParse(session['userLatitude']!) : null;
      final userLongitude = session['userLongitude'] != null ? double.tryParse(session['userLongitude']!) : null;

      if (accessToken != null &&
          refreshToken != null &&
          userRole != null &&
          userName != null &&
          userId != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          accessToken: accessToken,
          refreshToken: refreshToken,
          userRole: userRole,
          userName: userName,
          userEmail: userEmail,
          userPhone: userPhone,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
          userId: userId,
        );
        _startTokenRefreshTimer();
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Failed to restore session: ${e.toString()}',
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repository.login(
        email: email,
        password: password,
        preSelectedRole: role,
      );
      state = result;
      _startTokenRefreshTimer();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        latitude: latitude,
        longitude: longitude,
      );
      state = result;
      _startTokenRefreshTimer();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repository.updateProfile(
        name: name,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
      );
      state = result;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> toggleLeave(String dateStr, bool takeLeave) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final action = takeLeave ? 'TAKE' : 'CANCEL';
      final updatedLeaves = await _repository.manageLeave(dateStr, action);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        userLeaves: updatedLeaves,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.clearSession();
      _stopTokenRefreshTimer();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to logout: ${e.toString()}',
      );
    }
  }

  Future<void> refreshSessionToken() async {
    // If we're authenticated, attempt silent token refresh in the background
    if (state.status == AuthStatus.authenticated) {
      try {
        final renewedState = await _repository.refreshSessionToken();
        if (renewedState != null) {
          state = renewedState;
          print(
            'Session token refreshed successfully: ${renewedState.accessToken}',
          );
        }
      } catch (e) {
        // We log the error but don't automatically logout user if they are using the app,
        // as transient network failures shouldn't kick active users out immediately.
        print('Background session refresh error: $e');
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
