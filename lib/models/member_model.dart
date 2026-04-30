import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a member within a group.
/// Stored in Firestore: groups/{groupId}/members/{userId}
class MemberModel {
  final String userId;
  final String name;
  final String? photoUrl;
  final String color;
  final String role; // 'superAdmin', 'admin', 'editor', 'viewer'
  final DateTime joinedAt;
  final String status; // 'active', 'removed'

  const MemberModel({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.color,
    required this.role,
    required this.joinedAt,
    required this.status,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return MemberModel(
      userId: id ?? json['userId'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      color: json['color'] as String,
      role: json['role'] as String,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'photoUrl': photoUrl,
        'color': color,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'status': status,
      };

  MemberModel copyWith({
    String? name,
    String? photoUrl,
    String? role,
    String? status,
  }) {
    return MemberModel(
      userId: userId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      color: color,
      role: role ?? this.role,
      joinedAt: joinedAt,
      status: status ?? this.status,
    );
  }

  /// Whether this member is the Super Admin.
  bool get isSuperAdmin => role == 'superAdmin';

  /// Whether this member is an Admin or Super Admin.
  bool get isAdmin => role == 'admin' || role == 'superAdmin';

  /// Whether this member can edit expenses (Editor, Admin, or Super Admin).
  bool get isEditor =>
      role == 'editor' || role == 'admin' || role == 'superAdmin';

  /// Whether this member is currently active (not removed).
  bool get isActive => status == 'active';
}
