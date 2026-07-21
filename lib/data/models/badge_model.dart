import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// CNG LIVE — Badge Catalog
///
/// FLAGGED ADDITION: Step 22's Firestore structure (Section 14) did not
/// spell out a badges collection. Achievements are fixed, code-defined
/// content (icon/name/description/unlock threshold) — not something a
/// driver or admin edits — so the catalog itself lives here as a static
/// list, matching how AppIcons/AppColors are handled. Only *which*
/// badges a driver has actually earned needs to live in Firestore (see
/// BadgeModel.fromFirestore below), at:
///   /users/{userId}/badges/{badgeId}
/// This mirrors the per-user subcollection pattern already approved for
/// notifications.
enum BadgeId {
  topContributor,
  fastReporter,
  trustedDriver,
  hundredUpdatesClub,
}

class BadgeDefinition extends Equatable {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.targetValue,
  });

  final BadgeId id;
  final String name;
  final String description;

  /// Maps to an AppIcons entry when rendered (Step 16 badge tiles).
  final String iconName;

  /// The stat threshold required to unlock — used to compute progress
  /// text like "Post 25 more updates to unlock" (Step 16).
  final int targetValue;

  @override
  List<Object?> get props => [id, name, description, iconName, targetValue];
}

/// The fixed 4-badge MVP catalog from Step 16's Achievement Badges spec.
class BadgeCatalog {
  BadgeCatalog._();

  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: BadgeId.topContributor,
      name: 'Top Contributor',
      description: 'Ranked in the weekly top 10 leaderboard.',
      iconName: 'emoji_events',
      targetValue: 10,
    ),
    BadgeDefinition(
      id: BadgeId.fastReporter,
      name: 'Fast Reporter',
      description: 'Submitted 10 GPS-verified updates within 5 minutes of arrival.',
      iconName: 'bolt',
      targetValue: 10,
    ),
    BadgeDefinition(
      id: BadgeId.trustedDriver,
      name: 'Trusted Driver',
      description: 'Maintained 90%+ accuracy across 50+ updates.',
      iconName: 'shield',
      targetValue: 50,
    ),
    BadgeDefinition(
      id: BadgeId.hundredUpdatesClub,
      name: '100 Updates Club',
      description: 'Posted 100 total status updates.',
      iconName: 'workspace_premium',
      targetValue: 100,
    ),
  ];

  static BadgeDefinition definitionFor(BadgeId id) =>
      all.firstWhere((b) => b.id == id);
}

/// CNG LIVE — Badge Model (earned-state record)
///
/// Represents ONE driver's unlock record for ONE badge. Maps to
/// /users/{userId}/badges/{badgeId} in Firestore. Combined with
/// [BadgeCatalog] by the ProfileViewModel to render the full
/// locked/unlocked grid (Step 16).
class BadgeModel extends Equatable {
  const BadgeModel({
    required this.id,
    required this.unlockedAt,
    this.progressCurrent = 0,
  });

  final BadgeId id;

  /// Null if not yet unlocked.
  final DateTime? unlockedAt;

  /// Current progress toward BadgeDefinition.targetValue — drives the
  /// "Post 25 more updates to unlock" tooltip text (Step 16).
  final int progressCurrent;

  bool get isUnlocked => unlockedAt != null;

  BadgeDefinition get definition => BadgeCatalog.definitionFor(id);

  factory BadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeModel(
      id: BadgeId.values.firstWhere(
        (b) => b.name == doc.id,
        orElse: () => BadgeId.hundredUpdatesClub,
      ),
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
      progressCurrent: data['progressCurrent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'progressCurrent': progressCurrent,
    };
  }

  @override
  List<Object?> get props => [id, unlockedAt, progressCurrent];
}
