import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// CNG LIVE — Notification Type
///
/// Matches the categories designed in Step 18 (Notifications screen),
/// each with its own icon/badge-color treatment and filter chip
/// ("Pumps" groups pumpStatusAlert + favouritePumpUpdate, "Rewards"
/// groups achievement + pointsEarned, "System" is standalone).
enum NotificationType {
  pumpStatusAlert,
  favouritePumpUpdate,
  achievement,
  pointsEarned,
  system;

  static NotificationType fromFirestore(String? value) {
    switch (value) {
      case 'favouritePumpUpdate':
        return NotificationType.favouritePumpUpdate;
      case 'achievement':
        return NotificationType.achievement;
      case 'pointsEarned':
        return NotificationType.pointsEarned;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.pumpStatusAlert;
    }
  }

  String toFirestoreValue() => name;

  /// Which top-level filter chip this type belongs to (Step 18).
  String get filterCategory {
    switch (this) {
      case NotificationType.pumpStatusAlert:
      case NotificationType.favouritePumpUpdate:
        return 'Pumps';
      case NotificationType.achievement:
      case NotificationType.pointsEarned:
        return 'Rewards';
      case NotificationType.system:
        return 'System';
    }
  }
}

/// CNG LIVE — Notification Model
///
/// Maps to /notifications/{userId}/items/{notificationId} in Firestore
/// (Step 22, Section 14) — a per-user subcollection so each driver only
/// ever reads their own notification list.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.relatedPumpId,
    required this.timestamp,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;

  /// If set, tapping the notification navigates to this pump's Pump
  /// Detail screen (Step 18) rather than Profile/Achievements.
  final String? relatedPumpId;

  final DateTime timestamp;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: NotificationType.fromFirestore(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      relatedPumpId: data['relatedPumpId'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toFirestoreValue(),
      'title': title,
      'body': body,
      'isRead': isRead,
      'relatedPumpId': relatedPumpId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      relatedPumpId: relatedPumpId,
      timestamp: timestamp,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, body, isRead, relatedPumpId, timestamp];
}
