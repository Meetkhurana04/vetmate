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
    String? userEmail,
    String? userPhone,
    double? userLatitude,
    double? userLongitude,
    List<String>? userLeaves,
  }) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _storage.write(
      key: AppConstants.keyRefreshToken,
      value: refreshToken,
    );
    await _storage.write(key: AppConstants.keyUserRole, value: userRole);
    await _storage.write(key: AppConstants.keyUserName, value: userName);
    await _storage.write(key: AppConstants.keyUserId, value: userId);
    if (userEmail != null) await _storage.write(key: AppConstants.keyUserEmail, value: userEmail);
    if (userPhone != null) await _storage.write(key: AppConstants.keyUserPhone, value: userPhone);
    if (userLatitude != null) await _storage.write(key: AppConstants.keyUserLatitude, value: userLatitude.toString());
    if (userLongitude != null) await _storage.write(key: AppConstants.keyUserLongitude, value: userLongitude.toString());
    if (userLeaves != null) await _storage.write(key: AppConstants.keyUserLeaves, value: jsonEncode(userLeaves));
  }

  Future<Map<String, String?>> getSession() async {
    final accessToken = await _storage.read(key: AppConstants.keyAccessToken);
    final refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
    final userRole = await _storage.read(key: AppConstants.keyUserRole);
    final userName = await _storage.read(key: AppConstants.keyUserName);
    final userId = await _storage.read(key: AppConstants.keyUserId);
    final userEmail = await _storage.read(key: AppConstants.keyUserEmail);
    final userPhone = await _storage.read(key: AppConstants.keyUserPhone);
    final userLatitude = await _storage.read(key: AppConstants.keyUserLatitude);
    final userLongitude = await _storage.read(key: AppConstants.keyUserLongitude);
    final userLeaves = await _storage.read(key: AppConstants.keyUserLeaves);

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userRole': userRole,
      'userName': userName,
      'userId': userId,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'userLeaves': userLeaves,
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserRole);
    await _storage.delete(key: AppConstants.keyUserName);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyUserEmail);
    await _storage.delete(key: AppConstants.keyUserPhone);
    await _storage.delete(key: AppConstants.keyUserLatitude);
    await _storage.delete(key: AppConstants.keyUserLongitude);
    await _storage.delete(key: AppConstants.keyUserLeaves);
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
    Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
    if (rawData.containsKey('data') && rawData['data'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(rawData['data'] as Map));
    } else if (rawData.containsKey('result') && rawData['result'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(rawData['result'] as Map));
    } else if (rawData.containsKey('response') && rawData['response'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(rawData['response'] as Map));
    }

    if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
      data.addAll(Map<String, dynamic>.from(data['user'] as Map));
    }

    var accessToken = (data['accessToken'] ?? data['access_token'] ?? data['token'] ?? data['access'] ?? '').toString();
    var refreshToken = (data['refreshToken'] ?? data['refresh_token'] ?? '').toString();

    if (accessToken.isEmpty) {
      accessToken = await _storage.read(key: AppConstants.keyAccessToken) ?? '';
      refreshToken = await _storage.read(key: AppConstants.keyRefreshToken) ?? '';
    }

    if (accessToken.isEmpty) {
      throw Exception('Server did not return a valid credentials token.');
    }

    final jwtClaims = _decodeJwt(accessToken);

    final userRole = (data['userRole'] ?? data['role'] ?? jwtClaims['role'] ?? jwtClaims['userRole'] ?? '').toString();
    final userName = (data['userName'] ?? data['name'] ?? jwtClaims['name'] ?? jwtClaims['userName'] ?? jwtClaims['username'] ?? 'User').toString();
    final userId = (data['userId'] ?? data['id'] ?? data['_id'] ?? jwtClaims['user_id'] ?? jwtClaims['userId'] ?? jwtClaims['sub'] ?? '').toString();

    final userEmail = (data['userEmail'] ?? data['email'] ?? jwtClaims['email'] ?? '').toString();
    final userPhone = (data['userPhone'] ?? data['phone'] ?? jwtClaims['phone'] ?? '').toString();
    final userLatitude = data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null;
    final userLongitude = data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null;
    final userLeaves = data['leaves'] != null
        ? List<String>.from(data['leaves'] as List)
        : <String>[];

    await saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userRole: userRole,
      userName: userName,
      userId: userId,
      userEmail: userEmail,
      userPhone: userPhone,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      userLeaves: userLeaves,
    );

    return AuthState(
      status: AuthStatus.authenticated,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userRole: userRole,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      userLeaves: userLeaves,
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
    double? latitude,
    double? longitude,
  }) async {
    final response = await _httpService.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
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

  Future<AuthState> updateProfile({
    required String name,
    required String phone,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _httpService.put(
      '/auth/profile',
      body: {
        'name': name,
        'phone': phone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseAuthState(data);
  }

  Future<List<String>> manageLeave(String date, String action) async {
    final response = await _httpService.post(
      '/auth/doctors/leave',
      body: {
        'date': date,
        'action': action,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final leaves = List<String>.from(data['leaves'] as List);
    
    await _storage.write(key: AppConstants.keyUserLeaves, value: jsonEncode(leaves));
    
    return leaves;
  }
}
