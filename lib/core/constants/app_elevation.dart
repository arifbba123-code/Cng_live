/// CNG LIVE — Elevation Tokens
///
/// Formalizes the elevation tiers introduced in the Step 20 review
/// (previously every screen said "soft shadow" with no defined scale).
class AppElevation {
  AppElevation._();

  /// Flat content — dense list rows (Leaderboard rows, Notification rows).
  static const double level0 = 0.0;

  /// Standard cards — pump cards, stat cards, achievement badges.
  static const double level1 = 2.0;

  /// Floating elements — search bar, sticky "Your Rank" card, bottom nav.
  static const double level2 = 4.0;

  /// FAB, pressed/active states, modals, bottom sheets.
  static const double level3 = 8.0;
}
