import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/status_update_model.dart';

/// CNG LIVE — Status Remote Data Source
///
/// Owns every Firestore call needed for submitting and reading status
/// updates (Step 22, Section 14 structure). Mirrors
/// AuthRemoteDataSource / PumpRemoteDataSource's contract: every method
/// returns a plain model/value or throws a typed exception
/// (ServerException) — never a Result<T>, and never business logic
/// (offline queueing, retry, staleness rules, etc. all live one layer
/// up in StatusRepositoryImpl). Repositories never talk to Firebase
/// directly; this is the only place in the app that imports
/// cloud_firestore for status update data.
///
/// SCOPE NOTE: [submitStatusUpdate] writes to both locations the
/// approved schema requires (Step 22, Section 14) — the per-pump
/// statusHistory subcollection AND the flat statusUpdates mirror —
/// using a single WriteBatch so both documents are created atomically
/// under the same id. This is schema mechanics (fulfilling the already
/// -approved dual-write structure), not business logic: it does not
/// decide *whether* to submit, retry, queue offline, or touch the
/// parent pump's currentStatus field (that update is owned by a
/// server-side Cloud Function per Step 22, Section 14 — not this
/// datasource).
class StatusRemoteDataSource {
  StatusRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _statusHistoryRef(String pumpId) {
    return _firestore
        .collection(FirestorePaths.pumps)
        .doc(pumpId)
        .collection(FirestorePaths.statusHistorySubcollection);
  }

  CollectionReference<Map<String, dynamic>> get _statusUpdatesRef =>
      _firestore.collection(FirestorePaths.statusUpdates);

  /// Writes the update to /pumps/{pumpId}/statusHistory/{id} and
  /// /statusUpdates/{id} in one batch, using the same generated id for
  /// both documents so the two locations stay trivially joinable.
  Future<StatusUpdateModel> submitStatusUpdate(
    StatusUpdateModel update,
  ) async {
    try {
      final docId = _statusHistoryRef(update.pumpId).doc().id;
      final data = update.toFirestore();

      final batch = _firestore.batch();
      batch.set(_statusHistoryRef(update.pumpId).doc(docId), data);
      batch.set(_statusUpdatesRef.doc(docId), data);
      await batch.commit();

      return StatusUpdateModel(
        id: docId,
        pumpId: update.pumpId,
        userId: update.userId,
        userName: update.userName,
        status: update.status,
        queueLength: update.queueLength,
        photo: update.photo,
        timestamp: update.timestamp,
        isFlagged: update.isFlagged,
        gpsVerified: update.gpsVerified,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Live stream of the most recent updates for one pump, newest first.
  Stream<List<StatusUpdateModel>> watchStatusHistory(
    String pumpId, {
    int limit = 3,
  }) {
    try {
      return _statusHistoryRef(pumpId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) =>
                  StatusUpdateModel.fromFirestore(doc, pumpId: pumpId))
              .toList());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// One-off paginated fetch of a pump's full status history.
  Future<List<StatusUpdateModel>> getFullStatusHistory(
    String pumpId, {
    int limit = 20,
    StatusUpdateModel? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _statusHistoryRef(pumpId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter.timestamp)]);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => StatusUpdateModel.fromFirestore(doc, pumpId: pumpId))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// One-off paginated fetch of a single driver's own contribution
  /// history, newest first, from the flat statusUpdates mirror.
  Future<List<StatusUpdateModel>> getUserContributions(
    String userId, {
    int limit = 20,
    StatusUpdateModel? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _statusUpdatesRef
          .where(FirestorePaths.fieldUserId, isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter.timestamp)]);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => StatusUpdateModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
