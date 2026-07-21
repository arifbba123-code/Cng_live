/// CNG LIVE — Input Validators
///
/// Pure functions, no Flutter/UI dependency — usable directly from
/// ViewModels for form validation (Login phone input, OTP input, etc).
class Validators {
  Validators._();

  static final RegExp _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Validates a 10-digit Indian mobile number (without +91 prefix).
  /// Returns null if valid, or an error message if invalid.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your phone number';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Enter a valid 10-digit number';
    }
    if (!_indianPhoneRegex.hasMatch(digitsOnly)) {
      return 'Enter a valid 10-digit number';
    }
    return null;
  }

  /// Validates a 6-digit OTP code.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the OTP';
    }
    if (value.trim().length != 6) {
      return 'Enter the complete 6-digit OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  /// Validates a driver's display name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    return null;
  }

  /// Strips a raw phone string down to digits only — used before storing
  /// or querying by phone number.
  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}
