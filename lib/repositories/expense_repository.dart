import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'group_repository.dart';

/// Repository for expense CRUD operations.
class ExpenseRepository {
  final FirestoreService _firestoreService;
  final GroupRepository _groupRepository;
  final NotificationService _notificationService;

  ExpenseRepository(
    this._firestoreService,
    this._groupRepository,
    this._notificationService,
  );

  /// Add a new expense to a group. Returns the expense ID.
  Future<String> addExpense({
    required String groupId,
    required String itemName,
    required double amount,
    required String addedById,
    required String addedByName,
    required String addedByColor,
  }) async {
    final now = DateTime.now();
    final expense = ExpenseModel(
      expenseId: '', // Set from Firestore
      itemName: itemName,
      amount: amount,
      addedById: addedById,
      addedByName: addedByName,
      addedByColor: addedByColor,
      timestamp: now,
      expiresAt: now.add(const Duration(days: 150)),
      isDeleted: false,
    );

    final docRef =
        await _firestoreService.addExpense(groupId, expense.toJson());

    // Send Notification to other members
    try {
      final tokens = await _groupRepository.getGroupMemberTokens(groupId, addedById);
      if (tokens.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientTokens: tokens,
          title: 'New Expense 💸',
          body: '$addedByName added ₹${amount.toStringAsFixed(0)} for "$itemName".',
        );
      }
    } catch (e) {
      print('Error sending add expense notification: $e');
    }

    return docRef.id;
  }

  /// Edit an existing expense. Adds an entry to the edit history.
  Future<void> editExpense({
    required String groupId,
    required String expenseId,
    required String newItemName,
    required double newAmount,
    required String oldItemName,
    required double oldAmount,
    required String editedBy,
    required String editedByName,
  }) async {
    final editEntry = EditHistory(
      editedBy: editedBy,
      editedByName: editedByName,
      oldAmount: oldAmount,
      newAmount: newAmount,
      oldItemName: oldItemName,
      newItemName: newItemName,
      editedAt: DateTime.now(),
    );

    await _firestoreService.updateExpense(groupId, expenseId, {
      'itemName': newItemName,
      'amount': newAmount,
      'editHistory': FieldValue.arrayUnion([editEntry.toJson()]),
    });

    // Send Notification to other members
    try {
      final tokens = await _groupRepository.getGroupMemberTokens(groupId, editedBy);
      if (tokens.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientTokens: tokens,
          title: 'Expense Updated ✏️',
          body: '$editedByName updated "$newItemName" to ₹${newAmount.toStringAsFixed(0)}.',
        );
      }
    } catch (e) {
      print('Error sending edit expense notification: $e');
    }
  }

  /// Soft-delete an expense (set isDeleted = true).
  Future<void> deleteExpense({
    required String groupId,
    required String expenseId,
    required String itemName,
    required String deletedBy,
    required String deletedByName,
  }) async {
    await _firestoreService.updateExpense(groupId, expenseId, {
      'isDeleted': true,
      'deletedBy': deletedBy,
    });

    // Send Notification to other members
    try {
      final tokens = await _groupRepository.getGroupMemberTokens(groupId, deletedBy);
      if (tokens.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientTokens: tokens,
          title: 'Expense Removed 🗑️',
          body: '$deletedByName removed the expense: "$itemName".',
        );
      }
    } catch (e) {
      print('Error sending delete expense notification: $e');
    }
  }

  /// Stream all expenses for a group (real-time).
  Stream<List<ExpenseModel>> streamExpenses(String groupId) {
    return _firestoreService.streamExpenses(groupId).map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    });
  }

  /// Get the total amount of non-deleted expenses for the current month.
  Future<double> getCurrentMonthTotal(String groupId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final snapshot = await _firestoreService.getMonthExpenses(
      groupId,
      monthStart,
      monthEnd,
    );

    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num).toDouble();
    }
    return total;
  }
}
