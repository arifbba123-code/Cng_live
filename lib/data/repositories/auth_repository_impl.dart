import '../../core/errors/error_handler.dart';
import '../../core/errors/failure.dart';
import '../../core/extensions/string_extensions.dart';
import '../../core/network/network_result.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// CNG LIVE — Auth Repository (Implementation)
///
/// Implements the approved AuthRepository contract by delegating every
/// call to AuthRemoteDataSource, which owns all FirebaseAuth/Firestore
/// access. This class contains NO Firebase imports — it only
/// orchestrates datasource calls and converts thrown exceptions into
/// typed Failures via ErrorHandler.handle(), per Step 22's layering
/// rule (Section 3: repositories never talk to Firebase directly).
///
/// All business logic previously reviewed (OTP send/verify/resend,
/// session state, logout, account deletion, and the "empty name routes
/// to Name Setup" first-sign-in behavior) is preserved unchanged — it
/// simply now lives in AuthRemoteDataSource rather than here.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<String>> sendOtp(String phoneNumber) async {
    try {
      final verificationId =
          await _remoteDataSource.sendOtp(phoneNumber.withCountryCode);
      return Result.success(verificationId);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'sendOtp'));
    }
  }

  @override
  Future<Result<String>> resendOtp(String phoneNumber) async {
    try {
      final verificationId =
          await _remoteDataSource.resendOtp(phoneNumber.withCountryCode);
      return Result.success(verificationId);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'resendOtp'));
    }
  }

  @override
  Future<Result<UserModel>> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final user = await _remoteDataSource.verifyOtp(
        verificationId: verificationId,
        otp: otp,
      );
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'verifyOtp'));
    }
  }

  @override
  bool get isLoggedIn => _remoteDataSource.isLoggedIn;

  @override
  String? get currentUserId => _remoteDataSource.currentUserId;

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'logout'));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Result.success(null);
    } catch (e) {
      final failure = ErrorHandler.handle(e, context: 'deleteAccount');
      // 'requires-recent-login' is the common failure here — Firebase
      // requires a fresh sign-in before allowing account deletion.
      // Step 19's Delete Account flow already re-confirms via OTP,
      // which satisfies this in normal use, but mapping it to a
      // clearer driver-facing message in case the session is older
      // than Firebase's freshness window.
      if (failure.message == 'requires-recent-login') {
        return const Result.failure(
          AuthFailure('Please verify your number again to delete your account.'),
        );
      }
      return Result.failure(failure);
    }
  }
}
