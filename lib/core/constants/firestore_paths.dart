/// CNG LIVE — Firestore Collection & Field Name Constants
///
/// Matches the approved Firestore structure (Step 22, Section 14).
/// Never hardcode a collection/field string literal in a datasource —
/// reference these constants so a schema rename is a one-file change.
class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String users = 'users';
  static const String pumps = 'pumps';
  static const String statusUpdates = 'statusUpdates';
  static const String reports = 'reports';
  static const String leaderboard = 'leaderboard';
  static const String notifications = 'notifications';

  // Subcollections
  static const String statusHistorySubcollection = 'statusHistory';
  static const String notificationItemsSubcollection = 'items';

  // Common field names
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldLastUpdatedAt = 'lastUpdatedAt';
  static const String fieldLatitude = 'latitude';
  static const String fieldLongitude = 'longitude';
  static const String fieldCurrentStatus = 'currentStatus';
  static const String fieldVerified = 'verified';
  static const String fieldUserId = 'userId';
  static const String fieldPumpId = 'pumpId';
  static const String fieldIsRead = 'isRead';
  static const String fieldIsFlagged = 'isFlagged';
}
