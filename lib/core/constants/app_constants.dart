/// Numeric and configuration constants used throughout SplitSaathi.
/// No magic numbers in code — always reference this class.
class AppConstants {
  AppConstants._();

  // ─── Invite Settings ────────────────────────────────────────
  /// Invite link validity duration in minutes
  static const int inviteExpiryMinutes = 30;

  /// Maximum number of times an invite link can be used
  static const int inviteMaxUses = 2;

  // ─── Animation Durations (ms) ───────────────────────────────
  static const int splashDuration = 2500;
  static const int fadeInDuration = 500;
  static const int slideInDuration = 400;
  static const int staggerDelay = 100;
  static const int shimmerDuration = 1500;
  static const int countUpDuration = 800;

  // ─── Pagination ─────────────────────────────────────────────
  static const int activityLogPageSize = 20;
  static const int expensePageSize = 30;

  // ─── Avatar Sizes ───────────────────────────────────────────
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 44.0;
  static const double avatarLarge = 64.0;

  // ─── Card Styling ───────────────────────────────────────────
  static const double cardBorderRadius = 16.0;
  static const double cardElevation = 2.0;
  static const double buttonBorderRadius = 12.0;
  static const double inputBorderRadius = 12.0;

  // ─── Deep Link ──────────────────────────────────────────────
  static const String deepLinkScheme = 'splitsaathi';
  static const String deepLinkHost = 'splitsaathi.app';
  static const String deepLinkJoinPath = '/join';

  // ─── SharedPreferences Keys ─────────────────────────────────
  static const String prefPendingInviteToken = 'pending_invite_token';
  static const String prefFcmToken = 'fcm_token';

  // ─── Firestore Collection Names ─────────────────────────────
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String membersSubcollection = 'members';
  static const String expensesSubcollection = 'expenses';
  static const String joinRequestsSubcollection = 'joinRequests';
  static const String settlementsSubcollection = 'settlements';
  static const String paymentsSubcollection = 'payments';
  static const String activityLogsSubcollection = 'activityLogs';
  static const String invitesCollection = 'invites';

  // ─── Member Roles ───────────────────────────────────────────
  static const String roleSuperAdmin = 'superAdmin';
  static const String roleAdmin = 'admin';
  static const String roleEditor = 'editor';
  static const String roleViewer = 'viewer';

  // ─── Member Status ──────────────────────────────────────────
  static const String statusActive = 'active';
  static const String statusRemoved = 'removed';

  // ─── Invite Status ──────────────────────────────────────────
  static const String inviteActive = 'active';
  static const String inviteExpired = 'expired';
  static const String inviteExhausted = 'exhausted';

  // ─── Join Request Status ────────────────────────────────────
  static const String requestPending = 'pending';
  static const String requestApproved = 'approved';
  static const String requestDeclined = 'declined';

  // ─── Activity Log Actions ───────────────────────────────────
  static const String actionAddExpense = 'ADD_EXPENSE';
  static const String actionEditExpense = 'EDIT_EXPENSE';
  static const String actionDeleteExpense = 'DELETE_EXPENSE';
  static const String actionJoinGroup = 'JOIN_GROUP';
  static const String actionLeaveGroup = 'LEAVE_GROUP';
  static const String actionRoleChanged = 'ROLE_CHANGED';
  static const String actionMemberApproved = 'MEMBER_APPROVED';
  static const String actionMemberDeclined = 'MEMBER_DECLINED';
  static const String actionSettlementCalculated = 'SETTLEMENT_CALCULATED';
  static const String actionPaymentMade = 'PAYMENT_MADE';
  static const String actionMemberRemoved = 'MEMBER_REMOVED';
  static const String actionGroupCreated = 'GROUP_CREATED';

  // ─── Emoji List for Group Icons ─────────────────────────────
  static const List<String> groupEmojis = [
    '🏠', '🍕', '✈️', '🎮', '🎬', '🍔', '☕', '🎂',
    '🛒', '💼', '🎓', '🏋️', '🎵', '🚗', '🏖️', '🎁',
    '🍻', '🌮', '🎯', '💡', '🔥', '⚽', '🎪', '🏕️',
    '🚀', '💰', '🎸', '🍿', '🌸', '🎲', '🧳', '🍜',
  ];
}
