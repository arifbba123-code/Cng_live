import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// CNG LIVE — Status Color Theme Extension
///
/// M3's default [ColorScheme] has no concept of "stock available / long
/// queue / no stock" — these are CNG LIVE-specific semantic colors, so
/// they're exposed via a custom [ThemeExtension] instead of being
/// hardcoded per-widget. Access via:
///
///   Theme.of(context).extension<StatusColorsExtension>()!.stockAvailable
///
/// This keeps status colors theme-aware (so tint opacity correctly
/// differs between light/dark, per Step 20's fix) without ever changing
/// the actual hue between modes.
@immutable
class StatusColorsExtension extends ThemeExtension<StatusColorsExtension> {
  const StatusColorsExtension({
    required this.stockAvailable,
    required this.longQueue,
    required this.longQueueText,
    required this.noStock,
    required this.unverified,
    required this.isDark,
  });

  final Color stockAvailable;
  final Color longQueue;
  final Color longQueueText;
  final Color noStock;
  final Color unverified;
  final bool isDark;

  /// Background tint for a status badge, respecting the light/dark
  /// opacity rule (12% light / 22% dark) locked in the design review.
  Color tintFor(Color statusColor) =>
      AppColors.statusTint(statusColor, isDark: isDark);

  static const StatusColorsExtension light = StatusColorsExtension(
    stockAvailable: AppColors.stockAvailable,
    longQueue: AppColors.longQueue,
    longQueueText: AppColors.longQueueTextOnLight,
    noStock: AppColors.noStock,
    unverified: AppColors.unverified,
    isDark: false,
  );

  static const StatusColorsExtension dark = StatusColorsExtension(
    stockAvailable: AppColors.stockAvailable,
    longQueue: AppColors.longQueue,
    // On dark surfaces the badge background is dark enough that the
    // brighter amber itself stays readable — no separate text shade needed.
    longQueueText: AppColors.longQueue,
    noStock: AppColors.noStock,
    unverified: AppColors.unverified,
    isDark: true,
  );

  @override
  StatusColorsExtension copyWith({
    Color? stockAvailable,
    Color? longQueue,
    Color? longQueueText,
    Color? noStock,
    Color? unverified,
    bool? isDark,
  }) {
    return StatusColorsExtension(
      stockAvailable: stockAvailable ?? this.stockAvailable,
      longQueue: longQueue ?? this.longQueue,
      longQueueText: longQueueText ?? this.longQueueText,
      noStock: noStock ?? this.noStock,
      unverified: unverified ?? this.unverified,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  StatusColorsExtension lerp(
      ThemeExtension<StatusColorsExtension>? other, double t) {
    if (other is! StatusColorsExtension) return this;
    return StatusColorsExtension(
      stockAvailable: Color.lerp(stockAvailable, other.stockAvailable, t)!,
      longQueue: Color.lerp(longQueue, other.longQueue, t)!,
      longQueueText: Color.lerp(longQueueText, other.longQueueText, t)!,
      noStock: Color.lerp(noStock, other.noStock, t)!,
      unverified: Color.lerp(unverified, other.unverified, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
