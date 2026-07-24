/// CNG LIVE — Spacing Tokens
///
/// All spacing follows an 8px grid, per the approved design system.
/// Never hardcode raw padding/margin numbers in a screen — use these.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  /// Standard horizontal screen padding used on every screen.
  static const double screenHorizontal = 16.0;

  /// Standard vertical gap between major sections on a screen.
  static const double sectionGap = 20.0;

  /// Standard gap between list/card items (e.g. pump cards).
  static const double cardGap = 12.0;
}
