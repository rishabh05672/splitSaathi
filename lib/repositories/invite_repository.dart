import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/invite_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/invite_service.dart';

/// Repository for invite and join request flows.
class InviteRepository {
  final FirestoreService _firestoreService;
  final InviteService _inviteService;

  InviteRepository(this._firestoreService, this._inviteService);

  /// Generate a new invite link for a group.
  Future<InviteModel> generateInvite({
    required String groupId,
    required String groupName,
    required String createdBy,
  }) async {
    return await _inviteService.generateInvite(
      groupId: groupId,
      groupName: groupName,
      createdBy: createdBy,
    );
  }

  /// Validate an invite token.
  Future<InviteModel> validateInvite(String token) async {
    return await _inviteService.validateInvite(token);
  }

  /// Share an invite link.
  Future<void> shareInviteLink(String token, String groupName) async {
    await _inviteService.shareInviteLink(token, groupName);
  }

  /// Check if a user is already a member of a group.
  Future<bool> isAlreadyMember(String groupId, String userId) async {
    final doc = await _firestoreService.getMember(groupId, userId);
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['status'] == AppConstants.statusActive;
  }

  /// Check if user already has a pending join request.
  Future<bool> hasPendingRequest(String groupId, String userId) async {
    final snapshot =
        await _firestoreService.getUserPendingRequests(groupId, userId);
    return snapshot.docs.isNotEmpty;
  }

  /// Submit a join request.
  Future<void> submitJoinRequest({
    required String groupId,
    required UserModel user,
    required String token,
  }) async {
    // Create join request
    await _firestoreService.createJoinRequest(groupId, {
      'userId': user.uid,
      'userName': user.name,
      'userColor': user.color,
      'userPhotoUrl': user.photoUrl,
      'requestedAt': Timestamp.fromDate(DateTime.now()),
      'status': AppConstants.requestPending,
    });

    // Increment invite used count
    await _inviteService.incrementUsedCount(token);
  }

  /// Stream pending join requests for a group.
  Stream<List<Map<String, dynamic>>> streamJoinRequests(String groupId) {
    return _firestoreService.streamJoinRequests(groupId).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['requestId'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Approve a join request.
  Future<void> approveRequest({
    required String groupId,
    required String requestId,
  }) async {
    await _firestoreService.updateJoinRequest(groupId, requestId, {
      'status': AppConstants.requestApproved,
    });
  }

  /// Decline a join request.
  Future<void> declineRequest({
    required String groupId,
    required String requestId,
  }) async {
    await _firestoreService.updateJoinRequest(groupId, requestId, {
      'status': AppConstants.requestDeclined,
    });
  }
}
