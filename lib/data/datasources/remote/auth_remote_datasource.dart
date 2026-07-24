import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// CNG LIVE — Auth Remote Data Source
///
/// Owns every FirebaseAuth and Firestore call needed for email &
/// password authentication. Per the layering rule established in
/// Step 22 (Section 3) — repositories never talk to Firebase
/// directly; this class is the only place in the app that imports
/// firebase_auth/cloud_firestore for auth purposes.
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

  /// Signs an existing driver in with email & password and returns
  /// their Firestore user profile — creating one on the fly if it's
  /// somehow missing (e.g. the account was created outside the app).
  /// Throws [AuthException] or [ServerException] on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('Sign-in did not return a user.');
    }

    return _fetchOrCreateUserDocument(
      firebaseUser,
      fallbackName: firebaseUser.displayName ?? '',
    );
  }

  /// Registers a brand-new driver with email & password, sets their
  /// Firebase Auth display name, and creates the Firestore
  /// /users/{uid} document. Throws [AuthException] or
  /// [ServerException] on failure.
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('Registration did not return a user.');
    }

    try {
      await firebaseUser.updateDisplayName(name);
    } catch (_) {
      // Non-fatal: the Firestore document below is the source of
      // truth for the driver's name throughout the app.
    }

    final newUser = UserModel(
      id: firebaseUser.uid,
      name: name,
      email: firebaseUser.email ?? email,
      driverType: '',
      createdAt: DateTime.now(),
    );

    try {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());
    } catch (e) {
      throw ServerException(e.toString());
    }

    return newUser;
  }

  /// Sends a password-reset email via Firebase Auth. Throws
  /// [AuthException] on failure (e.g. no account for that email).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code);
    }
  }

  /// Returns the currently signed-in driver's Firestore profile, or
  /// null if nobody is signed in — used to auto-login a driver whose
  /// Firebase Auth session survived an app restart.
  Future<UserModel?> getCurrentUserProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchOrCreateUserDocument(
      firebaseUser,
      fallbackName: firebaseUser.displayName ?? '',
    );
  }

  /// Shared fetch-or-create logic for both signIn and auto-login, so a
  /// driver always has a Firestore document to read from even if it
  /// wasn't created at registration time for some reason.
  Future<UserModel> _fetchOrCreateUserDocument(
    User firebaseUser, {
    required String fallbackName,
  }) async {
    try {
      final docRef =
          _firestore.collection(FirestorePaths.users).doc(firebaseUser.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      final newUser = UserModel(
        id: firebaseUser.uid,
        name: fallbackName,
        email: firebaseUser.email ?? '',
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
  /// requires a fresher session (the driver should sign in again
  /// before retrying).
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
