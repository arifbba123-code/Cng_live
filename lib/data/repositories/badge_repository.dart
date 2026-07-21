import '../../core/network/network_result.dart';
import '../models/badge_model.dart';

/// CNG LIVE — Badge Repository (Interface)
///
/// Defines the contract for reading and updating a driver's badge
/// unlock-state records at /users/{userId}/badges/{badgeId} (Step 22,
/// Section 14; badge storage design approved alongside BadgeModel).
/// The static badge catalog itself (names/descriptions/icons/thresholds)
/// is code-defined in BadgeCatalog and is not part of this repository's
/// contract — this repository only ever reads/writes per-user earned
/// state, exactly as BadgeModel.fromFirestore/toFirestore expect.
abstract class BadgeRepository {
  /// One-off fetch of a driver's earned-state records for all badges
  /// they've made progress on or unlocked — merged by the ViewModel
  /// against BadgeCatalog.all to render the full locked/unlocked grid
  /// (Step 16 Achievement Badges).
  Future<Result<List<BadgeModel>>> getBadges(String userId);

  /// Live stream of the same data — keeps Profile's badge row updating
  /// in real time as progress changes (e.g. right after a status update
  /// pushes progressCurrent closer to a badge's targetValue).
  Stream<List<BadgeModel>> watchBadges(String userId);

  /// Fetches a single badge's earned-state record — used by the badge
  /// detail tooltip/modal (Step 16, tapping a badge tile).
  Future<Result<BadgeModel>> getBadgeById(String userId, BadgeId badgeId);

  /// Updates progressCurrent toward a badge's target without unlocking
  /// it — called after actions that count toward a badge (e.g. each
  /// status update submission incrementing progress toward the "100
  /// Updates Club" badge).
  Future<Result<BadgeModel>> updateBadgeProgress({
    required String userId,
    required BadgeId badgeId,
    required int progressCurrent,
  });

  /// Marks a badge as unlocked (sets unlockedAt) once its target is
  /// reached — the implementation is responsible for also triggering
  /// the "Achievement Unlocked" notification (Step 18, NotificationType
  /// .achievement) as part of this same logical operation.
  Future<Result<BadgeModel>> unlockBadge({
    required String userId,
    required BadgeId badgeId,
  });
}
