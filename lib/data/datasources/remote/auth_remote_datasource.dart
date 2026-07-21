import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../models/user_model.dart';

/// CNG LIVE — Auth Remote Data Source
///
/// Owns every FirebaseAuth and Firestore call needed for phone-OTP
/// authentication (Step 1). Per the layering rule established in
/// Step 22 (Section 3) — reinforced explicitly for this rewrite —
/// repositories never talk to Firebase directly; this class is the
/// only place in the app that imports firebase_auth/cloud_firestore
/// for auth purposes.
///
/// Contract: every method here either returns a plain value/model or
/// throws one of the typed exceptions from core/errors/exceptions.dart
/// (AuthException, ServerException). It never returns a Result<T> —
/// that wrapping happens one layer up, in AuthRepositoryImpl, via
/// ErrorHandler. This keeps the datasource layer thin and Firebase-
/// specific, and the Result<T>/Failure vocabulary exclusive to
/// repositories and above.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Android/iOS auto-resend token, captured from codeSent and reused
  /// on resendOtp so the SMS provider treats it as a continuation of
  /// the same verification attempt rather than a brand-new one.
  int? _forceResendingToken;

  static const Duration _otpTimeout = Duration(seconds: 60);

  /// Starts phone verification for a full E.164 number (e.g.
  /// "+919876543210"). Returns the verificationId to be passed to
  /// [verifyOtp]. Throws [AuthException] on failure.
  Future<String> sendOtp(String fullPhoneNumber) {
    return _startPhoneVerification(fullPhoneNumber);
  }

  /// Re-sends the OTP for an in-progress verification (Step 12 Resend
  /// OTP), reusing the resend token captured from the original
  /// [sendOtp] call.
  Future<String> resendOtp(String fullPhoneNumber) {
    return _startPhoneVerification(
      fullPhoneNumber,
      forceResendingToken: _forceResendingToken,
    );
  }

  /// Shared implementation for sendOtp/resendOtp — Firebase's
  /// verifyPhoneNumber API is callback-based, so it's wrapped in a
  /// Completer to expose a plain Future<String> to the repository.
  Future<String> _startPhoneVerification(
    String fullPhoneNumber, {
    int? forceResendingToken,
  }) {
    final completer = Completer<String>();

    try {
      _firebaseAuth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: _otpTimeout,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Android instant/auto-verification. The explicit OTP screen
          // flow (Step 12) always completes sign-in via verifyOtp with
          // the code the driver typed/auto-filled, so no sign-in
          // happens here — logged only.
          AppLogger.info(
            'AuthRemoteDataSource',
            'verificationCompleted fired for auto-retrieved credential',
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(AuthException(e.code));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _forceResendingToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // No-op: if codeSent already completed the future, this only
          // signals auto-retrieval is no longer possible — the driver
          // can still submit manually via the OTP screen (Step 12).
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(AuthException(e.toString()));
      }
    }

    return completer.future;
  }

  /// Verifies the OTP, signs the driver in, and ensures a Firestore
  /// /users/{uid} document exists — creating a minimal one (empty
  /// name/driverType) on first-ever sign-in. Throws [AuthException] or
  /// [ServerException] on failure.
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final UserCredential userCredential;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('Sign-in did not return a user.');
    }

    try {
      final docRef =
          _firestore.collection(FirestorePaths.users).doc(firebaseUser.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      // First-ever sign-in: create a minimal document. The caller
      // (AuthRepositoryImpl -> OtpViewModel) checks UserModel.name
      // .isEmpty to decide whether to route to Name Setup (Step 3).
      final newUser = UserModel(
        id: firebaseUser.uid,
        name: '',
        phone: firebaseUser.phoneNumber ?? '',
        driverType: '',
        createdAt: DateTime.now(),
      );
      await docRef.set(newUser.toFirestore());
      return newUser;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Throws [AuthException] on failure (rare for signOut, but kept
  /// consistent with every other method's error contract).
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Deletes the driver's Firebase Auth identity. Throws
  /// [AuthException] with code 'requires-recent-login' when Firebase
  /// requires a fresher session — Step 19's Delete Account flow
  /// already re-confirms via OTP, which normally satisfies this.
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException('No signed-in driver to delete.');
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }
}
