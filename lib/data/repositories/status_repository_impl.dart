import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../datasources/local/pending_updates_queue.dart';
import '../datasources/remote/status_remote_datasource.dart';
import '../models/status_update_model.dart';
import 'status_repository.dart';

/// CNG LIVE — Status Repository (Implementation)
///
/// Implements the approved StatusRepository contract by delegating all
/// Firestore access to StatusRemoteDataSource and all local-queue
/// state checks to PendingUpdatesQueue. This class has no Firebase
/// imports — it only orchestrates datasource calls and converts
/// thrown exceptions into typed Failures via ErrorHandler.handle(),
/// per Step 22's layering rule.
///
/// SCOPE NOTE — offline submission queueing: per your instruction to
/// keep offline queue logic separated from remote logic, this
/// implementation of submitStatusUpdate() delegates directly to
/// StatusRemoteDataSource (the online path) and does not itself decide
/// whether to queue offline. The full offline-first behavior described
/// in Step 22, Section 13 (silently queue when offline, auto-sync on
/// reconnect) requires a ConnectivityService check plus a queue *write*
/// path — that orchestration belongs in a dedicated sync
/// coordinator/use case that composes ConnectivityService (already
/// approved) with PendingUpdatesQueue (now implemented at
/// data/datasources/local/pending_updates_queue.dart), so it isn't
/// bolted onto this repository ad hoc. hasPendingUpdates() below reads
/// from that local queue directly, as requested; the write-side
/// queueing on submit remains a follow-up rather than guessed at here.
class StatusRepositoryImpl implements StatusRepository {
  StatusRepositoryImpl(this._remoteDataSource, this._pendingUpdatesQueue);

  final StatusRemoteDataSource _remoteDataSource;
  final PendingUpdatesQueue _pendingUpdatesQueue;

  @override
  Future<Result<StatusUpdateModel>> submitStatusUpdate(
    StatusUpdateModel update,
  ) async {
    try {
      final submitted = await _remoteDataSource.submitStatusUpdate(update);
      return Result.success(submitted);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'submitStatusUpdate'),
      );
    }
  }

  @override
  Stream<List<StatusUpdateModel>> watchStatusHistory(
    String pumpId, {
    int limit = 3,
  }) {
    return _remoteDataSource
        .watchStatusHistory(pumpId, limit: limit)
        .handleError((Object e) {
      // Streams can't carry Result<T> per the approved interface, so
      // exceptions are converted to a typed Failure and re-thrown on
      // the stream's error channel — mirrors PumpRepositoryImpl's
      // established pattern for its watch* methods.
      throw ErrorHandler.handle(e, context: 'watchStatusHistory');
    });
  }

  @override
  Future<Result<List<StatusUpdateModel>>> getFullStatusHistory(
    String pumpId, {
    int limit = 20,
    StatusUpdateModel? startAfter,
  }) async {
    try {
      final history = await _remoteDataSource.getFullStatusHistory(
        pumpId,
        limit: limit,
        startAfter: startAfter,
      );
      return Result.success(history);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'getFullStatusHistory'),
      );
    }
  }

  @override
  Future<Result<List<StatusUpdateModel>>> getUserContributions(
    String userId, {
    int limit = 20,
    StatusUpdateModel? startAfter,
  }) async {
    try {
      final contributions = await _remoteDataSource.getUserContributions(
        userId,
        limit: limit,
        startAfter: startAfter,
      );
      return Result.success(contributions);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'getUserContributions'),
      );
    }
  }

  @override
  Future<bool> hasPendingUpdates() {
    // Local-only check — never touches Firestore, per the approved
    // StatusRepository interface's doc comment on this method.
    return _pendingUpdatesQueue.hasPending();
  }
}
