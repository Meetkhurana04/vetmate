/// Centralized validation rules that mirror the backend (Pydantic) constraints.
/// Backend source of truth:
///   name: min 3, max 100
///   email: EmailStr (valid email)
///   phone: exactly 10 chars
///   password: min 8 chars
///   latitude/longitude: optional float

const int kNameMinLength = 3;
const int kNameMaxLength = 100;
const int kPhoneLength = 10;
const int kPasswordMinLength = 8;

final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

String? validateName(String? val) {
  if (val == null || val.trim().isEmpty) return 'Name is required';
  if (val.trim().length < kNameMinLength) {
    return 'Name must be at least $kNameMinLength characters';
  }
  if (val.trim().length > kNameMaxLength) {
    return 'Name must be at most $kNameMaxLength characters';
  }
  return null;
}

String? validateEmail(String? val) {
  if (val == null || val.trim().isEmpty) return 'Email is required';
  if (!_emailRegex.hasMatch(val.trim())) return 'Enter a valid email';
  return null;
}

String? validatePhone(String? val) {
  if (val == null || val.trim().isEmpty) return 'Phone number is required';
  if (val.trim().length != kPhoneLength) {
    return 'Phone number must be exactly $kPhoneLength characters';
  }
  return null;
}

String? validatePassword(String? val) {
  if (val == null || val.isEmpty) return 'Password is required';
  if (val.length < kPasswordMinLength) {
    return 'Password must be at least $kPasswordMinLength characters';
  }
  return null;
}

String? validateLatitude(String? val) {
  if (val == null || val.trim().isEmpty) return null;
  final value = double.tryParse(val.trim());
  if (value == null) return 'Enter a valid number';
  if (value < -90 || value > 90) return 'Latitude must be between -90 and 90';
  return null;
}

String? validateLongitude(String? val) {
  if (val == null || val.trim().isEmpty) return null;
  final value = double.tryParse(val.trim());
  if (value == null) return 'Enter a valid number';
  if (value < -180 || value > 180) {
    return 'Longitude must be between -180 and 180';
  }
  return null;
}
