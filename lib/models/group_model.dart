import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a group in SplitSaathi.
/// Stored in Firestore: groups/{groupId}
class GroupModel {
  final String groupId;
  final String name;
  final String? iconEmoji;
  final String createdBy; // userId of Super Admin
  final DateTime createdAt;
  final int memberCount;

  const GroupModel({
    required this.groupId,
    required this.name,
    this.iconEmoji,
    required this.createdBy,
    required this.createdAt,
    required this.memberCount,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return GroupModel(
      groupId: id ?? json['groupId'] as String,
      name: json['name'] as String,
      iconEmoji: json['iconEmoji'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      memberCount: json['memberCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconEmoji': iconEmoji,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'memberCount': memberCount,
      };

  GroupModel copyWith({
    String? name,
    String? iconEmoji,
    int? memberCount,
  }) {
    return GroupModel(
      groupId: groupId,
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      createdBy: createdBy,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
