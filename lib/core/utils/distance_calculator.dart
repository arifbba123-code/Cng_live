import 'dart:math';

/// CNG LIVE — Distance Calculation
///
/// Haversine formula for straight-line distance between the driver's
/// current location and a pump's coordinates. Used on Home Screen pump
/// cards and Pump Detail's "2.3 km away" label.
///
/// NOTE: This is straight-line distance, not driving distance. Google
/// Maps navigation (via url_launcher) will show the real route distance
/// once the driver taps Navigate — this is only for quick sort/display.
class DistanceCalculator {
  DistanceCalculator._();

  static const double _earthRadiusKm = 6371.0;

  /// Returns distance in kilometers between two lat/lng points.
  static double distanceInKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);

  /// Formats a distance for display: "850 m" if under 1km, else "2.3 km".
  static String format(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
