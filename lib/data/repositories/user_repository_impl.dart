import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../datasources/remote/badge_remote_datasource.dart';
import '../datasources/remote/pump_remote_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';
import '../models/badge_model.dart';
import '../models/pump_model.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// CNG LIVE — User Repository (Implementation)
///
/// Implements the approved UserRepository contract. Delegates profile
/// CRUD and favourites-array mutations to UserRemoteDataSource, and
/// composes PumpRemoteDataSource / BadgeRemoteDataSource to resolve the
/// id-only data UserRemoteDataSource stores into full model objects —
/// this composition is repository-layer responsibility, not something
/// bolted onto UserRemoteDataSource itself, matching how
/// StatusRepositoryImpl composes StatusRemoteDataSource with
/// PendingUpdatesQueue.
///
/// SCOPE NOTE — watchFavouritePumps(): resolves the current favourites
/// list into pump objects with a one-off fetch per emission of the
/// user's favourites array, rather than a fully live per-pump stream.
/// A driver's own status updates in the app do change the pumps in
/// range, but this keeps the join simple for the MVP; upgrading each
/// resolved pump to its own live snapshot stream is a documented
/// follow-up rather than guessed at here.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(
    this._remoteDataSource,
    this._pumpRemoteDataSource,
    this._badgeRemoteDataSource,
  );

  final UserRemoteDataSource _remoteDataSource;
  final PumpRemoteDataSource _pumpRemoteDataSource;
  final BadgeRemoteDataSource _badgeRemoteDataSource;

  @override
  Stream<UserModel> watchUser(String userId) {
    return _remoteDataSource.watchUser(userId).handleError((Object e) {
      throw ErrorHandler.handle(e, context: 'watchUser');
    });
  }

  @override
  Future<Result<UserModel>> getUserById(String userId) async {
    try {
      final user = await _remoteDataSource.getUserById(userId);
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getUserById'));
    }
  }

  @override
  Future<Result<UserModel>> createUser(UserModel user) async {
    try {
      final created = await _remoteDataSource.createUser(user);
      return Result.success(created);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'createUser'));
    }
  }

  @override
  Future<Result<UserModel>> updateProfile(UserModel user) async {
    try {
      final updated = await _remoteDataSource.updateProfile(user);
      return Result.success(updated);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'updateProfile'));
    }
  }

  @override
  Future<Result<String>> uploadProfilePhoto(
    String userId,
    String localFilePath,
  ) async {
    try {
      final url =
          await _remoteDataSource.uploadProfilePhoto(userId, localFilePath);
      return Result.success(url);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'uploadProfilePhoto'),
      );
    }
  }

  @override
  Future<Result<void>> addFavouritePump(String userId, String pumpId) async {
    try {
      await _remoteDataSource.addFavouritePump(userId, pumpId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'addFavouritePump'),
      );
    }
  }

  @override
  Future<Result<void>> removeFavouritePump(
    String userId,
    String pumpId,
  ) async {
    try {
      await _remoteDataSource.removeFavouritePump(userId, pumpId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'removeFavouritePump'),
      );
    }
  }

  @override
  Stream<List<PumpModel>> watchFavouritePumps(String userId) {
    return _remoteDataSource.watchUser(userId).asyncMap((user) async {
      final results = await Future.wait(
        user.favouritePumps.map((pumpId) async {
          try {
            return await _pumpRemoteDataSource.getPumpById(pumpId);
          } catch (_) {
            // A favourited pump that's since been removed shouldn't
            // break the whole list — skip it rather than failing the
            // stream (null filtered out below).
            return null;
          }
        }),
      );
      return results.whereType<PumpModel>().toList();
    }).handleError((Object e) {
      throw ErrorHandler.handle(e, context: 'watchFavouritePumps');
    });
  }

  @override
  Stream<List<BadgeModel>> watchBadges(String userId) {
    return _badgeRemoteDataSource.watchBadges(userId).handleError((Object e) {
      throw ErrorHandler.handle(e, context: 'watchBadges');
    });
  }

  @override
  Future<Result<void>> deleteUserData(String userId) async {
    try {
      await _remoteDataSource.deleteUserData(userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'deleteUserData'));
    }
  }
}
