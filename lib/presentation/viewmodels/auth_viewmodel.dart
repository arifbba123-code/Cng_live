import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Overall session state, driven by Firebase Auth + Firestore.
///
/// [unknown] is the brief window at app start while a previously
/// signed-in driver's profile is being restored (auto-login) — Home
/// is already on screen by then (main.dart routes on
/// [AuthRepository.isLoggedIn] synchronously), this just governs
/// when [user] becomes available.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository) {
    _restoreSession();
  }

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  /// Whether a driver is currently signed in with Firebase Auth —
  /// checked by the app's startup logic to decide /login vs /home.
  bool get isLoggedIn => _authRepository.isLoggedIn;

  /// Auto-login: if Firebase Auth already has a signed-in driver from
  /// a previous session, load their Firestore profile so the rest of
  /// the app (e.g. Update Status screen) has it without another sign-in.
  Future<void> _restoreSession() async {
    if (!_authRepository.isLoggedIn) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final result = await _authRepository.getCurrentUser();
    result.when(
      success: (user) {
        _user = user;
        _status = user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
        notifyListeners();
      },
      failure: (failure) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      },
    );
  }

  /// Signs an existing driver in with email & password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.signIn(email: email, password: password);
    var success = false;

    result.when(
      success: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        success = true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Registers a new driver with email & password, then signs them in.
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.register(
      email: email,
      password: password,
      name: name,
    );
    var success = false;

    result.when(
      success: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        success = true;
      },
      failure: (failure) {
        _errorMessage = failure.message;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Sends a password-reset email. Returns true on success.
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.sendPasswordResetEmail(email);
    var success = false;

    result.when(
      success: (_) => success = true,
      failure: (failure) => _errorMessage = failure.message,
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepository.logout();

    result.when(
      success: (_) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        _isLoading = false;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
    );
  }
}
