import 'package:intl/intl.dart';

/// CNG LIVE — Date/Time Formatting
///
/// Central "5 min ago" relative-time logic, used on every pump card,
/// notification row, and activity entry across the app. Keeping this in
/// one place means the staleness threshold (45 min, per the design
/// system) and formatting rules only need to change in one file.
class DateFormatter {
  DateFormatter._();

  /// Returns a compact relative-time string: "Just now", "5 min ago",
  /// "2 hr ago", "Yesterday", or a short date for anything older.
  static String relative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return DateFormat('MMM d').format(dateTime);
  }

  /// Full date + time for detail views (e.g. "Jul 20, 2026, 5:20 PM").
  static String full(DateTime dateTime) {
    return DateFormat('MMM d, y, h:mm a').format(dateTime);
  }

  /// Whether a status update is considered stale — per the design system,
  /// updates older than 45 minutes should show a staleness warning
  /// (Pump Detail screen, Step 14).
  static bool isStale(DateTime updatedAt, {int staleAfterMinutes = 45}) {
    return DateTime.now().difference(updatedAt).inMinutes >= staleAfterMinutes;
  }
}
