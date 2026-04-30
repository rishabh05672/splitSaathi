import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the SplitSaathi system.
/// Stored in Firestore: users/{userId}
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String color; // Hex color string, e.g., '#FF6B6B'
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.color,
    this.fcmToken,
    required this.createdAt,
  });

  /// Creates a UserModel from a Firestore document snapshot.
  factory UserModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return UserModel(
      uid: id ?? json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      color: json['color'] as String,
      fcmToken: json['fcmToken'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this model to a Firestore-compatible JSON map.
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'color': color,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Returns a copy with modified fields.
  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      color: color,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
