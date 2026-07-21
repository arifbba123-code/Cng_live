import 'package:logger/logger.dart';

/// CNG LIVE — App Logger
///
/// Wraps the `logger` package for structured console logging during
/// development. Production crash/error reporting is handled separately
/// by Firebase Crashlytics (wired in main.dart) — this logger is for
/// local debug visibility and for feeding breadcrumbs into Crashlytics.
///
/// Usage:
///   AppLogger.info('HomeViewModel', 'Loaded 12 pumps');
///   AppLogger.error('PumpRepository', error, stackTrace);
///
/// PRIVACY: Never log PII — phone numbers, exact GPS coordinates, or
/// full addresses. Log user IDs / pump IDs instead, per the Privacy
/// commitments made in the Settings screen design (Step 19).
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void info(String tag, String message) {
    _logger.i('[$tag] $message');
  }

  static void warning(String tag, String message) {
    _logger.w('[$tag] $message');
  }

  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    _logger.e('[$tag]', error: error, stackTrace: stackTrace);
    // Crashlytics forwarding: once firebase_crashlytics is initialized
    // in main.dart, this is where FirebaseCrashlytics.instance
    // .recordError(...) would be called in addition to local logging.
  }

  static void debug(String tag, String message) {
    _logger.d('[$tag] $message');
  }
}
