import 'dart:async';
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../repositories/group_repository.dart';

/// ViewModel for member-related operations.
class MemberViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;

  MemberViewModel(this._groupRepository);

  List<MemberModel> _members = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _sub;

  List<MemberModel> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadMembers(String groupId) {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _groupRepository.streamMembers(groupId).listen(
      (m) { _members = m; _isLoading = false; notifyListeners(); },
      onError: (_) { _error = 'Failed to load members.'; _isLoading = false; notifyListeners(); },
    );
  }

  MemberModel? getMemberById(String userId) {
    try { return _members.firstWhere((m) => m.userId == userId); } catch (_) { return null; }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
