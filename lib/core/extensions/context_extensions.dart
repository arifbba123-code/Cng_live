import 'package:flutter/material.dart';
import '../theme/status_colors_extension.dart';

/// CNG LIVE — BuildContext Extensions
///
/// Shortcuts used throughout every screen to avoid repeating
/// `Theme.of(context)` / `MediaQuery.of(context)` boilerplate.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  StatusColorsExtension get statusColors =>
      Theme.of(this).extension<StatusColorsExtension>() ??
      StatusColorsExtension.light;

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shows the app-standard snackbar (Deep Navy/Surface bg, per theme).
  void showAppSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), action: action),
    );
  }
}
