import 'package:flutter/material.dart';

/// CNG LIVE — Central Color System
///
/// Organized in 3 tiers as defined in the approved design system (Step 20):
///   Tier 1 — Raw brand palette (internal hex values)
///   Tier 2 — Semantic status colors (used everywhere status is shown)
///   Tier 3 — Light/Dark resolved pairs are handled via [AppColorsExtension]
///            in core/theme — widgets should prefer Theme.of(context) access
///            over importing this file directly wherever a theme-aware
///            value exists.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // TIER 1 — Raw Brand Palette
  // ---------------------------------------------------------------------
  static const Color cngGreen = Color(0xFF00A86B);
  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color skyBlue = Color(0xFF2D9CDB);
  static const Color offWhite = Color(0xFFF7F9FA);
  static const Color lightGrey = Color(0xFFE5E8EB);
  static const Color midGrey = Color(0xFF8A94A6);
  static const Color charcoal = Color(0xFF1C1F26);
  static const Color darkSurface = Color(0xFF262A33);

  // Dark-mode brighter accent (used only when isDark == true)
  static const Color cngGreenDark = Color(0xFF1DE28A);

  // ---------------------------------------------------------------------
  // TIER 2 — Semantic Status Colors
  // ---------------------------------------------------------------------
  static const Color stockAvailable = Color(0xFF1DB954);
  static const Color longQueue = Color(0xFFF4A300);
  // Darker amber used for TEXT on light-amber backgrounds only,
  // to satisfy WCAG AA contrast (flagged in Step 20 review, Section 3).
  static const Color longQueueTextOnLight = Color(0xFFB87700);
  static const Color noStock = Color(0xFFE63946);
  static const Color unverified = Color(0xFFB0B7C3);

  // ---------------------------------------------------------------------
  // Podium accent colors (Leaderboard only — not reused elsewhere)
  // ---------------------------------------------------------------------
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // ---------------------------------------------------------------------
  // Status background tint opacities (per Step 20 fix: light vs dark
  // surfaces need different tint strength to stay readable)
  // ---------------------------------------------------------------------
  static const double statusTintOpacityLight = 0.12;
  static const double statusTintOpacityDark = 0.22;

  /// Returns the correct badge background tint for a status color,
  /// respecting the light/dark opacity rule above.
  static Color statusTint(Color statusColor, {required bool isDark}) {
    return statusColor.withOpacity(
      isDark ? statusTintOpacityDark : statusTintOpacityLight,
    );
  }
}
