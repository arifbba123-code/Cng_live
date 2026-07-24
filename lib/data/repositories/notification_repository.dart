import '../../core/network/network_result.dart';
import '../models/notification_model.dart';

/// CNG LIVE — Notification Repository (Interface)
///
/// Defines the contract for reading and managing a driver's notification
/// list. Backs the Notifications screen (Step 18), reading from the
/// per-user subcollection /notifications/{userId}/items/{notificationId}
/// (Step 22, Section 14). Notification *creation* is a server-side
/// concern (Cloud Functions reacting to status updates, achievements,
/// points, and system announcements — Step 22, Section 14), so no
/// create/delete methods are exposed here; this repository is read +
/// read-state management only.
abstract class NotificationRepository {
  /// One-off paginated fetch, newest first — used for initial load and
  /// infinite scroll on the Notifications screen (Step 18).
  Future<Result<List<NotificationModel>>> getNotifications(
    String userId, {
    int limit = 20,
    NotificationModel? startAfter,
  });

  /// Live stream of the notification list — keeps the screen updated in
  /// real time as new notifications arrive (Step 18 "New notification
  /// arrives" live animation) without requiring a manual refresh.
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// Fetches a single notification by id — used when deep-linking from
  /// a push notification tap into the in-app Notifications list.
  Future<Result<NotificationModel>> getNotificationById(
    String userId,
    String notificationId,
  );

  /// Marks a single notification as read — triggered on tap (Step 18
  /// read/unread state, dot fade-out).
  Future<Result<void>> markAsRead(String userId, String notificationId);

  /// Marks every notification as read — powers the top-right "Mark all
  /// as read" action (Step 18), including its staggered fade animation
  /// once this completes.
  Future<Result<void>> markAllAsRead(String userId);

  /// Count of unread notifications — powers the red badge count on the
  /// bottom nav Alerts tab (Step 13) and the notification bell on Home
  /// Screen's top bar (Step 13).
  Future<Result<int>> getUnreadCount(String userId);
}
