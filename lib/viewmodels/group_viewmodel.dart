import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import '../models/user_model.dart';
import '../repositories/group_repository.dart';
import '../core/utils/date_helper.dart';

/// ViewModel for group-level operations.
/// Used by HomeScreen, CreateGroupScreen, GroupDetailScreen.
class GroupViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;

  GroupViewModel(this._groupRepository);

  // ─── State ──────────────────────────────────────────────────
  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  MemberModel? _currentMember;
  String _selectedMonth = DateHelper.currentSettlementKey;
  bool _isLoading = false;
  String? _error;

  // ─── Getters ────────────────────────────────────────────────
  List<GroupModel> get groups => _groups;
  GroupModel? get selectedGroup => _selectedGroup;
  MemberModel? get currentMember => _currentMember;
  String get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Navigation ─────────────────────────────────────────────
  
  void changeMonth(int offset) {
    final parts = _selectedMonth.split('-');
    final current = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final next = DateTime(current.year, current.month + offset);
    
    // Don't allow future months
    if (next.isAfter(DateTime.now())) return;
    
    _selectedMonth = DateHelper.settlementKey(next);
    notifyListeners();
  }

  // ─── Loading & Error Helpers ────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Group Operations ─────────────────────────────────────

  /// Listen to the user's groups in real-time.
  void loadUserGroups(String userId) {
    _setLoading(true);
    _groupRepository.streamUserGroups(userId).listen(
      (groups) {
        _groups = groups;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _setError('Failed to load groups.');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Create a new group.
  Future<GroupModel?> createGroup({
    required String name,
    String? iconEmoji,
    required UserModel creator,
  }) async {
    try {
      _setLoading(true);
      final group = await _groupRepository.createGroup(
        name: name,
        iconEmoji: iconEmoji,
        creator: creator,
      );
      _setLoading(false);
      return group;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create group.');
      return null;
    }
  }

  /// Select a group and load the current user's member info.
  Future<void> selectGroup(GroupModel group, String userId) async {
    _selectedGroup = group;
    notifyListeners();

    // Load current member info for permissions
    _currentMember = await _groupRepository.getCurrentMember(
      group.groupId,
      userId,
    );
    notifyListeners();
  }

  /// Fetch a specific group by ID (for deep links or refresh).
  Future<void> fetchGroup(String groupId, String userId) async {
    try {
      final group = await _groupRepository.getGroup(groupId);
      if (group != null) {
        await selectGroup(group, userId);
      }
    } catch (e) {
      _setError('Failed to fetch group details.');
    }
  }

  /// Change a member's role.
  Future<bool> changeMemberRole({
    required String groupId,
    required String memberId,
    required String memberName,
    required String newRole,
    required UserModel changedBy,
  }) async {
    try {
      await _groupRepository.changeMemberRole(
        groupId: groupId,
        memberId: memberId,
        memberName: memberName,
        newRole: newRole,
        changedByName: changedBy.name,
        changedByColor: changedBy.color,
        changedById: changedBy.uid,
      );
      return true;
    } catch (e) {
      _setError('Failed to change role.');
      return false;
    }
  }

  /// Remove a member from a group.
  Future<bool> removeMember({
    required String groupId,
    required String memberId,
    required String memberName,
    required UserModel removedBy,
  }) async {
    try {
      await _groupRepository.removeMember(
        groupId: groupId,
        memberId: memberId,
        memberName: memberName,
        removedByName: removedBy.name,
        removedByColor: removedBy.color,
        removedById: removedBy.uid,
      );
      return true;
    } catch (e) {
      _setError('Failed to remove member.');
      return false;
    }
  }

  /// Delete a group (Super Admin only).
  Future<bool> deleteGroup(String groupId) async {
    try {
      _setLoading(true);
      await _groupRepository.deleteGroup(groupId);
      _selectedGroup = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete group.');
      return false;
    }
  }

  /// Leave a group (Soft remove for self).
  Future<bool> leaveGroup(String groupId, UserModel user) async {
    try {
      _setLoading(true);
      // We need the member name for activity logging
      final member = await _groupRepository.getCurrentMember(groupId, user.uid);
      if (member == null) {
        _setLoading(false);
        return false;
      }

      await _groupRepository.removeMember(
        groupId: groupId,
        memberId: user.uid,
        memberName: member.name,
        removedByName: user.name,
        removedByColor: user.color,
        removedById: user.uid,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to leave group.');
      return false;
    }
  }
}
