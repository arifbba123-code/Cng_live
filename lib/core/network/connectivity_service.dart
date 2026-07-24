import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// CNG LIVE — Connectivity Service
///
/// Wraps connectivity_plus to expose a simple online/offline stream and
/// snapshot check. Consumed by:
///   - Repositories, to decide remote-vs-cache / queue-write behavior
///     (Step 22, Section 13 offline-first architecture)
///   - ConnectivityViewModel, to drive the app-wide OfflineBanner widget
class ConnectivityService {
  ConnectivityService() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((results) => _controller.add(_hasConnection(results)));
  }

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  /// Emits `true` when online, `false` when offline.
  Stream<bool> get onStatusChange => _controller.stream;

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// One-off check — use when a repository needs a synchronous-ish
  /// decision before making a call, rather than subscribing to the stream.
  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return _hasConnection(results);
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
