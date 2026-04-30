import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Service layer for all Firestore read/write operations.
/// Centralizes database access; repositories call this service.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Operations ──────────────────────────────────────────

  /// Create or update a user document.
  Future<void> setUser(String userId, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).set(
          data,
          SetOptions(merge: true),
        );
  }

  /// Get a user document by ID.
  Future<DocumentSnapshot> getUser(String userId) async {
    return await _db.collection(AppConstants.usersCollection).doc(userId).get();
  }

  /// Get a user document by Email.
  Future<QuerySnapshot> getUserByEmail(String email) async {
    return await _db
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
  }

  /// Update specific fields on a user document.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).update(data);
  }

  /// Delete a user document.
  Future<void> deleteUser(String userId) async {
    await _db.collection(AppConstants.usersCollection).doc(userId).delete();
  }

  // ─── Group Operations ─────────────────────────────────────────

  /// Create a new group document. Returns the document reference.
  Future<DocumentReference> createGroup(Map<String, dynamic> data) async {
    return await _db.collection(AppConstants.groupsCollection).add(data);
  }

  /// Get a group document by ID.
  Future<DocumentSnapshot> getGroup(String groupId) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .get();
  }

  /// Update a group document.
  Future<void> updateGroup(
      String groupId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .update(data);
  }

  /// Delete a group document.
  Future<void> deleteGroup(String groupId) async {
    await _db.collection(AppConstants.groupsCollection).doc(groupId).delete();
  }

  /// Stream of groups where user is a member (real-time).
  Stream<QuerySnapshot> streamUserGroups(String userId) {
    // We query groups via the members subcollection
    // This requires a collection group query on 'members'
    return _db
        .collectionGroup(AppConstants.membersSubcollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.statusActive)
        .snapshots();
  }

  // ─── Member Operations ────────────────────────────────────────

  /// Add a member to a group.
  Future<void> addMember(
      String groupId, String userId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.membersSubcollection)
        .doc(userId)
        .set(data);
  }

  /// Get a specific member in a group.
  Future<DocumentSnapshot> getMember(String groupId, String userId) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.membersSubcollection)
        .doc(userId)
        .get();
  }

  /// Update a member's data (e.g., role change).
  Future<void> updateMember(
      String groupId, String userId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.membersSubcollection)
        .doc(userId)
        .update(data);
  }

  /// Stream all active members of a group.
  Stream<QuerySnapshot> streamMembers(String groupId) {
    return _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.membersSubcollection)
        .where('status', isEqualTo: AppConstants.statusActive)
        .snapshots();
  }

  /// Get all active members of a group (one-time fetch).
  Future<QuerySnapshot> getMembers(String groupId) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.membersSubcollection)
        .where('status', isEqualTo: AppConstants.statusActive)
        .get();
  }

  // ─── Expense Operations ───────────────────────────────────────

  /// Add an expense to a group.
  Future<DocumentReference> addExpense(
      String groupId, Map<String, dynamic> data) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.expensesSubcollection)
        .add(data);
  }

  /// Update an expense document.
  Future<void> updateExpense(
      String groupId, String expenseId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.expensesSubcollection)
        .doc(expenseId)
        .update(data);
  }

  /// Stream expenses for a group (real-time, ordered by timestamp).
  Stream<QuerySnapshot> streamExpenses(String groupId) {
    return _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.expensesSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get expenses for a specific month (one-time fetch for settlement).
  Future<QuerySnapshot> getMonthExpenses(
      String groupId, DateTime monthStart, DateTime monthEnd) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.expensesSubcollection)
        .where('isDeleted', isEqualTo: false)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(monthEnd))
        .get();
  }

  // ─── Join Request Operations ──────────────────────────────────

  /// Create a join request.
  Future<DocumentReference> createJoinRequest(
      String groupId, Map<String, dynamic> data) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.joinRequestsSubcollection)
        .add(data);
  }

  /// Update a join request (approve/decline).
  Future<void> updateJoinRequest(
      String groupId, String requestId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.joinRequestsSubcollection)
        .doc(requestId)
        .update(data);
  }

  /// Stream pending join requests for a group.
  Stream<QuerySnapshot> streamJoinRequests(String groupId) {
    return _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.joinRequestsSubcollection)
        .where('status', isEqualTo: AppConstants.requestPending)
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  /// Check if user already has a pending request for this group.
  Future<QuerySnapshot> getUserPendingRequests(
      String groupId, String userId) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.joinRequestsSubcollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.requestPending)
        .get();
  }

  // ─── Settlement Operations ────────────────────────────────────

  /// Save or update a settlement document.
  Future<void> setSettlement(
      String groupId, String month, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.settlementsSubcollection)
        .doc(month)
        .set(data);
  }

  /// Get a settlement by month key.
  Future<DocumentSnapshot> getSettlement(String groupId, String month) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.settlementsSubcollection)
        .doc(month)
        .get();
  }

  /// Stream a settlement document (real-time for payment updates).
  Stream<DocumentSnapshot> streamSettlement(String groupId, String month) {
    return _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.settlementsSubcollection)
        .doc(month)
        .snapshots();
  }

  // ─── Payment Operations ───────────────────────────────────────

  /// Create a payment record.
  Future<DocumentReference> createPayment(
      String groupId, Map<String, dynamic> data) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.paymentsSubcollection)
        .add(data);
  }

  /// Update a payment (e.g., confirm receipt).
  Future<void> updatePayment(
      String groupId, String paymentId, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.paymentsSubcollection)
        .doc(paymentId)
        .update(data);
  }

  /// Get a specific payment record.
  Future<DocumentSnapshot> getPayment(String groupId, String paymentId) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.paymentsSubcollection)
        .doc(paymentId)
        .get();
  }

  /// Stream payments for a group.
  Stream<QuerySnapshot> streamPayments(String groupId) {
    return _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.paymentsSubcollection)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  /// Get payments for a specific settlement month.
  Future<QuerySnapshot> getMonthPayments(
      String groupId, String month) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.paymentsSubcollection)
        .where('settlementMonth', isEqualTo: month)
        .get();
  }

  // ─── Activity Log Operations ──────────────────────────────────

  /// Add an activity log entry.
  Future<DocumentReference> addActivityLog(
      String groupId, Map<String, dynamic> data) async {
    return await _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.activityLogsSubcollection)
        .add(data);
  }

  /// Stream activity logs (paginated, most recent first).
  Stream<QuerySnapshot> streamActivityLogs(String groupId, {int limit = 20}) {
    return _db
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .collection(AppConstants.activityLogsSubcollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ─── Invite Operations ────────────────────────────────────────

  /// Create an invite document.
  Future<void> createInvite(String token, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.invitesCollection).doc(token).set(data);
  }

  /// Get an invite by token.
  Future<DocumentSnapshot> getInvite(String token) async {
    return await _db
        .collection(AppConstants.invitesCollection)
        .doc(token)
        .get();
  }

  /// Update an invite document.
  Future<void> updateInvite(
      String token, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.invitesCollection)
        .doc(token)
        .update(data);
  }

  // ─── Batch / Transaction Helpers ──────────────────────────────

  /// Run a Firestore transaction.
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction transaction) handler) {
    return _db.runTransaction(handler);
  }

  /// Get a batch writer.
  WriteBatch batch() => _db.batch();

  /// Increment a numeric field atomically.
  Future<void> incrementField(
    String collection,
    String docId,
    String field,
    int value,
  ) async {
    await _db.collection(collection).doc(docId).update({
      field: FieldValue.increment(value),
    });
  }
}
