import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/badge_model.dart';
import '../../data/models/pump_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  UserViewModel(this._userRepository);

  final UserRepository _userRepository;

  // --- Profile ---------------------------------------------------------

  UserModel? _profile;
  bool _isLoadingProfile = false;
  String? _profileError;
  StreamSubscription<UserModel>? _profileSubscription;

  UserModel? get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  void watchProfile(String userId) {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    _profileSubscription?.cancel();
    _profileSubscription = _userRepository.watchUser(userId).listen(
      (user) {
        _profile = user;
        _isLoadingProfile = false;
        notifyListeners();
      },
      onError: (Object error) {
        _profileError = error.toString();
        _isLoadingProfile = false;
        notifyListeners();
      },
    );
  }

  bool _isSavingProfile = false;
  bool get isSavingProfile => _isSavingProfile;

  Future<bool> updateProfile(UserModel user) async {
    _isSavingProfile = true;
    notifyListeners();

    final result = await _userRepository.updateProfile(user);
    var success = false;

    result.when(
      success: (updated) {
        _profile = updated;
        success = true;
      },
      failure: (failure) => _profileError = failure.message,
    );

    _isSavingProfile = false;
    notifyListeners();
    return success;
  }

  Future<String?> uploadProfilePhoto(String userId, String localFilePath) async {
    final result =
        await _userRepository.uploadProfilePhoto(userId, localFilePath);
    return result.when(
      success: (url) => url,
      failure: (failure) {
        _profileError = failure.message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<bool> deleteAccountData(String userId) async {
    final result = await _userRepository.deleteUserData(userId);
    return result.when(
      success: (_) => true,
      failure: (failure) {
        _profileError = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  // --- Favourites --------------------------------------------------------

  List<PumpModel> _favouritePumps = [];
  bool _isLoadingFavourites = false;
  String? _favouritesError;
  StreamSubscription<List<PumpModel>>? _favouritesSubscription;

  List<PumpModel> get favouritePumps => _favouritePumps;
  bool get isLoadingFavourites => _isLoadingFavourites;
  String? get favouritesError => _favouritesError;

  void watchFavouritePumps(String userId) {
    _isLoadingFavourites = true;
    _favouritesError = null;
    notifyListeners();

    _favouritesSubscription?.cancel();
    _favouritesSubscription =
        _userRepository.watchFavouritePumps(userId).listen(
      (pumps) {
        _favouritePumps = pumps;
        _isLoadingFavourites = false;
        notifyListeners();
      },
      onError: (Object error) {
        _favouritesError = error.toString();
        _isLoadingFavourites = false;
        notifyListeners();
      },
    );
  }

  bool isFavourite(String pumpId) =>
      _profile?.favouritePumps.contains(pumpId) ?? false;

  Future<void> toggleFavourite(String userId, String pumpId) async {
    if (isFavourite(pumpId)) {
      await _userRepository.removeFavouritePump(userId, pumpId);
    } else {
      await _userRepository.addFavouritePump(userId, pumpId);
    }
    // watchProfile/watchFavouritePumps streams pick up the change on
    // their own next emission — no local optimistic state needed.
  }

  // --- Badges --------------------------------------------------------------

  List<BadgeModel> _badges = [];
  StreamSubscription<List<BadgeModel>>? _badgesSubscription;

  List<BadgeModel> get badges => _badges;

  void watchBadges(String userId) {
    _badgesSubscription?.cancel();
    _badgesSubscription = _userRepository.watchBadges(userId).listen(
      (badges) {
        _badges = badges;
        notifyListeners();
      },
      onError: (Object _) {
        // Badge load failures shouldn't block the rest of Profile —
        // the grid just stays empty/locked.
      },
    );
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _favouritesSubscription?.cancel();
    _badgesSubscription?.cancel();
    super.dispose();
  }
}
