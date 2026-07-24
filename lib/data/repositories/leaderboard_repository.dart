import '../../core/network/network_result.dart';
import '../models/leaderboard_model.dart';

/// CNG LIVE — Leaderboard Repository (Interface)
///
/// Defines the contract for reading the weekly rankings collection.
/// Read-only, mirroring NotificationRepository's own read-only
/// contract — ranking computation is a server-side (Cloud Functions)
/// concern reacting to points/reputation changes.
abstract class LeaderboardRepository {
  /// Live top-N leaderboard, ordered by rank ascending.
  Stream<List<LeaderboardEntryModel>> watchLeaderboard({int limit = 10});

  /// The current driver's own entry, even if outside the top N — used
  /// for a "Your Rank" sticky card (Step 20, Section elevation
  /// level2). Returns null if the driver has no entry yet (e.g. new
  /// account with no ranked activity this week).
  Future<Result<LeaderboardEntryModel?>> getUserRank(String userId);
}
