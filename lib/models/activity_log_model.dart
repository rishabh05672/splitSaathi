import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an activity log entry within a group.
/// Stored in Firestore: groups/{groupId}/activityLogs/{logId}
class ActivityLogModel {
  final String logId;
  final String userId;
  final String userName;
  final String userColor;
  final String action;
  // Possible actions:
  // 'ADD_EXPENSE', 'EDIT_EXPENSE', 'DELETE_EXPENSE',
  // 'JOIN_GROUP', 'LEAVE_GROUP', 'ROLE_CHANGED',
  // 'MEMBER_APPROVED', 'MEMBER_DECLINED',
  // 'SETTLEMENT_CALCULATED', 'PAYMENT_MADE',
  // 'MEMBER_REMOVED', 'GROUP_CREATED'
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final DateTime expiresAt;

  const ActivityLogModel({
    required this.logId,
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.expiresAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final timestamp = (json['timestamp'] as Timestamp).toDate();
    return ActivityLogModel(
      logId: id ?? json['logId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userColor: json['userColor'] as String,
      action: json['action'] as String,
      details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
      timestamp: timestamp,
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : timestamp.add(const Duration(days: 150)),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'userColor': userColor,
        'action': action,
        'details': details,
        'timestamp': Timestamp.fromDate(timestamp),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  /// Returns a human-readable description of this activity.
  String get description {
    switch (action) {
      case 'ADD_EXPENSE':
        return '$userName added ₹${details['amount']} for ${details['itemName']}';
      case 'EDIT_EXPENSE':
        return '$userName edited ${details['itemName']}: ₹${details['oldAmount']}→₹${details['newAmount']}';
      case 'DELETE_EXPENSE':
        return '$userName deleted ${details['itemName']} ₹${details['amount']}';
      case 'JOIN_GROUP':
        return '$userName joined the group';
      case 'LEAVE_GROUP':
        return '$userName left the group';
      case 'ROLE_CHANGED':
        return "${details['targetName']}'s role changed to ${details['newRole']}";
      case 'MEMBER_APPROVED':
        return '${details['memberName']} was approved to join';
      case 'MEMBER_DECLINED':
        return "${details['memberName']}'s request was declined";
      case 'MEMBER_REMOVED':
        return '${details['memberName']} was removed from the group';
      case 'SETTLEMENT_CALCULATED':
        return 'Settlement calculated for ${details['month']}';
      case 'PAYMENT_MADE':
        return '$userName paid ₹${details['amount']} to ${details['toUserName']}';
      case 'GROUP_CREATED':
        return '$userName created this group';
      default:
        return '$userName performed an action';
    }
  }
}
