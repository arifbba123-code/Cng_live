import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/badge_model.dart';

/// CNG LIVE — Badge Remote Data Source
///
/// Owns every Firestore call against a driver's per-user badge
/// earned-state subcollection /users/{userId}/badges/{badgeId} (see
/// BadgeModel's doc comment for why the catalog itself is code-defined
/// rather than a Firestore collection). Mirrors StatusRemoteDataSource's
/// contract: every method returns a plain model/value or throws
/// ServerException, never Result<T>.
class BadgeRemoteDataSource {
  BadgeRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _badgesRef(String userId) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .collection(FirestorePaths.badgesSubcollection);
  }

  Future<List<BadgeModel>> getBadges(String userId) async {
    try {
      final snapshot = await _badgesRef(userId).get();
      return snapshot.docs.map(BadgeModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Stream<List<BadgeModel>> watchBadges(String userId) {
    try {
      return _badgesRef(userId).snapshots().map(
          (snapshot) => snapshot.docs.map(BadgeModel.fromFirestore).toList());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<BadgeModel> getBadgeById(String userId, BadgeId badgeId) async {
    try {
      final doc = await _badgesRef(userId).doc(badgeId.name).get();
      if (!doc.exists) {
        // A badge a driver hasn't made any progress on yet simply has
        // no document — surface that as a fresh, locked BadgeModel
        // rather than a failure, since "not started" is a valid state.
        return BadgeModel(id: badgeId, unlockedAt: null, progressCurrent: 0);
      }
      return BadgeModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<BadgeModel> updateBadgeProgress({
    required String userId,
    required BadgeId badgeId,
    required int progressCurrent,
  }) async {
    try {
      final docRef = _badgesRef(userId).doc(badgeId.name);
      await docRef.set(
        {'progressCurrent': progressCurrent},
        SetOptions(merge: true),
      );
      final doc = await docRef.get();
      return BadgeModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<BadgeModel> unlockBadge({
    required String userId,
    required BadgeId badgeId,
  }) async {
    try {
      final docRef = _badgesRef(userId).doc(badgeId.name);
      await docRef.set(
        {'unlockedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
      final doc = await docRef.get();
      return BadgeModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
