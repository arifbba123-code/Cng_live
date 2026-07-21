import '../../core/network/network_result.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../models/pump_model.dart';

/// CNG LIVE — User Repository (Interface)
///
/// Defines the contract for driver profile CRUD, points/reputation,
/// favourites, and badge progress. Backs Profile (Step 16), Favourites
/// (Step 2 screen list), and the Edit Profile flow (Step 16 Quick
/// Actions).
abstract class UserRepository {
  /// Live stream of the current driver's own profile — powers Profile
  /// header (Step 16) and stays live so points/reputation updates from
  /// Cloud Functions (Step 22, Section 14) reflect instantly.
  Stream<UserModel> watchUser(String userId);

  Future<Result<UserModel>> getUserById(String userId);

  /// Creates the initial /users/{uid} document after first OTP
  /// verification (Step 3 Name Setup screen).
  Future<Result<UserModel>> createUser(UserModel user);

  /// Updates editable profile fields (Step 16 Edit Profile).
  Future<Result<UserModel>> updateProfile(UserModel user);

  /// Uploads a new profile photo and returns its storage URL — used by
  /// Edit Profile before calling [updateProfile] with the new URL.
  Future<Result<String>> uploadProfilePhoto(String userId, String localFilePath);

  // --- Favourites (Step 16 / Favourites screen) ------------------------

  Future<Result<void>> addFavouritePump(String userId, String pumpId);

  Future<Result<void>> removeFavouritePump(String userId, String pumpId);

  /// Resolved pump objects for the driver's favourites list — powers
  /// both Profile's compact preview and the full Favourites tab.
  Stream<List<PumpModel>> watchFavouritePumps(String userId);

  // --- Badges (Step 16 Achievement Badges) ------------------------------

  /// Earned-state records for all 4 catalog badges (unlocked + locked),
  /// merged by the ViewModel against BadgeCatalog.all for display.
  Stream<List<BadgeModel>> watchBadges(String userId);

  // --- Account lifecycle -------------------------------------------------

  /// Deletes the driver's Firestore data (profile, favourites, badges).
  /// Called alongside AuthRepository.deleteAccount() (Step 19 Delete
  /// Account flow) — kept separate since this repository owns Firestore
  /// user data, while AuthRepository owns the Firebase Auth identity.
  Future<Result<void>> deleteUserData(String userId);
}
