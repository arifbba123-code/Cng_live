/// CNG LIVE — String Extensions
extension StringExtensions on String {
  /// Capitalizes the first letter only: "stock available" -> "Stock available"
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Formats a raw 10-digit number as "98765 43210" for display.
  String get asFormattedPhone {
    final digits = replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return this;
    return '${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  /// Prepends +91 for storage/Firebase Auth calls.
  String get withCountryCode => '+91$this';

  bool get isNullOrEmptyString => trim().isEmpty;
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
}
