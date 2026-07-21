import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../data/models/pump_model.dart';

/// CNG LIVE — Status Badge
///
/// Single source of truth for mapping a PumpStatus to its color across
/// Home, Pump Details, and Update Status — resolving the duplicated
/// switch-statement pattern that had been repeated inline in each
/// screen. Reads status colors via context.statusColors, so it stays
/// correct in both light and dark mode automatically.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final PumpStatus status;

  /// Compact mode renders just colored text (used inline, e.g. pump
  /// list cards). Non-compact renders a filled pill badge (used on
  /// Pump Detail's hero status card).
  final bool compact;

  static Color colorFor(BuildContext context, PumpStatus status) {
    final statusColors = context.statusColors;
    switch (status) {
      case PumpStatus.stockAvailable:
        return statusColors.stockAvailable;
      case PumpStatus.longQueue:
        return statusColors.longQueue;
      case PumpStatus.noStock:
        return statusColors.noStock;
      case PumpStatus.unverified:
        return statusColors.unverified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorFor(context, status);

    if (compact) {
      return Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.statusColors.tintFor(color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
