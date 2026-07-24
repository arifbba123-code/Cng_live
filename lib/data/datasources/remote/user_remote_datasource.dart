import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// CNG LIVE — User Remote Data Source
///
/// Owns every Firestore call against /users/{userId} plus the Storage
/// upload for profile photos. Mirrors StatusRemoteDataSource's
/// contract: every method returns a plain model/value or throws
/// ServerException, never Result<T>. Badge and favourite-pump
/// *resolution* (joining ids to full BadgeModel/PumpModel objects) is
/// composition that belongs one layer up in UserRepositoryImpl, which
/// is why this datasource only exposes the raw favourites array
/// mutations, not a resolved pump list.
class UserRemoteDataSource {
  UserRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection(FirestorePaths.users).doc(userId);

  Stream<UserModel> watchUser(String userId) {
    try {
      return _userDoc(userId).snapshots().map((doc) {
        if (!doc.exists) {
          throw ServerException('User not found: $userId');
        }
        return UserModel.fromFirestore(doc);
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      if (!doc.exists) {
        throw ServerException('User not found: $userId');
      }
      return UserModel.fromFirestore(doc);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      await _userDoc(user.id).set(user.toFirestore());
      return user;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> updateProfile(UserModel user) async {
    try {
      await _userDoc(user.id).set(user.toFirestore(), SetOptions(merge: true));
      return user;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// KNOWN LIMITATION: uses dart:io's File, which has no implementation
  /// on web — fine for the mobile-first MVP this app targets today, but
  /// flagged here since the repo also carries web/desktop build
  /// folders. A future web build would need this call site to accept
  /// raw bytes (Uint8List) instead of a file path.
  Future<String> uploadProfilePhoto(String userId, String localFilePath) async {
    try {
      final ref = _storage.ref('profile_photos/$userId.jpg');
      final file = File(localFilePath);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> addFavouritePump(String userId, String pumpId) async {
    try {
      await _userDoc(userId).update({
        FirestorePaths.fieldFavouritePumps: FieldValue.arrayUnion([pumpId]),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> removeFavouritePump(String userId, String pumpId) async {
    try {
      await _userDoc(userId).update({
        FirestorePaths.fieldFavouritePumps: FieldValue.arrayRemove([pumpId]),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      // Deletes the profile document plus the badges subcollection
      // (Step 22, Section 14) — favourites are a field on the profile
      // document itself so no separate cleanup is needed for those.
      final badgesSnapshot =
          await _userDoc(userId).collection(FirestorePaths.badgesSubcollection).get();
      final batch = _firestore.batch();
      for (final doc in badgesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_userDoc(userId));
      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
