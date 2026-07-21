import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CNG LIVE — Typography Scale
///
/// Locks the formal type scale approved in Step 20 (Section 2), resolving
/// the earlier per-screen size drift (20/22/18sp all used for "headline").
///
/// Base font: Inter (via google_fonts). Tamil text automatically falls
/// back to Noto Sans Tamil via [fontFamilyFallback] — no manual per-string
/// language switching required.
///
/// NOTE: google_fonts fetches at runtime by default. For a fully
/// offline-safe production build, bundle static .ttf files under
/// assets/fonts/ and switch these to a local `fontFamily:` reference
/// instead of GoogleFonts.inter(...) before Play Store release.
class AppTypography {
  AppTypography._();

  static const List<String> _tamilFallback = ['Noto Sans Tamil'];

  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: _tamilFallback,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: _tamilFallback,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: _tamilFallback,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamilyFallback: _tamilFallback,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamilyFallback: _tamilFallback,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: _tamilFallback,
  );

  /// Builds a complete Flutter [TextTheme] from the tokens above, with
  /// the given base color applied. Used by light_theme.dart / dark_theme.dart.
  static TextTheme buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: baseColor),
      headlineMedium: headlineMedium.copyWith(color: baseColor),
      titleMedium: titleMedium.copyWith(color: baseColor),
      bodyMedium: bodyMedium.copyWith(color: baseColor),
      labelMedium: labelMedium.copyWith(color: baseColor),
      bodySmall: caption.copyWith(color: baseColor),
    );
  }
}
