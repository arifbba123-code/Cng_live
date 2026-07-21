import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStep { enterPhone, otpSent, verified }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository);

  final AuthRepository _authRepository;

  AuthStep _step = AuthStep.enterPhone;
  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';
  String? _verificationId;
  UserModel? _user;

  AuthStep get step => _step;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get phoneNumber => _phoneNumber;
  UserModel? get user => _user;
  bool get isNewUser => _user != null && _user!.name.isEmpty;

  Future<void> sendOtp(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.sendOtp(phoneNumber);

    result.when(
      success: (verificationId) {
        _verificationId = verificationId;
        _step = AuthStep.otpSent;
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

  Future<void> resendOtp() async {
    if (_phoneNumber.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.resendOtp(_phoneNumber);

    result.when(
      success: (verificationId) {
        _verificationId = verificationId;
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

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null) {
      _errorMessage = 'OTP session expired. Please request a new one.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.verifyOtp(
      verificationId: _verificationId!,
      otp: otp,
    );

    result.when(
      success: (user) {
        _user = user;
        _step = AuthStep.verified;
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

  void changeNumber() {
    _step = AuthStep.enterPhone;
    _verificationId = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool get isLoggedIn => _authRepository.isLoggedIn;

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepository.logout();

    result.when(
      success: (_) {
        _user = null;
        _step = AuthStep.enterPhone;
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
