import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/notification_model.dart';

/// CNG LIVE — Notification Remote Data Source
///
/// Owns every Firestore call against a driver's per-user notification
/// subcollection /notifications/{userId}/items/{notificationId} (Step
/// 22, Section 14). Mirrors StatusRemoteDataSource's contract: every
/// method returns a plain model/value or throws ServerException, never
/// Result<T>. Notification *creation* is a server-side (Cloud
/// Functions) concern per NotificationRepository's doc comment, so no
/// create method exists here.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _itemsRef(String userId) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .doc(userId)
        .collection(FirestorePaths.notificationItemsSubcollection);
  }

  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 20,
    NotificationModel? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _itemsRef(userId)
          .orderBy(FirestorePaths.fieldTimestamp, descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter.timestamp)]);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(NotificationModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    try {
      return _itemsRef(userId)
          .orderBy(FirestorePaths.fieldTimestamp, descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(NotificationModel.fromFirestore).toList());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<NotificationModel> getNotificationById(
    String userId,
    String notificationId,
  ) async {
    try {
      final doc = await _itemsRef(userId).doc(notificationId).get();
      if (!doc.exists) {
        throw ServerException('Notification not found');
      }
      return NotificationModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _itemsRef(userId)
          .doc(notificationId)
          .update({FirestorePaths.fieldIsRead: true});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _itemsRef(userId)
          .where(FirestorePaths.fieldIsRead, isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {FirestorePaths.fieldIsRead: true});
      }
      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _itemsRef(userId)
          .where(FirestorePaths.fieldIsRead, isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
