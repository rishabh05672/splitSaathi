/// All user-facing string constants used throughout SplitSaathi.
/// No hardcoded strings in UI files — always reference this class.
class AppStrings {
  AppStrings._();

  // ─── App Info ───────────────────────────────────────────────
  static const String appName = 'SplitSaathi';
  static const String appTagline = 'Split expenses, not friendships';
  static const String currency = '₹';

  // ─── Auth ───────────────────────────────────────────────────
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Full Name';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String logout = 'Logout';
  static const String logoutConfirm = 'Are you sure you want to logout?';
  static const String forgotPassword = 'Forgot Password?';

  // ─── Home ───────────────────────────────────────────────────
  static const String myGroups = 'My Groups';
  static const String noGroups = 'No groups yet';
  static const String noGroupsSubtitle = 'Create a group or join one to get started!';
  static const String createGroup = 'Create Group';

  // ─── Groups ─────────────────────────────────────────────────
  static const String groupName = 'Group Name';
  static const String pickEmoji = 'Pick an emoji icon';
  static const String create = 'Create';
  static const String members = 'Members';
  static const String expenses = 'Expenses';
  static const String settlement = 'Settlement';
  static const String activity = 'Activity';
  static const String inviteMembers = 'Invite Members';
  static const String deleteGroup = 'Delete Group';
  static const String deleteGroupConfirm = 'Are you sure you want to delete this group? This cannot be undone.';
  static const String leaveGroup = 'Leave Group';
  static const String leaveGroupConfirm = 'Are you sure you want to leave this group?';

  // ─── Expenses ───────────────────────────────────────────────
  static const String addExpense = 'Add Expense';
  static const String editExpense = 'Edit Expense';
  static const String deleteExpense = 'Delete Expense';
  static const String itemName = 'Item Name';
  static const String amount = 'Amount';
  static const String noExpenses = 'No expenses yet';
  static const String noExpensesSubtitle = 'Add an expense to get started!';
  static const String expenseAdded = 'Expense added successfully!';
  static const String expenseUpdated = 'Expense updated successfully!';
  static const String expenseDeleted = 'Expense deleted successfully!';
  static const String deleteExpenseConfirm = 'Are you sure you want to delete this expense?';

  // ─── Invite ─────────────────────────────────────────────────
  static const String generateLink = 'Generate Invite Link';
  static const String shareLink = 'Share Invite Link';
  static const String linkExpired = 'This invite link has expired';
  static const String linkExhausted = 'This invite link has been used the maximum number of times';
  static const String linkInvalid = 'This invite link is invalid';
  static const String alreadyMember = 'You are already a member of this group';
  static const String requestPending = 'You already have a pending request for this group';
  static const String inviteLinkCopied = 'Invite link copied to clipboard!';

  // ─── Join Request ───────────────────────────────────────────
  static const String sendJoinRequest = 'Send Join Request';
  static const String requestSent = 'Request sent!';
  static const String waitingForApproval = 'Waiting for admin approval...';
  static const String joinRequests = 'Join Requests';
  static const String noJoinRequests = 'No pending join requests';
  static const String approve = 'Approve';
  static const String decline = 'Decline';
  static const String requestApproved = 'Request approved!';
  static const String requestDeclined = 'Request declined';

  // ─── Roles ──────────────────────────────────────────────────
  static const String superAdmin = 'Super Admin';
  static const String admin = 'Admin';
  static const String editor = 'Editor';
  static const String viewer = 'Viewer';
  static const String changeRole = 'Change Role';
  static const String removeMember = 'Remove Member';
  static const String removeMemberConfirm = 'Are you sure you want to remove this member?';

  // ─── Settlement ─────────────────────────────────────────────
  static const String totalSpent = 'Total Spent';
  static const String fairShare = 'Fair Share';
  static const String calculateSettlement = 'Calculate Settlement';
  static const String noSettlement = 'No settlement data for this month';
  static const String markAsPaid = 'Mark as Paid';
  static const String confirmReceipt = 'Confirm Receipt';
  static const String paymentHistory = 'Payment History';
  static const String noPayments = 'No payments recorded yet';
  static const String settled = 'Settled';

  // ─── Activity Log ───────────────────────────────────────────
  static const String noActivity = 'No activity yet';
  static const String noActivitySubtitle = 'Actions in this group will show up here';

  // ─── Profile ────────────────────────────────────────────────
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String memberSince = 'Member since';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountConfirm =
      'This will permanently delete your account and remove you from all groups. This cannot be undone.';
  static const String changeName = 'Change Name';
  static const String changePhoto = 'Change Photo';

  // ─── General ────────────────────────────────────────────────
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String remove = 'Remove';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String somethingWentWrong = 'Something went wrong. Please try again.';
  static const String noInternet = 'No internet connection. Please check your network.';
  static const String permissionDenied = "You don't have permission to perform this action.";
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
}
