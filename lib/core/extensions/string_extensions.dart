/// CNG LIVE — String Extensions
extension StringExtensions on String {
  /// Capitalizes the first letter only: "stock available" -> "Stock available"
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isNullOrEmptyString => trim().isEmpty;
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
}
