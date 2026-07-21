import '../utils/date_formatter.dart';

/// CNG LIVE — DateTime Extensions
///
/// Thin convenience wrapper over [DateFormatter] so call sites can write
/// `update.timestamp.toRelative()` instead of importing the formatter
/// class directly everywhere.
extension DateTimeExtensions on DateTime {
  String toRelative() => DateFormatter.relative(this);

  String toFullDateTime() => DateFormatter.full(this);

  bool get isStale => DateFormatter.isStale(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}
