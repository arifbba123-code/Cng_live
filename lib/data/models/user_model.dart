import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// CNG LIVE — User Model
///
/// Maps to /users/{userId} in Firestore (Step 22, Section 14).
/// Document ID = Firebase Auth UID.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.driverType,
    this.profilePhoto,
    this.points = 0,
    this.reputation = 0,
    this.favouritePumps = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String driverType; // Red Taxi / Ola / Uber / Private / Fleet
  final String? profilePhoto;
  final int points;
  final int reputation;
  final List<String> favouritePumps;
  final DateTime createdAt;

  /// Reputation tier label, derived from points — used on Profile header
  /// and Pump Detail contributor tag (Step 16 / Step 14).
  String get reputationLevel {
    if (points >= 1000) return 'Elite Driver';
    if (points >= 500) return 'Trusted Driver';
    if (points >= 100) return 'Active Driver';
    return 'New Driver';
  }

  bool get isVerified => reputation >= 50;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      driverType: data['driverType'] as String? ?? '',
      profilePhoto: data['profilePhoto'] as String?,
      points: data['points'] as int? ?? 0,
      reputation: data['reputation'] as int? ?? 0,
      favouritePumps: List<String>.from(data['favouritePumps'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'driverType': driverType,
      'profilePhoto': profilePhoto,
      'points': points,
      'reputation': reputation,
      'favouritePumps': favouritePumps,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? driverType,
    String? profilePhoto,
    int? points,
    int? reputation,
    List<String>? favouritePumps,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      driverType: driverType ?? this.driverType,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      points: points ?? this.points,
      reputation: reputation ?? this.reputation,
      favouritePumps: favouritePumps ?? this.favouritePumps,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, phone, driverType, profilePhoto, points, reputation, favouritePumps, createdAt];
}
