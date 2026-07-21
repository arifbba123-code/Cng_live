import 'dart:math';

import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../../core/utils/distance_calculator.dart';
import '../datasources/remote/pump_remote_datasource.dart';
import '../models/pump_model.dart';
import 'pump_repository.dart';

/// CNG LIVE — Pump Repository (Implementation)
///
/// Implements the approved PumpRepository contract by delegating all
/// Firestore access to PumpRemoteDataSource and layering the
/// business logic that datasource intentionally does NOT own:
///   - converting a (latitude, longitude, radiusKm) point into the
///     rectangular bounding box the datasource queries against
///   - trimming the datasource's coarse rectangular results down to
///     the exact circular radius using DistanceCalculator
///   - sorting the final list by distance, nearest first
///
/// This class has no Firebase imports — it only depends on
/// PumpRemoteDataSource and converts thrown exceptions into typed
/// Failures via ErrorHandler.handle(), per Step 22's layering rule.
class PumpRepositoryImpl implements PumpRepository {
  PumpRepositoryImpl(this._remoteDataSource);

  final PumpRemoteDataSource _remoteDataSource;

  /// Approximate degrees-of-latitude per kilometer — constant
  /// worldwide, since lines of latitude are evenly spaced.
  static const double _kmPerDegreeLat = 110.574;

  /// Converts a center point + radius into a rectangular bounding box.
  /// Longitude degrees-per-km shrinks toward the poles, so it's scaled
  /// by cos(latitude) — standard equirectangular approximation, more
  /// than accurate enough for a single-city radius search.
  ({double minLat, double maxLat, double minLng, double maxLng})
      _boundingBoxFor({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    final latDelta = radiusKm / _kmPerDegreeLat;
    final kmPerDegreeLng = _kmPerDegreeLat * cos(latitude * pi / 180);
    final lngDelta = kmPerDegreeLng == 0 ? 180.0 : radiusKm / kmPerDegreeLng;

    return (
      minLat: latitude - latDelta,
      maxLat: latitude + latDelta,
      minLng: longitude - lngDelta,
      maxLng: longitude + lngDelta,
    );
  }

  /// Trims a bounding-box result set down to the exact circular
  /// radius and sorts nearest-first, using the shared
  /// DistanceCalculator utility (core/utils) — the same one used to
  /// render "2.3 km away" on pump cards, so distance figures stay
  /// consistent between filtering and display.
  List<PumpModel> _filterAndSortByRadius(
    List<PumpModel> pumps, {
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    final withDistance = pumps
        .map((pump) => (
              pump: pump,
              distanceKm: DistanceCalculator.distanceInKm(
                lat1: latitude,
                lon1: longitude,
                lat2: pump.latitude,
                lon2: pump.longitude,
              ),
            ))
        .where((entry) => entry.distanceKm <= radiusKm)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return withDistance.map((entry) => entry.pump).toList();
  }

  @override
  Stream<List<PumpModel>> watchNearbyPumps({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) {
    final box = _boundingBoxFor(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    return _remoteDataSource
        .watchPumpsInBoundingBox(
          minLat: box.minLat,
          maxLat: box.maxLat,
          minLng: box.minLng,
          maxLng: box.maxLng,
        )
        .map((pumps) => _filterAndSortByRadius(
              pumps,
              latitude: latitude,
              longitude: longitude,
              radiusKm: radiusKm,
            ))
        .handleError((Object e) {
      // Streams can't carry Result<T> per the approved interface, so
      // exceptions are converted to a typed Failure and re-thrown on
      // the stream's error channel — callers catch it via
      // stream.listen(onError: ...) and receive the same Failure
      // vocabulary used everywhere else in the app.
      throw ErrorHandler.handle(e, context: 'watchNearbyPumps');
    });
  }

  @override
  Stream<PumpModel> watchPumpById(String pumpId) {
    return _remoteDataSource.watchPumpById(pumpId).handleError((Object e) {
      throw ErrorHandler.handle(e, context: 'watchPumpById');
    });
  }

  @override
  Future<Result<PumpModel>> getPumpById(String pumpId) async {
    try {
      final pump = await _remoteDataSource.getPumpById(pumpId);
      return Result.success(pump);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getPumpById'));
    }
  }

  @override
  Future<Result<List<PumpModel>>> searchPumps(String query) async {
    try {
      final pumps = await _remoteDataSource.searchPumps(query);
      return Result.success(pumps);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'searchPumps'));
    }
  }

  @override
  Future<Result<List<PumpModel>>> filterPumps({
    PumpStatus? status,
    bool? verifiedOnly,
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      final box = _boundingBoxFor(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      final pumps = await _remoteDataSource.filterPumpsInBoundingBox(
        minLat: box.minLat,
        maxLat: box.maxLat,
        minLng: box.minLng,
        maxLng: box.maxLng,
        statusValue: status?.toFirestoreValue(),
        verifiedOnly: verifiedOnly,
      );

      final filtered = _filterAndSortByRadius(
        pumps,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      return Result.success(filtered);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'filterPumps'));
    }
  }
}
