import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';
import 'status_colors_extension.dart';

/// CNG LIVE — Dark Theme
///
/// Closes the biggest gap flagged in Step 20 (Section 13): dark mode was
/// only ever designed for the Splash screen. This gives every other
/// screen a fully defined dark surface/card/text mapping using the
/// Charcoal/Surface tokens from the approved design system, and keeps
/// status hues identical to light mode (only tint opacity changes).
ThemeData buildDarkTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.cngGreenDark,
    onPrimary: AppColors.deepNavy,
    secondary: AppColors.skyBlue,
    onSecondary: Colors.white,
    tertiary: AppColors.longQueue,
    onTertiary: AppColors.deepNavy,
    error: AppColors.noStock,
    onError: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.offWhite,
    surfaceContainerHighest: Color(0xFF31353F),
    onSurfaceVariant: AppColors.midGrey,
    outline: Color(0xFF3A3F4B),
  );

  final textTheme = AppTypography.buildTextTheme(AppColors.offWhite);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.charcoal,
    textTheme: textTheme,
    fontFamily: textTheme.bodyMedium?.fontFamily,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.charcoal,
      foregroundColor: AppColors.offWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleMedium.copyWith(
        color: AppColors.offWhite,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.featureRadius,
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cngGreenDark,
        foregroundColor: AppColors.deepNavy,
        disabledBackgroundColor: const Color(0xFF3A3F4B),
        disabledForegroundColor: AppColors.midGrey,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.compact),
        ),
        textStyle: AppTypography.labelMedium.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cngGreenDark,
        side: const BorderSide(color: AppColors.cngGreenDark),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.compact),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: Color(0xFF3A3F4B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: Color(0xFF3A3F4B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide:
            const BorderSide(color: AppColors.cngGreenDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: AppColors.noStock),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedColor: AppColors.cngGreenDark,
      labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.offWhite),
      secondaryLabelStyle:
          AppTypography.labelMedium.copyWith(color: AppColors.deepNavy),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: Color(0xFF3A3F4B)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.cngGreenDark,
      unselectedItemColor: AppColors.midGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.cngGreenDark,
      foregroundColor: AppColors.deepNavy,
      elevation: 6,
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A3F4B),
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle:
          AppTypography.bodyMedium.copyWith(color: AppColors.offWhite),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
      ),
    ),

    extensions: const [StatusColorsExtension.dark],
  );
}
