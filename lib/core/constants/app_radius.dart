import 'package:flutter/material.dart';

/// CNG LIVE — Corner Radius Tokens
///
/// Per the Step 20 design review, radius was standardized to exactly
/// TWO tokens to close the 12px/16px/20px drift found across screens:
///   - compact  (12px) -> buttons, chips, small/list-row cards
///   - feature  (16px) -> large feature cards, sheets, containers
class AppRadius {
  AppRadius._();

  static const double compact = 12.0;
  static const double feature = 16.0;
  static const double pill = 999.0; // fully rounded (chips, badges, FAB)

  static const BorderRadius compactRadius =
      BorderRadius.all(Radius.circular(compact));
  static const BorderRadius featureRadius =
      BorderRadius.all(Radius.circular(feature));
  static const BorderRadius pillRadius =
      BorderRadius.all(Radius.circular(pill));
}
