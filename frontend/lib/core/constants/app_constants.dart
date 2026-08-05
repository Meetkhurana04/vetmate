class AppConstants {
  // Secure Storage Keys
  static const String keyAccessToken = 'accessToken';
  static const String keyRefreshToken = 'refreshToken';
  static const String keyUserRole = 'userRole';
  static const String keyUserName = 'userName';
  static const String keyUserId = 'userId';

  // Role names
  static const String roleDoctor = 'DOCTOR';
  static const String rolePetOwner = 'PATIENT';

  // Default Location (Jaipur, India)
  static const double defaultLatitude = 26.9124;
  static const double defaultLongitude = 75.7873;

  // Base URL for the dynamic backend API
  static const String apiBaseUrl = 'http://192.168.5.253:8000';
}
