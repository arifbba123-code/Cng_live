import 'dart:async';

import '../core/logging/app_logger.dart';
import '../core/network/connectivity_service.dart';
import '../data/datasources/local/pending_updates_queue.dart';
import '../data/datasources/remote/status_remote_datasource.dart';

class SyncService {
  SyncService({
    required ConnectivityService connectivityService,
    required PendingUpdatesQueue pendingUpdatesQueue,
    required StatusRemoteDataSource statusRemoteDataSource,
  })  : _connectivityService = connectivityService,
        _pendingUpdatesQueue = pendingUpdatesQueue,
        _statusRemoteDataSource = statusRemoteDataSource;

  final ConnectivityService _connectivityService;
  final PendingUpdatesQueue _pendingUpdatesQueue;
  final StatusRemoteDataSource _statusRemoteDataSource;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  void start() {
    _connectivitySubscription ??=
        _connectivityService.onStatusChange.listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await _pendingUpdatesQueue.getAll();

      for (final update in pending) {
        try {
          await _statusRemoteDataSource.submitStatusUpdate(update);
          await _pendingUpdatesQueue.remove(update.id);
        } catch (e) {
          AppLogger.error('SyncService', e);
          // Continue with the next queued update even if this one
          // failed — it stays in the queue and is retried on the
          // next sync trigger.
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
