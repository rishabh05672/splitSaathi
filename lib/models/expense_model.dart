import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an expense item within a group.
/// Stored in Firestore: groups/{groupId}/expenses/{expenseId}
class ExpenseModel {
  final String expenseId;
  final String itemName;
  final double amount;
  final String addedById;
  final String addedByName;
  final String addedByColor;
  final DateTime timestamp;
  final DateTime expiresAt;
  final bool isDeleted;
  final String? deletedBy;
  final List<EditHistory> editHistory;

  const ExpenseModel({
    required this.expenseId,
    required this.itemName,
    required this.amount,
    required this.addedById,
    required this.addedByName,
    required this.addedByColor,
    required this.timestamp,
    required this.expiresAt,
    this.isDeleted = false,
    this.deletedBy,
    this.editHistory = const [],
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final timestamp = (json['timestamp'] as Timestamp).toDate();
    return ExpenseModel(
      expenseId: id ?? json['expenseId'] as String,
      itemName: json['itemName'] as String,
      amount: (json['amount'] as num).toDouble(),
      addedById: json['addedById'] as String,
      addedByName: json['addedByName'] as String,
      addedByColor: json['addedByColor'] as String,
      timestamp: timestamp,
      expiresAt: json['expiresAt'] != null 
          ? (json['expiresAt'] as Timestamp).toDate()
          : timestamp.add(const Duration(days: 150)),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedBy: json['deletedBy'] as String?,
      editHistory: (json['editHistory'] as List<dynamic>?)
              ?.map((e) => EditHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'amount': amount,
        'addedById': addedById,
        'addedByName': addedByName,
        'addedByColor': addedByColor,
        'timestamp': Timestamp.fromDate(timestamp),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isDeleted': isDeleted,
        'deletedBy': deletedBy,
        'editHistory': editHistory.map((e) => e.toJson()).toList(),
      };

  ExpenseModel copyWith({
    String? itemName,
    double? amount,
    bool? isDeleted,
    String? deletedBy,
    List<EditHistory>? editHistory,
    DateTime? expiresAt,
  }) {
    return ExpenseModel(
      expenseId: expenseId,
      itemName: itemName ?? this.itemName,
      amount: amount ?? this.amount,
      addedById: addedById,
      addedByName: addedByName,
      addedByColor: addedByColor,
      timestamp: timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedBy: deletedBy ?? this.deletedBy,
      editHistory: editHistory ?? this.editHistory,
    );
  }
}

/// Represents a single edit history entry for an expense.
class EditHistory {
  final String editedBy;
  final String editedByName;
  final double oldAmount;
  final double newAmount;
  final String oldItemName;
  final String newItemName;
  final DateTime editedAt;

  const EditHistory({
    required this.editedBy,
    required this.editedByName,
    required this.oldAmount,
    required this.newAmount,
    required this.oldItemName,
    required this.newItemName,
    required this.editedAt,
  });

  factory EditHistory.fromJson(Map<String, dynamic> json) {
    return EditHistory(
      editedBy: json['editedBy'] as String,
      editedByName: json['editedByName'] as String,
      oldAmount: (json['oldAmount'] as num).toDouble(),
      newAmount: (json['newAmount'] as num).toDouble(),
      oldItemName: json['oldItemName'] as String,
      newItemName: json['newItemName'] as String,
      editedAt: (json['editedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'editedBy': editedBy,
        'editedByName': editedByName,
        'oldAmount': oldAmount,
        'newAmount': newAmount,
        'oldItemName': oldItemName,
        'newItemName': newItemName,
        'editedAt': Timestamp.fromDate(editedAt),
      };
}
