import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/pump_model.dart';

/// CNG LIVE — Pump Remote Data Source
///
/// Owns every Firestore call needed for pump list/detail/search access
/// (Step 22, Section 14 structure). Mirrors AuthRemoteDataSource's
/// contract: every method returns a plain model/value or throws a
/// typed exception (ServerException) from core/errors/exceptions.dart
/// — never a Result<T>, and never any business logic. Repositories
/// never talk to Firebase directly; this is the only place in the app
/// that imports cloud_firestore for pump data.
///
/// SCOPE NOTE: per the approved MVP decision, this datasource performs
/// only the Firestore bounding-box query for "nearby" pumps — it does
/// NOT calculate exact straight-line distance, filter to the precise
/// radius, or sort by distance. That trimming/sorting is business
/// logic and belongs one layer up, in PumpRepositoryImpl, using
/// DistanceCalculator (core/utils). This datasource stays a dumb data
/// pipe: given a bounding box, return what Firestore has in it.
class PumpRemoteDataSource {
  PumpRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _pumpsRef =>
      _firestore.collection(FirestorePaths.pumps);

  /// TEMPORARY DIAGNOSTIC — not part of the approved architecture.
  /// Fetches every /pumps doc with NO filters at all and prints the
  /// raw field values AND their runtimeType. This exists specifically
  /// to distinguish "field is a String that looks like a number"
  /// (e.g. "19.0760") from an actual Firestore `number` type, because
  /// debugPrint(value) renders both identically and the bounding-box
  /// query silently returns zero matches for either, with no error.
  /// Remove this method once the root cause is confirmed.
  Future<void> debugDumpAllPumpsRaw() async {
    final snapshot = await _pumpsRef.get();
    debugPrint(
      '[PumpRemoteDataSource][DIAGNOSTIC] total docs in /pumps '
      '(no filter) = ${snapshot.docs.length}',
    );
    for (final doc in snapshot.docs) {
      final data = doc.data();
      debugPrint(
        '[PumpRemoteDataSource][DIAGNOSTIC] doc.id=${doc.id} raw data=$data',
      );
      debugPrint(
        '[PumpRemoteDataSource][DIAGNOSTIC]   latitude value='
        '${data[FirestorePaths.fieldLatitude]} '
        'runtimeType=${data[FirestorePaths.fieldLatitude]?.runtimeType}',
      );
      debugPrint(
        '[PumpRemoteDataSource][DIAGNOSTIC]   longitude value='
        '${data[FirestorePaths.fieldLongitude]} '
        'runtimeType=${data[FirestorePaths.fieldLongitude]?.runtimeType}',
      );
    }
  }

  /// Live stream of pumps whose lat/lng fall within the given bounding
  /// box. This is a coarse rectangular filter, not a true radius —
  /// PumpRepositoryImpl narrows this down to an exact circle using
  /// DistanceCalculator after receiving each emission.
  Stream<List<PumpModel>> watchPumpsInBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    try {
      debugPrint(
        '[PumpRemoteDataSource] bounding box: '
        'minLat=$minLat, maxLat=$maxLat, minLng=$minLng, maxLng=$maxLng',
      );

      return _pumpsRef
          .where(FirestorePaths.fieldLatitude, isGreaterThanOrEqualTo: minLat)
          .where(FirestorePaths.fieldLatitude, isLessThanOrEqualTo: maxLat)
          .snapshots()
          .map((snapshot) {
        debugPrint(
          '[PumpRemoteDataSource] snapshot.docs.length = ${snapshot.docs.length}',
        );

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final lat = (data[FirestorePaths.fieldLatitude] as num?)?.toDouble();
          final lng =
              (data[FirestorePaths.fieldLongitude] as num?)?.toDouble();
          debugPrint(
            '[PumpRemoteDataSource] doc.id=${doc.id} '
            'latitude=$lat longitude=$lng',
          );
        }

        // Longitude range is filtered client-side since Firestore
        // only allows range (>=/<=) filters on a single field per
        // query — latitude already claims that slot above.
        final filteredDocs = snapshot.docs.where((doc) {
          final lng = (doc.data()[FirestorePaths.fieldLongitude] as num?)
                  ?.toDouble() ??
              0.0;
          return lng >= minLng && lng <= maxLng;
        }).toList();

        debugPrint(
          '[PumpRemoteDataSource] after longitude filter, '
          'remaining count = ${filteredDocs.length}',
        );

        return filteredDocs.map((doc) => PumpModel.fromFirestore(doc)).toList();
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Live stream of every pump document in /pumps, with no bounding-box
  /// or radius filtering at all. Powers the Home Screen map view (Step
  /// 23), which shows every pump on the map regardless of distance —
  /// unlike watchNearbyPumps, which exists specifically to narrow the
  /// list view down to what's close to the driver.
  Stream<List<PumpModel>> watchAllPumps() {
    try {
      return _pumpsRef.snapshots().map(
            (snapshot) =>
                snapshot.docs.map((doc) => PumpModel.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Live stream of a single pump document — powers Pump Detail's live
  /// status card without a manual refresh.
  Stream<PumpModel> watchPumpById(String pumpId) {
    try {
      return _pumpsRef
          .doc(pumpId)
          .snapshots()
          .map((doc) => PumpModel.fromFirestore(doc));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<PumpModel> getPumpById(String pumpId) async {
    try {
      final doc = await _pumpsRef.doc(pumpId).get();
      if (!doc.exists) {
        throw ServerException('Pump not found: $pumpId');
      }
      return PumpModel.fromFirestore(doc);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Prefix search on pump name, e.g. typing "Sri" matches "Sri Balaji
  /// CNG Station". Firestore has no native full-text search, so this
  /// uses the standard range-query prefix trick
  /// (name >= query && name <= query + '\uf8ff').
  Future<List<PumpModel>> searchPumps(String query) async {
    try {
      final snapshot = await _pumpsRef
          .orderBy('name')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return snapshot.docs.map((doc) => PumpModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Bounding-box query with optional status/verified equality filters
  /// applied server-side. Like [watchPumpsInBoundingBox], longitude and
  /// distance narrowing still happen one layer up in the repository.
  Future<List<PumpModel>> filterPumpsInBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? statusValue,
    bool? verifiedOnly,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _pumpsRef
          .where(FirestorePaths.fieldLatitude, isGreaterThanOrEqualTo: minLat)
          .where(FirestorePaths.fieldLatitude, isLessThanOrEqualTo: maxLat);

      if (statusValue != null) {
        query = query.where(FirestorePaths.fieldCurrentStatus,
            isEqualTo: statusValue);
      }
      if (verifiedOnly == true) {
        query = query.where(FirestorePaths.fieldVerified, isEqualTo: true);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .where((doc) {
            final lng =
                (doc.data()[FirestorePaths.fieldLongitude] as num?)
                        ?.toDouble() ??
                    0.0;
            return lng >= minLng && lng <= maxLng;
          })
          .map((doc) => PumpModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
