class AppConstants {
  // Secure Storage Keys
  static const String keyAccessToken = 'accessToken';
  static const String keyRefreshToken = 'refreshToken';
  static const String keyUserRole = 'userRole';
  static const String keyUserName = 'userName';
  static const String keyUserId = 'userId';
  static const String keyUserEmail = 'userEmail';
  static const String keyUserPhone = 'keyUserPhone';
  static const String keyUserLatitude = 'userLatitude';
  static const String keyUserLongitude = 'userLongitude';
  static const String keyUserLeaves = 'userLeaves';

  // Role names
  static const String roleDoctor = 'DOCTOR';
  static const String rolePetOwner = 'PATIENT';

  // Default Location (Jaipur, India)
  static const double defaultLatitude = 26.9124;
  static const double defaultLongitude = 75.7873;

  // Base URL for the dynamic backend API
  static const String apiBaseUrl = 'http://172.24.46.254:8000';
}
