import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a payment record between two users for a settlement.
/// Stored in Firestore: groups/{groupId}/payments/{paymentId}
class PaymentModel {
  final String paymentId;
  final String settlementMonth;
  final String settlementId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;
  final bool confirmedByReceiver;
  final DateTime paidAt;

  const PaymentModel({
    required this.paymentId,
    required this.settlementMonth,
    required this.settlementId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    this.confirmedByReceiver = false,
    required this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return PaymentModel(
      paymentId: id ?? json['paymentId'] as String,
      settlementMonth: json['settlementMonth'] as String,
      settlementId: json['settlementId'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      amount: (json['amount'] as num).toDouble(),
      confirmedByReceiver: json['confirmedByReceiver'] as bool? ?? false,
      paidAt: (json['paidAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'settlementMonth': settlementMonth,
        'settlementId': settlementId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'amount': amount,
        'confirmedByReceiver': confirmedByReceiver,
        'paidAt': Timestamp.fromDate(paidAt),
      };

  PaymentModel copyWith({bool? confirmedByReceiver}) {
    return PaymentModel(
      paymentId: paymentId,
      settlementMonth: settlementMonth,
      settlementId: settlementId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      amount: amount,
      confirmedByReceiver: confirmedByReceiver ?? this.confirmedByReceiver,
      paidAt: paidAt,
    );
  }
}
