import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../datasources/remote/badge_remote_datasource.dart';
import '../models/badge_model.dart';
import 'badge_repository.dart';

/// CNG LIVE — Badge Repository (Implementation)
///
/// Implements the approved BadgeRepository contract by delegating all
/// Firestore access to BadgeRemoteDataSource, mirroring
/// StatusRepositoryImpl's established pattern for converting thrown
/// exceptions into typed Failures.
///
/// SCOPE NOTE — unlockBadge(): the interface's doc comment says
/// unlocking a badge is "responsible for also triggering the
/// Achievement Unlocked notification". Per NotificationRepository's own
/// doc comment, notification *creation* is a server-side (Cloud
/// Functions) concern reacting to Firestore writes — this repository
/// only performs the client-side write (setting unlockedAt); the
/// notification itself is expected to be produced by a Cloud Function
/// watching /users/{userId}/badges/{badgeId}, not authored here.
class BadgeRepositoryImpl implements BadgeRepository {
  BadgeRepositoryImpl(this._remoteDataSource);

  final BadgeRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<BadgeModel>>> getBadges(String userId) async {
    try {
      final badges = await _remoteDataSource.getBadges(userId);
      return Result.success(badges);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getBadges'));
    }
  }

  @override
  Stream<List<BadgeModel>> watchBadges(String userId) {
    return _remoteDataSource.watchBadges(userId).handleError((Object e) {
      throw ErrorHandler.handle(e, context: 'watchBadges');
    });
  }

  @override
  Future<Result<BadgeModel>> getBadgeById(
    String userId,
    BadgeId badgeId,
  ) async {
    try {
      final badge = await _remoteDataSource.getBadgeById(userId, badgeId);
      return Result.success(badge);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getBadgeById'));
    }
  }

  @override
  Future<Result<BadgeModel>> updateBadgeProgress({
    required String userId,
    required BadgeId badgeId,
    required int progressCurrent,
  }) async {
    try {
      final badge = await _remoteDataSource.updateBadgeProgress(
        userId: userId,
        badgeId: badgeId,
        progressCurrent: progressCurrent,
      );
      return Result.success(badge);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'updateBadgeProgress'),
      );
    }
  }

  @override
  Future<Result<BadgeModel>> unlockBadge({
    required String userId,
    required BadgeId badgeId,
  }) async {
    try {
      final badge = await _remoteDataSource.unlockBadge(
        userId: userId,
        badgeId: badgeId,
      );
      return Result.success(badge);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'unlockBadge'));
    }
  }
}
