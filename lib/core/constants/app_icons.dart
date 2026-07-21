import 'package:flutter/material.dart';

/// CNG LIVE — Icon Registry
///
/// Centralizes every icon used across the app so the "rounded, filled"
/// style rule from the design system is enforced in one place, and
/// sizing follows the table locked in Step 20 (Section 5):
///   - Bottom nav icons        : 24dp
///   - Inline text icons       : 16dp
///   - Card badge icons        : 20dp
///   - Empty state illustration: 96–120dp
class AppIcons {
  AppIcons._();

  // Sizes
  static const double sizeNav = 24.0;
  static const double sizeInline = 16.0;
  static const double sizeBadge = 20.0;
  static const double sizeEmptyState = 120.0;

  // Navigation
  static const IconData home = Icons.home_rounded;
  static const IconData favourites = Icons.star_rounded;
  static const IconData leaderboard = Icons.emoji_events_rounded;
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData profile = Icons.person_rounded;

  // Status
  static const IconData stockAvailable = Icons.check_circle_rounded;
  static const IconData longQueue = Icons.hourglass_bottom_rounded;
  static const IconData noStock = Icons.cancel_rounded;
  static const IconData unverified = Icons.help_rounded;

  // Utility
  static const IconData pump = Icons.local_gas_station_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData queue = Icons.schedule_rounded;
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData report = Icons.flag_rounded;
  static const IconData navigate = Icons.navigation_rounded;
  static const IconData call = Icons.call_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData verified = Icons.verified_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData deleteAccount = Icons.delete_forever_rounded;
}
