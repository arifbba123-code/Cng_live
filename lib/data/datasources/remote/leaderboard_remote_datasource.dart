import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/leaderboard_model.dart';

/// CNG LIVE — Leaderboard Remote Data Source
///
/// Owns every Firestore call against /leaderboard/{userId}. Read-only —
/// mirrors NotificationRemoteDataSource's contract in that regard.
/// Every method returns a plain model/value or throws ServerException,
/// never Result<T>.
class LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _leaderboardRef =>
      _firestore.collection(FirestorePaths.leaderboard);

  Stream<List<LeaderboardEntryModel>> watchLeaderboard({int limit = 10}) {
    try {
      return _leaderboardRef
          .orderBy('rank')
          .limit(limit)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(LeaderboardEntryModel.fromFirestore).toList());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<LeaderboardEntryModel?> getUserRank(String userId) async {
    try {
      final doc = await _leaderboardRef.doc(userId).get();
      if (!doc.exists) return null;
      return LeaderboardEntryModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
