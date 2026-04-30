import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../repositories/group_repository.dart';
import '../services/notification_service.dart';

/// ViewModel for expense-related operations.
/// Used by expense list, add/edit/delete screens.
class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository;
  final GroupRepository _groupRepository;
  final NotificationService _notificationService;

  ExpenseViewModel(this._expenseRepository, this._groupRepository, this._notificationService);

  // ─── State ──────────────────────────────────────────────────
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;
  double _currentMonthTotal = 0;
  StreamSubscription? _expenseSubscription;

  // ─── Getters ────────────────────────────────────────────────
  List<ExpenseModel> get expenses => _expenses;

  /// Non-deleted expenses only (for normal views).
  List<ExpenseModel> get activeExpenses =>
      _expenses.where((e) => !e.isDeleted).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  double get currentMonthTotal => _currentMonthTotal;

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

  // ─── Expense Operations ───────────────────────────────────

  /// Start listening to expenses for a group in real-time.
  void loadExpenses(String groupId) {
    _setLoading(true);
    _expenseSubscription?.cancel();
    _expenseSubscription =
        _expenseRepository.streamExpenses(groupId).listen(
      (expenses) {
        _expenses = expenses;
        // Calculate current month total from non-deleted expenses
        final now = DateTime.now();
        _currentMonthTotal = expenses
            .where((e) =>
                !e.isDeleted &&
                e.timestamp.month == now.month &&
                e.timestamp.year == now.year)
            .fold(0.0, (sum, e) => sum + e.amount);
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _setError('Failed to load expenses.');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Add a new expense.
  Future<bool> addExpense({
    required String groupId,
    required String itemName,
    required double amount,
    required String addedById,
    required String addedByName,
    required String addedByColor,
  }) async {
    try {
      _setLoading(true);

      final expenseId = await _expenseRepository.addExpense(
        groupId: groupId,
        itemName: itemName,
        amount: amount,
        addedById: addedById,
        addedByName: addedByName,
        addedByColor: addedByColor,
      );

      // Log activity
      await _groupRepository.logActivity(
        groupId: groupId,
        userId: addedById,
        userName: addedByName,
        userColor: addedByColor,
        action: AppConstants.actionAddExpense,
        details: {
          'expenseId': expenseId,
          'itemName': itemName,
          'amount': amount,
        },
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to add expense.');
      return false;
    }
  }

  /// Edit an existing expense.
  Future<bool> editExpense({
    required String groupId,
    required ExpenseModel expense,
    required String newItemName,
    required double newAmount,
    required String editedById,
    required String editedByName,
    required String editedByColor,
  }) async {
    try {
      _setLoading(true);

      await _expenseRepository.editExpense(
        groupId: groupId,
        expenseId: expense.expenseId,
        newItemName: newItemName,
        newAmount: newAmount,
        oldItemName: expense.itemName,
        oldAmount: expense.amount,
        editedBy: editedById,
        editedByName: editedByName,
      );

      // Log activity
      await _groupRepository.logActivity(
        groupId: groupId,
        userId: editedById,
        userName: editedByName,
        userColor: editedByColor,
        action: AppConstants.actionEditExpense,
        details: {
          'expenseId': expense.expenseId,
          'itemName': newItemName,
          'oldAmount': expense.amount,
          'newAmount': newAmount,
          'oldItemName': expense.itemName,
        },
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to edit expense.');
      return false;
    }
  }

  /// Soft-delete an expense.
  Future<bool> deleteExpense({
    required String groupId,
    required ExpenseModel expense,
    required String deletedById,
    required String deletedByName,
    required String deletedByColor,
  }) async {
    try {
      await _expenseRepository.deleteExpense(
        groupId: groupId,
        expenseId: expense.expenseId,
        itemName: expense.itemName,
        deletedBy: deletedById,
        deletedByName: deletedByName,
      );

      // Log activity
      await _groupRepository.logActivity(
        groupId: groupId,
        userId: deletedById,
        userName: deletedByName,
        userColor: deletedByColor,
        action: AppConstants.actionDeleteExpense,
        details: {
          'expenseId': expense.expenseId,
          'itemName': expense.itemName,
          'amount': expense.amount,
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to delete expense.');
      return false;
    }
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
