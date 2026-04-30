import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an invite link for joining a group.
/// Stored in Firestore: invites/{token}
class InviteModel {
  final String token;
  final String groupId;
  final String groupName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final String status; // 'active', 'expired', 'exhausted'

  const InviteModel({
    required this.token,
    required this.groupId,
    required this.groupName,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = 2,
    this.usedCount = 0,
    this.status = 'active',
  });

  factory InviteModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return InviteModel(
      token: id ?? json['token'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      maxUses: json['maxUses'] as int? ?? 2,
      usedCount: json['usedCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'groupId': groupId,
        'groupName': groupName,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'maxUses': maxUses,
        'usedCount': usedCount,
        'status': status,
      };

  /// Whether this invite is still valid (active, not expired, not exhausted).
  bool get isValid =>
      status == 'active' &&
      DateTime.now().isBefore(expiresAt) &&
      usedCount < maxUses;

  /// Whether this invite has expired (time-based).
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this invite has reached max uses.
  bool get isExhausted => usedCount >= maxUses;
}
