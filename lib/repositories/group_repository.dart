import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import '../models/activity_log_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';

/// Repository for group-level operations.
/// Handles creating groups, managing members, and activity logging.
class GroupRepository {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  GroupRepository(this._firestoreService, this._notificationService);

  /// Create a new group and add the creator as Super Admin.
  /// Returns the created GroupModel.
  Future<GroupModel> createGroup({
    required String name,
    String? iconEmoji,
    required UserModel creator,
  }) async {
    final now = DateTime.now();

    // Create the group document
    final groupData = GroupModel(
      groupId: '', // Will be set from Firestore doc ID
      name: name,
      iconEmoji: iconEmoji,
      createdBy: creator.uid,
      createdAt: now,
      memberCount: 1,
    );

    final docRef = await _firestoreService.createGroup(groupData.toJson());
    final groupId = docRef.id;

    // Add creator as Super Admin member
    final member = MemberModel(
      userId: creator.uid,
      name: creator.name,
      photoUrl: creator.photoUrl,
      color: creator.color,
      role: AppConstants.roleSuperAdmin,
      joinedAt: now,
      status: AppConstants.statusActive,
    );

    await _firestoreService.addMember(groupId, creator.uid, member.toJson());

    // Log activity
    await logActivity(
      groupId: groupId,
      userId: creator.uid,
      userName: creator.name,
      userColor: creator.color,
      action: AppConstants.actionGroupCreated,
      details: {'groupName': name},
    );

    return GroupModel(
      groupId: groupId,
      name: name,
      iconEmoji: iconEmoji,
      createdBy: creator.uid,
      createdAt: now,
      memberCount: 1,
    );
  }

