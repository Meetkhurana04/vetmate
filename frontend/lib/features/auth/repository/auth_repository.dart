import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vetmate/core/constants/app_constants.dart';
import 'package:vetmate/core/services/http_service.dart';
import 'package:vetmate/features/auth/models/auth_state.dart';

class AuthRepository {
  final HttpService _httpService;
  final FlutterSecureStorage _storage;

  AuthRepository({HttpService? httpService, FlutterSecureStorage? storage})
    : _httpService = httpService ?? HttpService(),
      _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userRole,
    required String userName,
    required String userId,
  }) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _storage.write(
      key: AppConstants.keyRefreshToken,
      value: refreshToken,
    );
    await _storage.write(key: AppConstants.keyUserRole, value: userRole);
    await _storage.write(key: AppConstants.keyUserName, value: userName);
    await _storage.write(key: AppConstants.keyUserId, value: userId);
  }

  Future<Map<String, String?>> getSession() async {
    final accessToken = await _storage.read(key: AppConstants.keyAccessToken);
    final refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
    final userRole = await _storage.read(key: AppConstants.keyUserRole);
    final userName = await _storage.read(key: AppConstants.keyUserName);
    final userId = await _storage.read(key: AppConstants.keyUserId);

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userRole': userRole,
      'userName': userName,
      'userId': userId,
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserRole);
    await _storage.delete(key: AppConstants.keyUserName);
    await _storage.delete(key: AppConstants.keyUserId);
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<AuthState> _parseAuthState(Map<String, dynamic> rawData) async {
    // Flatten nested envelopes if present (e.g. data: { token: '...' } or response: { ... })
    Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
    if (rawData.containsKey('data') && rawData['data'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(rawData['data'] as Map));
    } else if (rawData.containsKey('result') && rawData['result'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(rawData['result'] as Map));
    } else if (rawData.containsKey('response') && rawData['response'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(rawData['response'] as Map));
    }

    // Flatten nested user details if present
    if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(data['user'] as Map));
    }

    final accessToken = (data['accessToken'] ?? data['access_token'] ?? data['token'] ?? data['access'] ?? '').toString();
    final refreshToken = (data['refreshToken'] ?? data['refresh_token'] ?? '').toString();

    if (accessToken.isEmpty) {
      throw Exception('Server did not return a valid credentials token.');
    }

    // Decode JWT payload for extra claims (user_id, role, name, email)
    final jwtClaims = _decodeJwt(accessToken);

    final userRole = (data['userRole'] ?? data['role'] ?? jwtClaims['role'] ?? jwtClaims['userRole'] ?? '').toString();
    final userName = (data['userName'] ?? data['name'] ?? jwtClaims['name'] ?? jwtClaims['userName'] ?? jwtClaims['username'] ?? 'User').toString();
    final userId = (data['userId'] ?? data['id'] ?? data['_id'] ?? jwtClaims['user_id'] ?? jwtClaims['userId'] ?? jwtClaims['sub'] ?? '').toString();

    await saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userRole: userRole,
      userName: userName,
      userId: userId,
    );

    return AuthState(
      status: AuthStatus.authenticated,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userRole: userRole,
      userName: userName,
      userId: userId,
    );
  }

  Future<AuthState> login({
    required String email,
    required String password,
    required String preSelectedRole,
  }) async {
    final response = await _httpService.post(
      '/auth/login',
      body: {'email': email, 'password': password, 'role': preSelectedRole},
    );

    print('Auth Login Response Body: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseAuthState(data);
  }

  Future<AuthState> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _httpService.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    );

    print('Auth Register Response Body: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseAuthState(data);
  }

  Future<AuthState?> refreshSessionToken() async {
    final session = await getSession();
    final refreshToken = session['refreshToken'];
    final userRole = session['userRole'];
    final userName = session['userName'];
    final userId = session['userId'];

    if (refreshToken != null &&
        userRole != null &&
        userName != null &&
        userId != null) {
      try {
        final response = await _httpService.post(
          '/auth/refresh',
          body: {'refreshToken': refreshToken},
        );

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = (data['accessToken'] ?? data['token'] ?? '').toString();
        final newRefreshToken = (data['refreshToken'] ?? refreshToken).toString();

        if (newAccessToken.isEmpty) {
          throw Exception('Token refresh response was empty.');
        }

        await _storage.write(
          key: AppConstants.keyAccessToken,
          value: newAccessToken,
        );
        await _storage.write(
          key: AppConstants.keyRefreshToken,
          value: newRefreshToken,
        );

        return AuthState(
          status: AuthStatus.authenticated,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          userRole: userRole,
          userName: userName,
          userId: userId,
        );
      } catch (_) {
        await clearSession();
        return const AuthState(status: AuthStatus.unauthenticated);
      }
    }
    return null;
  }
}
