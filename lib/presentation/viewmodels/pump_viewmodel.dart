import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/pump_model.dart';
import '../../data/models/status_update_model.dart';
import '../../data/repositories/pump_repository.dart';
import '../../data/repositories/status_repository.dart';

class PumpViewModel extends ChangeNotifier {
  PumpViewModel(this._pumpRepository, this._statusRepository);

  final PumpRepository _pumpRepository;
  final StatusRepository _statusRepository;

  // --- Nearby pumps (Home Screen) ---------------------------------------

  List<PumpModel> _nearbyPumps = [];
  bool _isLoadingNearby = false;
  String? _nearbyError;
  StreamSubscription<List<PumpModel>>? _nearbySubscription;

  List<PumpModel> get nearbyPumps => _nearbyPumps;
  bool get isLoadingNearby => _isLoadingNearby;
  String? get nearbyError => _nearbyError;

  void watchNearbyPumps({
    required double latitude,
    required double longitude,
    double radiusKm = 150,
  }) {
    _isLoadingNearby = true;
    _nearbyError = null;
    notifyListeners();

    _nearbySubscription?.cancel();
    _nearbySubscription = _pumpRepository
        .watchNearbyPumps(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    )
        .listen(
      (pumps) {
        _nearbyPumps = pumps;
        _isLoadingNearby = false;
        notifyListeners();
      },
      onError: (Object error) {
        _nearbyError = error.toString();
        _isLoadingNearby = false;
        notifyListeners();
      },
    );
  }

  // --- All pumps (Home Screen map view) -----------------------------------

  List<PumpModel> _allPumps = [];
  bool _isLoadingAllPumps = false;
  String? _allPumpsError;
  StreamSubscription<List<PumpModel>>? _allPumpsSubscription;

  List<PumpModel> get allPumps => _allPumps;
  bool get isLoadingAllPumps => _isLoadingAllPumps;
  String? get allPumpsError => _allPumpsError;

  /// Starts (or restarts) the live stream of every pump in /pumps, used
  /// to plot markers on the Home Screen map. Safe to call more than
  /// once — e.g. if the map tab is re-entered — since it cancels any
  /// existing subscription first rather than stacking listeners.
  void watchAllPumps() {
    if (_allPumpsSubscription != null) return;

    _isLoadingAllPumps = true;
    _allPumpsError = null;
    notifyListeners();

    _allPumpsSubscription = _pumpRepository.watchAllPumps().listen(
      (pumps) {
        _allPumps = pumps;
        _isLoadingAllPumps = false;
        notifyListeners();
      },
      onError: (Object error) {
        _allPumpsError = error.toString();
        _isLoadingAllPumps = false;
        notifyListeners();
      },
    );
  }

  // --- Search --------------------------------------------------------------

  List<PumpModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  List<PumpModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  Future<void> searchPumps(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    final result = await _pumpRepository.searchPumps(query);

    result.when(
      success: (pumps) {
        _searchResults = pumps;
        _isSearching = false;
        notifyListeners();
      },
      failure: (failure) {
        _searchError = failure.message;
        _isSearching = false;
        notifyListeners();
      },
    );
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  // --- Pump Detail (live status + history) ---------------------------------

  PumpModel? _selectedPump;
  bool _isLoadingDetail = false;
  String? _detailError;
  StreamSubscription<PumpModel>? _pumpDetailSubscription;

  List<StatusUpdateModel> _statusHistory = [];
  StreamSubscription<List<StatusUpdateModel>>? _historySubscription;

  PumpModel? get selectedPump => _selectedPump;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;
  List<StatusUpdateModel> get statusHistory => _statusHistory;

  void watchPumpDetail(String pumpId) {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    _pumpDetailSubscription?.cancel();
    _pumpDetailSubscription = _pumpRepository.watchPumpById(pumpId).listen(
      (pump) {
        _selectedPump = pump;
        _isLoadingDetail = false;
        notifyListeners();
      },
      onError: (Object error) {
        _detailError = error.toString();
        _isLoadingDetail = false;
        notifyListeners();
      },
    );

    _historySubscription?.cancel();
    _historySubscription =
        _statusRepository.watchStatusHistory(pumpId, limit: 3).listen(
      (history) {
        _statusHistory = history;
        notifyListeners();
      },
      onError: (Object error) {
        _detailError = error.toString();
        notifyListeners();
      },
    );
  }

  void clearSelectedPump() {
    _pumpDetailSubscription?.cancel();
    _historySubscription?.cancel();
    _selectedPump = null;
    _statusHistory = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _nearbySubscription?.cancel();
    _allPumpsSubscription?.cancel();
    _pumpDetailSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
