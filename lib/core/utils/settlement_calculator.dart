/// Settlement calculator utility.
/// Implements the greedy minimum-transactions algorithm
/// to calculate who owes whom.
library;

/// Represents a single settlement transaction.
class SettlementTransaction {
  final String fromUserId;
  final String fromUserName;
  final String fromUserColor;
  final String toUserId;
  final String toUserName;
  final String toUserColor;
  final double amount;

  const SettlementTransaction({
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserColor,
    required this.toUserId,
    required this.toUserName,
    required this.toUserColor,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserColor': fromUserColor,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'toUserColor': toUserColor,
        'amount': amount,
      };

  factory SettlementTransaction.fromJson(Map<String, dynamic> json) {
    return SettlementTransaction(
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      fromUserColor: json['fromUserColor'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      toUserColor: json['toUserColor'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// Represents the full settlement result for a month.
class SettlementResult {
  final double totalAmount;
  final double fairShare;
  final int memberCount;
  final Map<String, double> memberTotals; // userId -> total spent
  final Map<String, double> balances; // userId -> balance (positive = gets money)
  final List<SettlementTransaction> transactions;

  const SettlementResult({
    required this.totalAmount,
    required this.fairShare,
    required this.memberCount,
    required this.memberTotals,
    required this.balances,
    required this.transactions,
  });
}

/// Represents a member's identity info (needed for transaction labels).
class MemberInfo {
  final String userId;
  final String name;
  final String color;

  const MemberInfo({
    required this.userId,
    required this.name,
    required this.color,
  });
}

class SettlementCalculator {
  SettlementCalculator._();

  /// Calculates the minimum number of transactions to settle all balances.
  ///
  /// [memberTotals] = {userId: total amount that user spent this month}
  /// [memberInfos] = {userId: MemberInfo} for display names and colors
  ///
  /// Returns a [SettlementResult] with all calculations.
  static SettlementResult calculate({
    required Map<String, double> memberTotals,
    required Map<String, MemberInfo> memberInfos,
  }) {
    // If no expenses or only one member, return empty settlement
    if (memberTotals.isEmpty) {
      return const SettlementResult(
        totalAmount: 0,
        fairShare: 0,
        memberCount: 0,
        memberTotals: {},
        balances: {},
        transactions: [],
      );
    }

    final memberCount = memberInfos.length;
    final totalAmount = memberTotals.values.fold(0.0, (sum, v) => sum + v);
    final fairShare = totalAmount / memberCount;

    // Calculate each member's balance (spent - fairShare)
    // Positive = overpaid (creditor, gets money back)
    // Negative = underpaid (debtor, owes money)
    final balances = <String, double>{};
    for (final userId in memberInfos.keys) {
      final spent = memberTotals[userId] ?? 0.0;
      balances[userId] = spent - fairShare;
    }

    // Separate into creditors (positive balance) and debtors (negative balance)
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        creditors.add(entry);
      } else if (entry.value < -0.01) {
        debtors.add(entry);
      }
    }

    // Sort: largest creditor first, largest debtor first
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => a.value.compareTo(b.value)); // most negative first

    // Greedy algorithm to minimize number of transactions
    final transactions = <SettlementTransaction>[];
    int ci = 0, di = 0;
    final cBal = creditors.map((e) => e.value).toList();
    final dBal = debtors.map((e) => e.value.abs()).toList();

    while (ci < creditors.length && di < debtors.length) {
      final transferAmount =
          cBal[ci] < dBal[di] ? cBal[ci] : dBal[di];

      if (transferAmount > 0.01) {
        final fromInfo = memberInfos[debtors[di].key]!;
        final toInfo = memberInfos[creditors[ci].key]!;

        transactions.add(SettlementTransaction(
          fromUserId: fromInfo.userId,
          fromUserName: fromInfo.name,
          fromUserColor: fromInfo.color,
          toUserId: toInfo.userId,
          toUserName: toInfo.name,
          toUserColor: toInfo.color,
          amount: double.parse(transferAmount.toStringAsFixed(2)),
        ));
      }

      cBal[ci] -= transferAmount;
      dBal[di] -= transferAmount;

      if (cBal[ci] < 0.01) ci++;
      if (dBal[di] < 0.01) di++;
    }

    return SettlementResult(
      totalAmount: double.parse(totalAmount.toStringAsFixed(2)),
      fairShare: double.parse(fairShare.toStringAsFixed(2)),
      memberCount: memberCount,
      memberTotals: memberTotals,
      balances: balances.map((k, v) =>
          MapEntry(k, double.parse(v.toStringAsFixed(2)))),
      transactions: transactions,
    );
  }
}
