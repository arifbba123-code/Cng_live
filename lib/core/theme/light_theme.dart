import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';
import 'status_colors_extension.dart';

/// CNG LIVE — Light Theme
///
/// Maps every brand color to its M3 semantic ColorScheme role, closing
/// the gap flagged in Step 20 (Section 1) where colors were previously
/// referenced only by brand name, never by semantic role.
ThemeData buildLightTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.cngGreen,
    onPrimary: Colors.white,
    secondary: AppColors.skyBlue,
    onSecondary: Colors.white,
    tertiary: AppColors.longQueue,
    onTertiary: Colors.white,
    error: AppColors.noStock,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.deepNavy,
    surfaceContainerHighest: AppColors.lightGrey,
    onSurfaceVariant: AppColors.midGrey,
    outline: AppColors.lightGrey,
  );

  final textTheme = AppTypography.buildTextTheme(AppColors.deepNavy);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.offWhite,
    textTheme: textTheme,
    fontFamily: textTheme.bodyMedium?.fontFamily,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.offWhite,
      foregroundColor: AppColors.deepNavy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleMedium.copyWith(
        color: AppColors.deepNavy,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.featureRadius,
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cngGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.lightGrey,
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
        foregroundColor: AppColors.cngGreen,
        side: const BorderSide(color: AppColors.cngGreen),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.compact),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: AppColors.cngGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
        borderSide: const BorderSide(color: AppColors.noStock),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.cngGreen,
      labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.deepNavy),
      secondaryLabelStyle:
          AppTypography.labelMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: AppColors.lightGrey),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.cngGreen,
      unselectedItemColor: AppColors.midGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.cngGreen,
      foregroundColor: Colors.white,
      elevation: 6,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.lightGrey,
      thickness: 1,
      space: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.deepNavy,
      contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.compact),
      ),
    ),

    extensions: const [StatusColorsExtension.light],
  );
}