  /// Get a group by ID.
  Future<GroupModel?> getGroup(String groupId) async {
    final doc = await _firestoreService.getGroup(groupId);
    if (!doc.exists) return null;
    return GroupModel.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  /// Stream all groups the user is a member of.
  /// Uses a collectionGroup query on 'members' subcollection,
  /// then fetches each group's data.
  Stream<List<GroupModel>> streamUserGroups(String userId) {
    return _firestoreService.streamUserGroups(userId).asyncMap((snapshot) async {
      final groups = <GroupModel>[];
      for (final doc in snapshot.docs) {
        // doc.reference.parent.parent gives us the group doc reference
        final groupRef = doc.reference.parent.parent;
        if (groupRef == null) continue;
        final groupDoc = await groupRef.get();
        if (groupDoc.exists) {
          groups.add(GroupModel.fromJson(
            groupDoc.data() as Map<String, dynamic>,
            id: groupDoc.id,
          ));
        }
      }
      return groups;
    });
  }

  /// Get the current user's member record in a group.
  Future<MemberModel?> getCurrentMember(
      String groupId, String userId) async {
    final doc = await _firestoreService.getMember(groupId, userId);
    if (!doc.exists) return null;
    return MemberModel.fromJson(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  /// Stream active members of a group.
  Stream<List<MemberModel>> streamMembers(String groupId) {
    return _firestoreService.streamMembers(groupId).map((snapshot) {
      return snapshot.docs
          .map((doc) => MemberModel.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    });
  }

  /// Get all active members of a group (one-time).
  Future<List<MemberModel>> getActiveMembers(String groupId) async {
    final snapshot = await _firestoreService.getMembers(groupId);
    return snapshot.docs
        .map((doc) => MemberModel.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();
  }

  /// Get FCM tokens of all group members except the sender.
  Future<List<String>> getGroupMemberTokens(String groupId, String excludeUserId) async {
    final members = await getActiveMembers(groupId);
    final tokens = <String>[];

    for (final member in members) {
      if (member.userId == excludeUserId) continue;
      
      // Fetch user doc to get the current token
      final userDoc = await _firestoreService.getUser(member.userId);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
    }
    return tokens;
  }

  /// Add a new member to a group (after join request approval).
  Future<void> addMember({
    required String groupId,
    required UserModel user,
    String role = 'viewer',
  }) async {
    final member = MemberModel(
      userId: user.uid,
      name: user.name,
      photoUrl: user.photoUrl,
      color: user.color,
      role: role,
      joinedAt: DateTime.now(),
      status: AppConstants.statusActive,
    );

    await _firestoreService.addMember(groupId, user.uid, member.toJson());

    // Increment member count
    await _firestoreService.incrementField(
      AppConstants.groupsCollection,
      groupId,
      'memberCount',
      1,
    );

    // Send notifications
    try {
      // 1. Notify existing members
      final existingTokens = await getGroupMemberTokens(groupId, user.uid);
      if (existingTokens.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientTokens: existingTokens,
          title: 'New Member 👋',
          body: '${user.name} has joined the group. Say hi!',
        );
      }

      // 2. Notify the newly added user
      if (user.fcmToken != null && user.fcmToken!.isNotEmpty) {
        final groupDoc = await _firestoreService.getGroup(groupId);
        final groupName = (groupDoc.data() as Map<String, dynamic>?)?['name'] ?? 'a new group';
        
        await _notificationService.sendNotification(
          recipientTokens: [user.fcmToken!],
          title: 'New Group Added 🏠',
          body: 'You have been added to "$groupName".',
        );
      }
    } catch (e) {
      print('Error sending member add notifications: $e');
    }
  }

  /// Add member directly by email if they exist.
  Future<String?> addMemberByEmail({
    required String groupId,
    required String email,
    required UserModel addedBy,
  }) async {
    // 1. Get user by email
    final snapshot = await _firestoreService.getUserByEmail(email);
    if (snapshot.docs.isEmpty) {
      return 'User with this email not found.';
    }

    final userDoc = snapshot.docs.first;
    final user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>, id: userDoc.id);

    // 2. Check if already a member
    final existingMember = await getCurrentMember(groupId, user.uid);
    if (existingMember != null && existingMember.status == AppConstants.statusActive) {
      return 'User is already a member of this group.';
    }

    // 3. Add as member
    await addMember(groupId: groupId, user: user, role: AppConstants.roleViewer);

    // 4. Log activity
    await logActivity(
      groupId: groupId,
      userId: addedBy.uid,
      userName: addedBy.name,
      userColor: addedBy.color,
      action: 'Member Added',
      details: {
        'memberName': user.name,
        'memberId': user.uid,
      },
    );

    return null; // Success
  }

  /// Change a member's role.
  Future<void> changeMemberRole({
    required String groupId,
    required String memberId,
    required String newRole,
    required String changedByName,
    required String changedByColor,
    required String changedById,
    required String memberName,
  }) async {
    await _firestoreService.updateMember(groupId, memberId, {'role': newRole});

    await logActivity(
      groupId: groupId,
      userId: changedById,
      userName: changedByName,
      userColor: changedByColor,
      action: AppConstants.actionRoleChanged,
      details: {
        'targetId': memberId,
        'targetName': memberName,
        'newRole': newRole,
      },
    );

    // Notify the target member
    try {
      final userDoc = await _firestoreService.getUser(memberId);
      final token = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];
      if (token != null && token.isNotEmpty) {
        final groupDoc = await _firestoreService.getGroup(groupId);
        final groupName = (groupDoc.data() as Map<String, dynamic>?)?['name'] ?? 'the group';
        await _notificationService.sendNotification(
          recipientTokens: [token],
          title: 'Role Updated 🎖️',
          body: 'Your role in "$groupName" has been changed to $newRole by $changedByName.',
        );
      }
    } catch (e) {
      debugPrint('Error sending role change notification: $e');
    }
  }

  /// Remove a member from a group (soft remove).
  Future<void> removeMember({
    required String groupId,
    required String memberId,
    required String memberName,
    required String removedByName,
    required String removedByColor,
    required String removedById,
  }) async {
    await _firestoreService.updateMember(
      groupId,
      memberId,
      {'status': AppConstants.statusRemoved},
    );

    // Decrement member count
    await _firestoreService.incrementField(
      AppConstants.groupsCollection,
      groupId,
      'memberCount',
      -1,
    );

    await logActivity(
      groupId: groupId,
      userId: removedById,
      userName: removedByName,
      userColor: removedByColor,
      action: AppConstants.actionMemberRemoved,
      details: {'memberName': memberName, 'memberId': memberId},
    );

    // Notify the removed member
    try {
      final userDoc = await _firestoreService.getUser(memberId);
      final token = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];
      if (token != null && token.isNotEmpty) {
        final groupDoc = await _firestoreService.getGroup(groupId);
        final groupName = (groupDoc.data() as Map<String, dynamic>?)?['name'] ?? 'the group';
        await _notificationService.sendNotification(
          recipientTokens: [token],
          title: 'Group Removed 🏠',
          body: 'You have been removed from "$groupName" by $removedByName.',
        );
      }
    } catch (e) {
      debugPrint('Error sending member removal notification: $e');
    }
  }

  /// Delete a group (Super Admin only).
  Future<void> deleteGroup(String groupId) async {
    await _firestoreService.deleteGroup(groupId);
  }

  /// Log an activity event in a group.
  Future<void> logActivity({
    required String groupId,
    required String userId,
    required String userName,
    required String userColor,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    final now = DateTime.now();
    final log = ActivityLogModel(
      logId: _uuid.v4(),
      userId: userId,
      userName: userName,
      userColor: userColor,
      action: action,
      details: details,
      timestamp: now,
      expiresAt: now.add(const Duration(days: 150)),
    );

    await _firestoreService.addActivityLog(groupId, log.toJson());
  }

  /// Stream activity logs for a group.
  Stream<List<ActivityLogModel>> streamActivityLogs(String groupId,
      {int limit = 20}) {
    return _firestoreService
        .streamActivityLogs(groupId, limit: limit)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLogModel.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    });
  }
}
