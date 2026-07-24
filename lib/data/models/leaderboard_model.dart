import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// CNG LIVE — Leaderboard Entry Model
///
/// Maps to /leaderboard/{userId} in Firestore (Step 22, Section 14;
/// collection name already reserved in FirestorePaths). Like
/// NotificationModel, this collection is populated server-side (a
/// Cloud Function recomputing weekly rankings from each driver's
/// points/reputation) — this model is read-only from the client, which
/// is why there's no toFirestore()/repository write method for it,
/// matching NotificationRepository's own read-only design.
class LeaderboardEntryModel extends Equatable {
  const LeaderboardEntryModel({
    required this.userId,
    required this.name,
    required this.points,
    required this.rank,
    this.profilePhoto,
  });

  final String userId;
  final String name;
  final int points;

  /// 1-based weekly rank — drives the podium (gold/silver/bronze)
  /// treatment for the top 3 (Step 16's "Top Contributor" badge is
  /// unlocked at rank <= 10).
  final int rank;
  final String? profilePhoto;

  factory LeaderboardEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntryModel(
      userId: doc.id,
      name: data['name'] as String? ?? '',
      points: data['points'] as int? ?? 0,
      rank: data['rank'] as int? ?? 0,
      profilePhoto: data['profilePhoto'] as String?,
    );
  }

  @override
  List<Object?> get props => [userId, name, points, rank, profilePhoto];
}
