import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_constants.dart';
import '../models/invite_model.dart';
import 'firestore_service.dart';

/// Service for generating, validating, and managing invite links.
class InviteService {
  final FirestoreService _firestoreService;
  final Uuid _uuid = const Uuid();

  InviteService(this._firestoreService);

  /// Generate a new invite link for a group.
  /// Returns the created InviteModel.
  Future<InviteModel> generateInvite({
    required String groupId,
    required String groupName,
    required String createdBy,
  }) async {
    final token = _uuid.v4();
    final now = DateTime.now();

    final invite = InviteModel(
      token: token,
      groupId: groupId,
      groupName: groupName,
      createdBy: createdBy,
      createdAt: now,
      expiresAt: now.add(
        const Duration(minutes: AppConstants.inviteExpiryMinutes),
      ),
      maxUses: AppConstants.inviteMaxUses,
      usedCount: 0,
      status: AppConstants.inviteActive,
    );

    await _firestoreService.createInvite(token, invite.toJson());
    return invite;
  }

  /// Build a shareable invite URL from a token.
  String buildInviteUrl(String token) {
    return 'https://${AppConstants.deepLinkHost}${AppConstants.deepLinkJoinPath}?token=$token';
  }

  /// Share the invite link via the system share sheet.
  Future<void> shareInviteLink(String token, String groupName) async {
    final url = buildInviteUrl(token);
    await Share.share('Join "$groupName" on SplitSaathi!\n$url');
  }

  /// Validate an invite token. Returns the InviteModel if valid.
  /// Throws an error string describing the issue if invalid.
  Future<InviteModel> validateInvite(String token) async {
    final doc = await _firestoreService.getInvite(token);

    if (!doc.exists) {
      throw 'This invite link is invalid';
    }

    final invite = InviteModel.fromJson(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );

    if (invite.isExpired) {
      // Also update status in Firestore
      await _firestoreService.updateInvite(token, {'status': AppConstants.inviteExpired});
      throw 'This invite link has expired';
    }

    if (invite.isExhausted) {
      throw 'This invite link has been used the maximum number of times';
    }

    if (invite.status != AppConstants.inviteActive) {
      throw 'This invite link is no longer active';
    }

    return invite;
  }

  /// Increment the used count of an invite. Mark as exhausted if max reached.
  Future<void> incrementUsedCount(String token) async {
    final doc = await _firestoreService.getInvite(token);
    if (!doc.exists) return;

    final invite = InviteModel.fromJson(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );

    final newCount = invite.usedCount + 1;
    final updates = <String, dynamic>{
      'usedCount': newCount,
    };

    if (newCount >= invite.maxUses) {
      updates['status'] = AppConstants.inviteExhausted;
    }

    await _firestoreService.updateInvite(token, updates);
  }
}
