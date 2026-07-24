import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../datasources/remote/notification_remote_datasource.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

/// CNG LIVE — Notification Repository (Implementation)
///
/// Implements the approved NotificationRepository contract by
/// delegating all Firestore access to NotificationRemoteDataSource,
/// mirroring StatusRepositoryImpl's established pattern for converting
/// thrown exceptions into typed Failures.
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<NotificationModel>>> getNotifications(
    String userId, {
    int limit = 20,
    NotificationModel? startAfter,
  }) async {
    try {
      final notifications = await _remoteDataSource.getNotifications(
        userId,
        limit: limit,
        startAfter: startAfter,
      );
      return Result.success(notifications);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'getNotifications'),
      );
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _remoteDataSource.watchNotifications(userId).handleError((Object e) {
      // Streams can't carry Result<T>, so exceptions are converted to a
      // typed Failure and re-thrown — mirrors
      // StatusRepositoryImpl.watchStatusHistory's established pattern.
      throw ErrorHandler.handle(e, context: 'watchNotifications');
    });
  }

  @override
  Future<Result<NotificationModel>> getNotificationById(
    String userId,
    String notificationId,
  ) async {
    try {
      final notification =
          await _remoteDataSource.getNotificationById(userId, notificationId);
      return Result.success(notification);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'getNotificationById'),
      );
    }
  }

  @override
  Future<Result<void>> markAsRead(String userId, String notificationId) async {
    try {
      await _remoteDataSource.markAsRead(userId, notificationId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'markAsRead'));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _remoteDataSource.markAllAsRead(userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'markAllAsRead'));
    }
  }

  @override
  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      final count = await _remoteDataSource.getUnreadCount(userId);
      return Result.success(count);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getUnreadCount'));
    }
  }
}
