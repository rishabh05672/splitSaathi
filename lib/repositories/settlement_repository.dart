import 'package:flutter/foundation.dart';
import '../models/settlement_model.dart';
import '../models/payment_model.dart';
import '../models/member_model.dart';
import '../services/firestore_service.dart';
import '../services/settlement_service.dart';
import '../services/notification_service.dart';
import '../core/utils/date_helper.dart';
import 'group_repository.dart';

/// Repository for settlement and payment operations.
class SettlementRepository {
  final FirestoreService _firestoreService;
  final SettlementService _settlementService;
  final GroupRepository _groupRepository;
  final NotificationService _notificationService;

  SettlementRepository(
    this._firestoreService,
    this._settlementService,
    this._groupRepository,
    this._notificationService,
  );

  /// Calculate and save settlement for a month.
  Future<SettlementModel?> calculateSettlement({
    required String groupId,
    required DateTime monthDate,
    required List<MemberModel> activeMembers,
  }) async {
    final settlement = await _settlementService.calculateAndSaveSettlement(
      groupId: groupId,
      monthDate: monthDate,
      activeMembers: activeMembers,
    );

    if (settlement != null) {
      // Notify all members that settlement is ready
      try {
        final tokens = await _groupRepository.getGroupMemberTokens(groupId, '');
        if (tokens.isNotEmpty) {
          final monthName = DateHelper.monthYear(monthDate);
          await _notificationService.sendNotification(
            recipientTokens: tokens,
            title: 'Settlement Ready! 📑',
            body: 'Monthly settlement for $monthName has been calculated. Check your balances!',
          );
        }
      } catch (e) {
        // Silent error
      }
    }
    return settlement;
  }

  /// Get a settlement by month key.
  Future<SettlementModel?> getSettlement(
      String groupId, String month) async {
    final doc = await _firestoreService.getSettlement(groupId, month);
    if (!doc.exists) return null;
    return SettlementModel.fromJson(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  /// Stream a settlement document (real-time).
  Stream<SettlementModel?> streamSettlement(String groupId, String month) {
    return _firestoreService.streamSettlement(groupId, month).map((doc) {
      if (!doc.exists) return null;
      return SettlementModel.fromJson(
        doc.data() as Map<String, dynamic>,
        id: doc.id,
      );
    });
  }

  /// Record a payment.
  Future<String> createPayment({
    required String groupId,
    required PaymentModel payment,
  }) async {
    final docRef = await _firestoreService.createPayment(
      groupId,
      payment.toJson(),
    );

    // Notify the receiver
    try {
      final userDoc = await _firestoreService.getUser(payment.toUserId);
      final token = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];
      if (token != null && token.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientTokens: [token],
          title: 'Payment Received! 💰',
          body: '${payment.fromUserName} paid you ₹${payment.amount.toStringAsFixed(0)}.',
        );
      }
    } catch (e) {
      // Silent error
    }

    return docRef.id;
  }

  /// Confirm receipt of a payment.
  Future<void> confirmPayment({
    required String groupId,
    required String paymentId,
    required String receiverName,
  }) async {
    await _firestoreService.updatePayment(groupId, paymentId, {
      'confirmedByReceiver': true,
    });

    // Notify the sender that payment was confirmed
    try {
      final paymentDoc = await _firestoreService.getPayment(groupId, paymentId);
      if (paymentDoc.exists) {
        final payment = PaymentModel.fromJson(
          paymentDoc.data() as Map<String, dynamic>,
          id: paymentDoc.id,
        );
        
        final userDoc = await _firestoreService.getUser(payment.fromUserId);
        final token = (userDoc.data() as Map<String, dynamic>?)?['fcmToken'];
        
        if (token != null && token.isNotEmpty) {
          await _notificationService.sendNotification(
            recipientTokens: [token],
            title: 'Payment Confirmed! ✅',
            body: '$receiverName has confirmed receiving ₹${payment.amount.toStringAsFixed(0)}.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending payment confirmation notification: $e');
    }
  }

  /// Stream payments for a group.
  Stream<List<PaymentModel>> streamPayments(String groupId) {
    return _firestoreService.streamPayments(groupId).map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    });
  }

  /// Get payments for a specific settlement month.
  Future<List<PaymentModel>> getMonthPayments(
      String groupId, String month) async {
    final snapshot = await _firestoreService.getMonthPayments(groupId, month);
    return snapshot.docs
        .map((doc) => PaymentModel.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();
  }
}
