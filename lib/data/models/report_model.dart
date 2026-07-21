import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// CNG LIVE — Report Model
///
/// Maps to /reports/{reportId} in Firestore (Step 22, Section 14).
/// Created when a driver taps "Report Wrong Update" on Pump Detail
/// (Step 14) or via the dedicated Report Wrong Update screen (Step 2).
///
/// A report references a specific StatusUpdateModel by id — it does not
/// delete or alter that update, it only flags it (see
/// StatusUpdateModel.isFlagged) for trust weighting / moderation review.
class ReportModel extends Equatable {
  const ReportModel({
    required this.id,
    required this.statusUpdateId,
    required this.pumpId,
    required this.reportedBy,
    required this.reason,
    required this.timestamp,
    this.resolved = false,
  });

  final String id;

  /// The StatusUpdateModel.id being disputed.
  final String statusUpdateId;

  /// Denormalized for quick lookups without joining through the update.
  final String pumpId;

  /// userId of the driver filing the report.
  final String reportedBy;

  /// Short reason text the driver selects/enters (Step 2 screen list).
  final String reason;

  final DateTime timestamp;

  /// Whether an admin/moderation pass has reviewed this report. Not
  /// exposed in any MVP screen yet — reserved for the future admin
  /// panel referenced in Step 22, Section 20 (Scalability Plan).
  final bool resolved;

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      statusUpdateId: data['statusUpdateId'] as String? ?? '',
      pumpId: data['pumpId'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolved: data['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'statusUpdateId': statusUpdateId,
      'pumpId': pumpId,
      'reportedBy': reportedBy,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'resolved': resolved,
    };
  }

  @override
  List<Object?> get props =>
      [id, statusUpdateId, pumpId, reportedBy, reason, timestamp, resolved];
}
