import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/group_repository.dart';
import '../core/utils/date_helper.dart';

/// ViewModel for Global Dashboard data aggregation.
class GlobalDashboardViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository;
  final GroupRepository _groupRepository;

  GlobalDashboardViewModel(this._expenseRepository, this._groupRepository) {
    _selectedMonth = DateHelper.currentSettlementKey;
  }

  // ─── State ──────────────────────────────────────────────────
  String _selectedMonth = '';
  Map<String, double> _memberTotals = {};
  Map<String, String> _memberNames = {};
  Map<String, String> _memberColors = {};
  Map<String, double> _groupTotals = {};
  Map<String, String> _groupNames = {};
  double _totalSpending = 0;
  bool _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────
  String get selectedMonth => _selectedMonth;
  Map<String, double> get memberTotals => _memberTotals;
  Map<String, String> get memberNames => _memberNames;
  Map<String, String> get memberColors => _memberColors;
  Map<String, double> get groupTotals => _groupTotals;
  Map<String, String> get groupNames => _groupNames;
  double get totalSpending => _totalSpending;
  bool get isLoading => _isLoading;

  // ─── Actions ────────────────────────────────────────────────

  void changeMonth(int offset, String userId) {
    final parts = _selectedMonth.split('-');
    final current = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final next = DateTime(current.year, current.month + offset);
    
    // 150 days limit check (~5 months)
    final now = DateTime.now();
    final fiveMonthsAgo = DateTime(now.year, now.month - 5);
    
    if (next.isBefore(fiveMonthsAgo)) return;
    if (next.isAfter(now)) return;

    _selectedMonth = DateHelper.settlementKey(next);
    notifyListeners();
    loadGlobalData(userId);
  }

  Future<void> loadGlobalData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final groups = await _groupRepository.streamUserGroups(userId).first;
      double total = 0;
      final Map<String, double> memberTotalsMap = {};
      final Map<String, String> memberNamesMap = {};
      final Map<String, String> memberColorsMap = {};
      final Map<String, double> groupTotalsMap = {};
      final Map<String, String> groupNamesMap = {};

      final monthParts = _selectedMonth.split('-');
      final monthStart = DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]), 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

      // Fetch expenses for each group in parallel
      final List<Future<void>> futures = [];

      for (var group in groups) {
        groupNamesMap[group.groupId] = group.name;
        futures.add(
          _expenseRepository.streamExpenses(group.groupId).first.then((expenses) {
            final monthExpenses = expenses.where((e) => 
              !e.isDeleted &&
              e.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
              e.timestamp.isBefore(monthEnd)
            );

            double groupSubtotal = 0;
            for (var exp in monthExpenses) {
              total += exp.amount;
              groupSubtotal += exp.amount;
              memberTotalsMap[exp.addedById] = (memberTotalsMap[exp.addedById] ?? 0) + exp.amount;
              memberNamesMap[exp.addedById] = exp.addedByName;
              memberColorsMap[exp.addedById] = exp.addedByColor;
            }
            groupTotalsMap[group.groupId] = groupSubtotal;
          })
        );
      }

      await Future.wait(futures);

      _totalSpending = total;
      _memberTotals = memberTotalsMap;
      _memberNames = memberNamesMap;
      _memberColors = memberColorsMap;
      _groupTotals = groupTotalsMap;
      _groupNames = groupNamesMap;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
