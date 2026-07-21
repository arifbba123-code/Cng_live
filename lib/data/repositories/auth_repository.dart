import '../../core/network/network_result.dart';
import '../models/user_model.dart';

/// CNG LIVE — Auth Repository (Interface)
///
/// Defines the contract for phone-OTP authentication (Step 1: Firebase
/// Auth Phone OTP) and session state. ViewModels (LoginViewModel,
/// OtpViewModel) depend on this abstraction only — never on
/// firebase_auth directly (Step 22, Section 3 MVVM layering).
abstract class AuthRepository {
  /// Sends an OTP to the given 10-digit phone number (without +91).
  /// On success, returns a verificationId to be passed to [verifyOtp].
  Future<Result<String>> sendOtp(String phoneNumber);

  /// Verifies the 6-digit OTP against the given verificationId.
  /// On success, returns the authenticated UserModel — creating a new
  /// Firestore /users/{uid} document on first sign-in if one doesn't
  /// exist yet (caller then routes to Name Setup, Step 3 screen list).
  Future<Result<UserModel>> verifyOtp({
    required String verificationId,
    required String otp,
  });

  /// Re-sends the OTP for an in-progress verification (Step 12 Resend
  /// OTP, 30-second timer). Returns a new verificationId.
  Future<Result<String>> resendOtp(String phoneNumber);

  /// Whether a driver is currently signed in — checked by the router's
  /// auth guard (Step 22, Section 9) to decide /login vs /home.
  bool get isLoggedIn;

  /// The current signed-in user's Firebase Auth UID, or null.
  String? get currentUserId;

  /// Signs the current driver out (Settings/Profile Logout, Step 16/19).
  Future<Result<void>> logout();

  /// Permanently deletes the driver's account and auth record (Settings
  /// Delete Account flow, Step 19) — Firestore data cleanup is handled
  /// separately by UserRepository, this only removes the Auth identity.
  Future<Result<void>> deleteAccount();
}
