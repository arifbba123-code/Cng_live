/// CNG LIVE — Non-Localized Fallback Strings
///
/// Placeholder for app-wide static copy until proper localization
/// (flutter_localizations / .arb files) is wired in. Keep every
/// user-facing string here rather than inline in widgets, so
/// localization later is a find-and-replace, not a rewrite.
class AppStrings {
  AppStrings._();

  static const String appName = 'CNG LIVE';
  static const String tagline = 'Fuel Smart. Drive Sure.';
  static const String connectingToLiveUpdates = 'Connecting to Live Updates...';

  // Generic
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String submit = 'Submit';
  static const String continueLabel = 'Continue';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noInternet = "You're offline — showing last saved data";
  static const String pendingSync = 'Pending sync';
}
