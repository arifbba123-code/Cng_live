import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// CNG LIVE — Pump Status Enum
///
/// Mirrors the three driver-facing statuses from the design system
/// (Step 8/15), plus an `unverified` fallback for pumps with no recent
/// update yet (Pump Detail empty state, Step 14).
enum PumpStatus {
  stockAvailable,
  longQueue,
  noStock,
  unverified;

  static PumpStatus fromFirestore(String? value) {
    switch (value) {
      case 'stockAvailable':
        return PumpStatus.stockAvailable;
      case 'longQueue':
        return PumpStatus.longQueue;
      case 'noStock':
        return PumpStatus.noStock;
      default:
        return PumpStatus.unverified;
    }
  }

  String toFirestoreValue() => name;

  /// Display label matching the badge text used across Home, Pump
  /// Detail, and Notifications (Step 13/14/18).
  String get label {
    switch (this) {
      case PumpStatus.stockAvailable:
        return 'Stock Available';
      case PumpStatus.longQueue:
        return 'Long Queue';
      case PumpStatus.noStock:
        return 'No Stock';
      case PumpStatus.unverified:
        return 'No Recent Update';
    }
  }
}

/// CNG LIVE — Pump Model
///
/// Maps to /pumps/{pumpId} in Firestore (Step 22, Section 14).
/// Pumps are curated/admin-seeded for MVP (Step 1) — drivers update
/// status, they don't create pump documents themselves.
class PumpModel extends Equatable {
  const PumpModel({
    required this.id,
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    this.currentStatus = PumpStatus.unverified,
    this.queueMinutes,
    this.verified = false,
    this.lastUpdatedAt,
    this.lastUpdatedBy,
    this.updatedByName,
    this.phoneNumber,
  });

  final String id;
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final PumpStatus currentStatus;

  /// Estimated queue wait time in minutes — only meaningful when
  /// currentStatus == PumpStatus.longQueue (Step 15 queue selector).
  final int? queueMinutes;

  /// Admin-curated verification badge (✔️ shown on Home/Pump Detail).
  final bool verified;

  final DateTime? lastUpdatedAt;
  final String? lastUpdatedBy; // contributor userId
  final String? updatedByName; // denormalized display name

  /// Optional — enables the "Call" button on Pump Detail (Step 14).
  final String? phoneNumber;

  /// Whether the current status is older than the 45-minute freshness
  /// window (Step 14 stale-status warning).
  bool get isStale {
    if (lastUpdatedAt == null) return true;
    return DateTime.now().difference(lastUpdatedAt!).inMinutes >= 45;
  }

  factory PumpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PumpModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      area: data['area'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      currentStatus: PumpStatus.fromFirestore(data['currentStatus'] as String?),
      queueMinutes: data['queueMinutes'] as int?,
      verified: data['verified'] as bool? ?? false,
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
      lastUpdatedBy: data['lastUpdatedBy'] as String?,
      updatedByName: data['updatedByName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'currentStatus': currentStatus.toFirestoreValue(),
      'queueMinutes': queueMinutes,
      'verified': verified,
      'lastUpdatedAt':
          lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'lastUpdatedBy': lastUpdatedBy,
      'updatedByName': updatedByName,
      'phoneNumber': phoneNumber,
    };
  }

  PumpModel copyWith({
    PumpStatus? currentStatus,
    int? queueMinutes,
    bool? verified,
    DateTime? lastUpdatedAt,
    String? lastUpdatedBy,
    String? updatedByName,
  }) {
    return PumpModel(
      id: id,
      name: name,
      area: area,
      latitude: latitude,
      longitude: longitude,
      currentStatus: currentStatus ?? this.currentStatus,
      queueMinutes: queueMinutes ?? this.queueMinutes,
      verified: verified ?? this.verified,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      phoneNumber: phoneNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        area,
        latitude,
        longitude,
        currentStatus,
        queueMinutes,
        verified,
        lastUpdatedAt,
        lastUpdatedBy,
        updatedByName,
        phoneNumber,
      ];
}
