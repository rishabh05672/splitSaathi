import 'dart:async';
import 'package:flutter/material.dart';
import '../models/settlement_model.dart';
import '../models/payment_model.dart';
import '../models/member_model.dart';
import '../repositories/settlement_repository.dart';
import '../repositories/group_repository.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_helper.dart';

import '../models/expense_model.dart';
import '../core/utils/settlement_calculator.dart';
import '../repositories/expense_repository.dart';

/// ViewModel for settlement and payment flows.
class SettlementViewModel extends ChangeNotifier {
  final SettlementRepository _repo;
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;

  SettlementViewModel(this._repo, this._groupRepo, this._expenseRepo);

  SettlementModel? _settlement;
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _error;
  String _selectedMonth = DateHelper.currentSettlementKey;

  StreamSubscription<SettlementModel?>? _settlementSub;
  StreamSubscription<List<PaymentModel>>? _paymentSub;
  StreamSubscription<List<ExpenseModel>>? _expenseSub;
  StreamSubscription<List<MemberModel>>? _memberSub;
  
  List<MemberModel> _members = [];
  List<ExpenseModel> _expenses = [];

  SettlementModel? get settlement => _settlement;
  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedMonth => _selectedMonth;

  void setMonth(String month) { _selectedMonth = month; notifyListeners(); }

  void loadSettlement(String groupId, String month) {
    _isLoading = true;
    _settlementSub?.cancel();
    _paymentSub?.cancel();
    _expenseSub?.cancel();
    _memberSub?.cancel();

    // 1. Listen to members (needed for live calculation)
    _memberSub = _groupRepo.streamMembers(groupId).listen((members) {
      _members = members;
      _triggerLiveRecalculation(groupId, _selectedMonth);
    });

    // 2. Listen to official settlement document
    _settlementSub = _repo.streamSettlement(groupId, month).listen((settlement) {
      // If we are in the current month, we might prefer the live calculation
      // but let's keep the official one as a base if it exists
      if (settlement != null) {
         _settlement = settlement;
         notifyListeners();
      }
      _isLoading = false;
    });

    // 3. Listen to expenses for live tracking
    _expenseSub = _expenseRepo.streamExpenses(groupId).listen((expenses) {
       _expenses = expenses;
       _triggerLiveRecalculation(groupId, _selectedMonth);
    });

    _repo.getMonthPayments(groupId, month).then((payments) {
      _payments = payments;
      notifyListeners();
    });
  }

  void _triggerLiveRecalculation(String groupId, String monthKey) {
    if (_members.isEmpty) return;

    // Filter expenses for selected month
    final monthStart = DateTime(int.parse(monthKey.split('-')[0]), int.parse(monthKey.split('-')[1]), 1);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

    final monthExpenses = _expenses.where((e) {
      return !e.isDeleted &&
             e.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
             e.timestamp.isBefore(monthEnd);
    }).toList();

    if (monthExpenses.isEmpty) {
      // If we don't have an official settlement from Firestore, clear the live one
      // If we do have one, keep it as the source of truth
      if (_settlement?.settlementId.startsWith('live-') ?? true) {
         _settlement = null;
         notifyListeners();
      }
      return;
    }

    // Sum up totals
    final memberTotals = <String, double>{};
    for (final expense in monthExpenses) {
      memberTotals[expense.addedById] = (memberTotals[expense.addedById] ?? 0) + expense.amount;
    }

    final memberInfos = <String, MemberInfo>{};
    for (final m in _members) {
      memberInfos[m.userId] = MemberInfo(userId: m.userId, name: m.name, color: m.color);
    }

    final result = SettlementCalculator.calculate(memberTotals: memberTotals, memberInfos: memberInfos);

    // Update the local settlement object in real-time
    _settlement = SettlementModel(
      settlementId: 'live-$monthKey',
      groupId: groupId,
      month: monthKey,
      totalAmount: result.totalAmount,
      fairShare: result.fairShare,
      memberCount: result.memberCount,
      memberTotals: result.memberTotals,
      balances: result.balances,
      transactions: result.transactions.map((t) => TransactionModel.fromSettlementTransaction(t)).toList(),
      calculatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 150)),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _settlementSub?.cancel();
    _paymentSub?.cancel();
    _expenseSub?.cancel();
    _memberSub?.cancel();
    super.dispose();
  }

  Future<bool> calculateSettlement({
    required String groupId, required DateTime monthDate, required List<MemberModel> members,
    required String userId, required String userName, required String userColor,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      _settlement = await _repo.calculateSettlement(
        groupId: groupId, monthDate: monthDate, activeMembers: members,
      );
      if (_settlement == null) { _error = 'No expenses for this month.'; _isLoading = false; notifyListeners(); return false; }
      await _groupRepo.logActivity(groupId: groupId, userId: userId, userName: userName, userColor: userColor,
        action: AppConstants.actionSettlementCalculated, details: {'month': DateHelper.settlementKey(monthDate)});
      _isLoading = false; notifyListeners(); return true;
    } catch (e) { _error = 'Failed to calculate settlement.'; _isLoading = false; notifyListeners(); return false; }
  }

  Future<bool> markAsPaid({required String groupId, required PaymentModel payment}) async {
    try {
      await _repo.createPayment(groupId: groupId, payment: payment);
      await _groupRepo.logActivity(groupId: groupId, userId: payment.fromUserId, userName: payment.fromUserName, userColor: '',
        action: AppConstants.actionPaymentMade, details: {'amount': payment.amount, 'toUserName': payment.toUserName});
      return true;
    } catch (e) { _error = 'Failed to record payment.'; notifyListeners(); return false; }
  }

  Future<bool> confirmPayment({
    required String groupId,
    required String paymentId,
    required String receiverName,
  }) async {
    try {
      await _repo.confirmPayment(
        groupId: groupId,
        paymentId: paymentId,
        receiverName: receiverName,
      );
      return true;
    } catch (e) {
      _error = 'Failed to confirm payment.';
      notifyListeners();
      return false;
    }
  }
}
