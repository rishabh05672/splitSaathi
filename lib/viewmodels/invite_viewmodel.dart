import 'package:flutter/material.dart';
import '../models/invite_model.dart';
import '../models/user_model.dart';
import '../repositories/invite_repository.dart';
import '../repositories/group_repository.dart';
import '../core/constants/app_constants.dart';

/// ViewModel for invite and join request flows.
class InviteViewModel extends ChangeNotifier {
  final InviteRepository _inviteRepository;
  final GroupRepository _groupRepository;

  InviteViewModel(this._inviteRepository, this._groupRepository);

  // ─── State ──────────────────────────────────────────────────
  InviteModel? _currentInvite;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  List<Map<String, dynamic>> _joinRequests = [];

  // ─── Getters ────────────────────────────────────────────────
  InviteModel? get currentInvite => _currentInvite;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  List<Map<String, dynamic>> get joinRequests => _joinRequests;

  // ─── Helpers ────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // ─── Invite Operations ────────────────────────────────────

  /// Generate a new invite link.
  Future<InviteModel?> generateInvite({
    required String groupId,
    required String groupName,
    required String createdBy,
  }) async {
    try {
      _setLoading(true);
      _currentInvite = await _inviteRepository.generateInvite(
        groupId: groupId,
        groupName: groupName,
        createdBy: createdBy,
      );
      _setLoading(false);
      return _currentInvite;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to generate invite link.');
      return null;
    }
  }

  /// Share the current invite link.
  Future<void> shareInvite(String groupName) async {
    if (_currentInvite == null) return;
    await _inviteRepository.shareInviteLink(
      _currentInvite!.token,
      groupName,
    );
  }

  /// Validate an invite token.
  Future<InviteModel?> validateToken(String token) async {
    try {
      _setLoading(true);
      _setError(null);
      _currentInvite = await _inviteRepository.validateInvite(token);
      _setLoading(false);
      return _currentInvite;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return null;
    }
  }

  /// Submit a join request after validating.
  Future<bool> submitJoinRequest({
    required String groupId,
    required UserModel user,
    required String token,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Check if already a member
      final isMember = await _inviteRepository.isAlreadyMember(groupId, user.uid);
      if (isMember) {
        _setLoading(false);
        _setError('You are already a member of this group.');
        return false;
      }

      // Check for pending request
      final hasPending =
          await _inviteRepository.hasPendingRequest(groupId, user.uid);
      if (hasPending) {
        _setLoading(false);
        _setError('You already have a pending request for this group.');
        return false;
      }

      await _inviteRepository.submitJoinRequest(
        groupId: groupId,
        user: user,
        token: token,
      );

      _successMessage = 'Request sent! Waiting for admin approval.';
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to send join request.');
      return false;
    }
  }

  /// Stream pending join requests for admin management.
  void loadJoinRequests(String groupId) {
    _inviteRepository.streamJoinRequests(groupId).listen(
      (requests) {
        _joinRequests = requests;
        notifyListeners();
      },
    );
  }

  /// Approve a join request.
  Future<bool> approveRequest({
    required String groupId,
    required String requestId,
    required Map<String, dynamic> requestData,
    required UserModel approvedBy,
  }) async {
    try {
      // Approve the request
      await _inviteRepository.approveRequest(
        groupId: groupId,
        requestId: requestId,
      );

      // Fetch user model and add as member
      final userModel = UserModel(
        uid: requestData['userId'] as String,
        name: requestData['userName'] as String,
        email: '', // Not needed for member creation
        color: requestData['userColor'] as String,
        photoUrl: requestData['userPhotoUrl'] as String?,
        createdAt: DateTime.now(),
      );

      await _groupRepository.addMember(
        groupId: groupId,
        user: userModel,
        role: AppConstants.roleViewer,
      );

      // Log activity
      await _groupRepository.logActivity(
        groupId: groupId,
        userId: approvedBy.uid,
        userName: approvedBy.name,
        userColor: approvedBy.color,
        action: AppConstants.actionMemberApproved,
        details: {
          'memberName': requestData['userName'],
          'memberId': requestData['userId'],
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to approve request.');
      return false;
    }
  }

  /// Decline a join request.
  Future<bool> declineRequest({
    required String groupId,
    required String requestId,
    required Map<String, dynamic> requestData,
    required UserModel declinedBy,
  }) async {
    try {
      await _inviteRepository.declineRequest(
        groupId: groupId,
        requestId: requestId,
      );

      // Log activity
      await _groupRepository.logActivity(
        groupId: groupId,
        userId: declinedBy.uid,
        userName: declinedBy.name,
        userColor: declinedBy.color,
        action: AppConstants.actionMemberDeclined,
        details: {
          'memberName': requestData['userName'],
          'memberId': requestData['userId'],
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to decline request.');
      return false;
    }
  }

  /// Add member by email directly.
  Future<bool> addMemberByEmail({
    required String groupId,
    required String email,
    required UserModel addedBy,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final errorMsg = await _groupRepository.addMemberByEmail(
        groupId: groupId,
        email: email,
        addedBy: addedBy,
      );

      if (errorMsg != null) {
        _setLoading(false);
        _setError(errorMsg);
        return false;
      }

      _successMessage = 'Member added successfully!';
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to add member by email.');
      return false;
    }
  }
}
