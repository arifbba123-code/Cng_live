import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'pump_model.dart';

/// CNG LIVE — Status Update Model
///
/// Represents a single driver-submitted status post. Written to BOTH
/// locations described in Step 22, Section 14:
///   - /pumps/{pumpId}/statusHistory/{updateId}  (per-pump timeline,
///     powers Pump Detail's Status History, Step 14)
///   - /statusUpdates/{updateId}                  (flat mirror, powers
///     "My Contributions" queries by userId, Step 16)
///
/// Both writes use this same model — the repository decides which
/// path(s) to write to, this model stays agnostic of location.
class StatusUpdateModel extends Equatable {
  const StatusUpdateModel({
    required this.id,
    required this.pumpId,
    required this.userId,
    this.userName,
    required this.status,
    this.queueLength,
    this.photo,
    required this.timestamp,
    this.isFlagged = false,
    this.gpsVerified = false,
  });

  final String id;
  final String pumpId;
  final String userId;

  /// Denormalized contributor name — avoids a join when rendering the
  /// Status History timeline (Step 14) or Recent Activity (Step 16).
  final String? userName;

  final PumpStatus status;

  /// Selected queue-time bucket, e.g. "5-10m", "10-20m" (Step 15 chip
  /// selector). Only meaningful when status == PumpStatus.longQueue.
  final String? queueLength;

  /// Optional photo URL attached to the update (Step 15 optional add-on).
  final String? photo;

  final DateTime timestamp;

  /// Set true once a Report Wrong Update (Step 14) has been filed
  /// against this entry — used to visually de-weight it in trust
  /// calculations without deleting the record.
  final bool isFlagged;

  /// Whether the submitting driver's GPS was within range of the pump
  /// at submission time (Step 15 GPS Auto-Verification). Silent trust
  /// signal — does not block submission, but feeds points/weighting.
  final bool gpsVerified;

  factory StatusUpdateModel.fromFirestore(DocumentSnapshot doc, {String? pumpId}) {
    final data = doc.data() as Map<String, dynamic>;
    return StatusUpdateModel(
      id: doc.id,
      pumpId: pumpId ?? data['pumpId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String?,
      status: PumpStatus.fromFirestore(data['status'] as String?),
      queueLength: data['queueLength'] as String?,
      photo: data['photo'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFlagged: data['isFlagged'] as bool? ?? false,
      gpsVerified: data['gpsVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pumpId': pumpId,
      'userId': userId,
      'userName': userName,
      'status': status.toFirestoreValue(),
      'queueLength': queueLength,
      'photo': photo,
      'timestamp': Timestamp.fromDate(timestamp),
      'isFlagged': isFlagged,
      'gpsVerified': gpsVerified,
    };
  }

  @override
  List<Object?> get props => [
        id,
        pumpId,
        userId,
        userName,
        status,
        queueLength,
        photo,
        timestamp,
        isFlagged,
        gpsVerified,
      ];
}
