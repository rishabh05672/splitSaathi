import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/settlement_calculator.dart';

/// Represents a monthly settlement summary for a group.
/// Stored in Firestore: groups/{groupId}/settlements/{YYYY-MM}
class SettlementModel {
  final String settlementId; // Same as month key, e.g., "2025-04"
  final String groupId;
  final String month; // "2025-04"
  final double totalAmount;
  final double fairShare;
  final int memberCount;
  final Map<String, double> memberTotals; // {userId: amount spent}
  final Map<String, double> balances; // {userId: balance}
  final List<TransactionModel> transactions;
  final DateTime calculatedAt;
  final DateTime expiresAt;

  const SettlementModel({
    required this.settlementId,
    required this.groupId,
    required this.month,
    required this.totalAmount,
    required this.fairShare,
    required this.memberCount,
    required this.memberTotals,
    required this.balances,
    required this.transactions,
    required this.calculatedAt,
    required this.expiresAt,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final calculatedAt = (json['calculatedAt'] as Timestamp).toDate();
    return SettlementModel(
      settlementId: id ?? json['settlementId'] as String,
      groupId: json['groupId'] as String? ?? '',
      month: json['month'] as String? ?? id ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      fairShare: (json['fairShare'] as num).toDouble(),
      memberCount: json['memberCount'] as int,
      memberTotals: Map<String, double>.from(
        (json['memberTotals'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      balances: Map<String, double>.from(
        (json['balances'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: calculatedAt,
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : calculatedAt.add(const Duration(days: 150)),
    );
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'month': month,
        'totalAmount': totalAmount,
        'fairShare': fairShare,
        'memberCount': memberCount,
        'memberTotals': memberTotals,
        'balances': balances,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'calculatedAt': Timestamp.fromDate(calculatedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };
}

/// Represents a single settlement transaction between two users.
class TransactionModel {
  final String fromUserId;
  final String fromUserName;
  final String fromUserColor;
  final String toUserId;
  final String toUserName;
  final String toUserColor;
  final double amount;

  const TransactionModel({
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserColor,
    required this.toUserId,
    required this.toUserName,
    required this.toUserColor,
    required this.amount,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      fromUserColor: json['fromUserColor'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      toUserColor: json['toUserColor'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserColor': fromUserColor,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'toUserColor': toUserColor,
        'amount': amount,
      };

  /// Creates from a SettlementTransaction (calculator result).
  factory TransactionModel.fromSettlementTransaction(
      SettlementTransaction st) {
    return TransactionModel(
      fromUserId: st.fromUserId,
      fromUserName: st.fromUserName,
      fromUserColor: st.fromUserColor,
      toUserId: st.toUserId,
      toUserName: st.toUserName,
      toUserColor: st.toUserColor,
      amount: st.amount,
    );
  }
}
