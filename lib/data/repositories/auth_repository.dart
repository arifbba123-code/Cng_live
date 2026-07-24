import '../../core/network/network_result.dart';
import '../models/user_model.dart';

/// CNG LIVE — Auth Repository (Interface)
///
/// Defines the contract for email & password authentication and
/// session state. ViewModels (AuthViewModel) depend on this
/// abstraction only — never on firebase_auth directly (Step 22,
/// Section 3 MVVM layering).
abstract class AuthRepository {
  /// Signs an existing driver in with email & password. Returns the
  /// authenticated driver's Firestore profile.
  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  });

  /// Registers a new driver with email & password and creates their
  /// Firestore /users/{uid} document.
  Future<Result<UserModel>> register({
    required String email,
    required String password,
    required String name,
  });

  /// Sends a password-reset email to the given address.
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Returns the currently signed-in driver's profile (for auto-login
  /// on app start), or null if nobody is signed in.
  Future<Result<UserModel?>> getCurrentUser();

  /// Whether a driver is currently signed in — checked by the app's
  /// startup logic to decide /login vs /home.
  bool get isLoggedIn;

  /// The current signed-in user's Firebase Auth UID, or null.
  String? get currentUserId;

  /// Signs the current driver out (Home screen Logout action).
  Future<Result<void>> logout();

  /// Permanently deletes the driver's account and auth record —
  /// Firestore data cleanup is handled separately by UserRepository,
  /// this only removes the Auth identity.
  Future<Result<void>> deleteAccount();
}
