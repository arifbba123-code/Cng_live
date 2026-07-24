/// CNG LIVE — Input Validators
///
/// Pure functions, no Flutter/UI dependency — usable directly from
/// ViewModels for form validation (Login/Register/Forgot Password
/// email & password inputs, etc).
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password on login/register (minimum length only —
  /// Firebase enforces its own strength rules server-side and returns
  /// a typed 'weak-password' error we surface separately).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that a confirmation field matches the original password.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
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
}
