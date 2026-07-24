import '../../core/errors/error_handler.dart';
import '../../core/errors/failure.dart';
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
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signIn(
        email: email.trim(),
        password: password,
      );
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'signIn'));
    }
  }

  @override
  Future<Result<UserModel>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        email: email.trim(),
        password: password,
        name: name.trim(),
      );
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'register'));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email.trim());
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'sendPasswordResetEmail'),
      );
    }
  }

  @override
  Future<Result<UserModel?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUserProfile();
      return Result.success(user);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'getCurrentUser'));
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
      if (failure.message == 'Please sign in again to continue.') {
        return const Result.failure(
          AuthFailure('Please sign in again to delete your account.'),
        );
      }
      return Result.failure(failure);
    }
  }
}
