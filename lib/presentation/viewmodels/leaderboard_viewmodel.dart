import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/leaderboard_model.dart';
import '../../data/repositories/leaderboard_repository.dart';

class LeaderboardViewModel extends ChangeNotifier {
  LeaderboardViewModel(this._leaderboardRepository);

  final LeaderboardRepository _leaderboardRepository;

  List<LeaderboardEntryModel> _entries = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<LeaderboardEntryModel>>? _subscription;

  LeaderboardEntryModel? _myRank;

  List<LeaderboardEntryModel> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LeaderboardEntryModel? get myRank => _myRank;

  void watchLeaderboard({int limit = 10}) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription =
        _leaderboardRepository.watchLeaderboard(limit: limit).listen(
      (entries) {
        _entries = entries;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadMyRank(String userId) async {
    final result = await _leaderboardRepository.getUserRank(userId);
    result.when(
      success: (entry) {
        _myRank = entry;
        notifyListeners();
      },
      failure: (_) {
        // Own-rank lookup failing shouldn't block the top-N list.
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
