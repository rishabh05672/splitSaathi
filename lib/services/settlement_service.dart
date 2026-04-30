import '../core/utils/settlement_calculator.dart';
import '../models/expense_model.dart';
import '../models/member_model.dart';
import '../models/settlement_model.dart';
import '../core/utils/date_helper.dart';
import 'firestore_service.dart';

/// Service for calculating and saving monthly settlements.
class SettlementService {
  final FirestoreService _firestoreService;

  SettlementService(this._firestoreService);

  /// Calculate settlement for a given month and save to Firestore.
  /// Returns the calculated SettlementModel, or null if no expenses.
  Future<SettlementModel?> calculateAndSaveSettlement({
    required String groupId,
    required DateTime monthDate,
    required List<MemberModel> activeMembers,
  }) async {
    // Determine month boundaries
    final monthStart = DateTime(monthDate.year, monthDate.month, 1);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 1);
    final monthKey = DateHelper.settlementKey(monthDate);

    // Fetch expenses for this month
    final expenseSnapshot = await _firestoreService.getMonthExpenses(
      groupId,
      monthStart,
      monthEnd,
    );

    if (expenseSnapshot.docs.isEmpty) return null;

    // Parse expenses
    final expenses = expenseSnapshot.docs
        .map((doc) => ExpenseModel.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();

    // Sum up each member's total spending
    final memberTotals = <String, double>{};
    for (final expense in expenses) {
      memberTotals[expense.addedById] =
          (memberTotals[expense.addedById] ?? 0) + expense.amount;
    }

    // Build member info map
    final memberInfos = <String, MemberInfo>{};
    for (final member in activeMembers) {
      memberInfos[member.userId] = MemberInfo(
        userId: member.userId,
        name: member.name,
        color: member.color,
      );
    }

    // Calculate settlement
    final result = SettlementCalculator.calculate(
      memberTotals: memberTotals,
      memberInfos: memberInfos,
    );

    final now = DateTime.now();
    // Build and save SettlementModel
    final settlement = SettlementModel(
      settlementId: monthKey,
      groupId: groupId,
      month: monthKey,
      totalAmount: result.totalAmount,
      fairShare: result.fairShare,
      memberCount: result.memberCount,
      memberTotals: result.memberTotals,
      balances: result.balances,
      transactions: result.transactions
          .map((t) => TransactionModel.fromSettlementTransaction(t))
          .toList(),
      calculatedAt: now,
      expiresAt: now.add(const Duration(days: 150)),
    );

    await _firestoreService.setSettlement(
      groupId,
      monthKey,
      settlement.toJson(),
    );

    return settlement;
  }
}
