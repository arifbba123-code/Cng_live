import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../datasources/remote/leaderboard_remote_datasource.dart';
import '../models/leaderboard_model.dart';
import 'leaderboard_repository.dart';

/// CNG LIVE — Leaderboard Repository (Implementation)
///
/// Delegates to LeaderboardRemoteDataSource, converting thrown
/// exceptions into typed Failures, mirroring every other
/// *RepositoryImpl in this codebase.
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._remoteDataSource);

  final LeaderboardRemoteDataSource _remoteDataSource;

  @override
  Stream<List<LeaderboardEntryModel>> watchLeaderboard({int limit = 10}) {
    return _remoteDataSource.watchLeaderboard(limit: limit).handleError((Object e) {
      throw ErrorHandler.handle(e, context: 'watchLeaderboard');
    });
  }

  @override
  Future<Result<LeaderboardEntryModel?>> getUserRank(String userId) async {
    try {
      final entry = await _remoteDataSource.getUserRank(userId);
      return Result.success(entry);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getUserRank'));
    }
  }
}
