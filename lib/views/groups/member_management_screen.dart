import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/member_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../viewmodels/invite_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/role_badge.dart';
import '../../widgets/shimmer/member_shimmer.dart';

/// Full member management screen with role changes and removal.
class MemberManagementScreen extends StatefulWidget {
  final String groupId;
  const MemberManagementScreen({super.key, required this.groupId});
  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MemberViewModel>().loadMembers(widget.groupId);
      context.read<InviteViewModel>().loadJoinRequests(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final memberVm = context.watch<MemberViewModel>();
    final inviteVm = context.watch<InviteViewModel>();
    final groupVm = context.watch<GroupViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currentMember = groupVm.currentMember;
    final isSuperAdmin = currentMember?.role == AppConstants.roleSuperAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Members'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
        body: memberVm.isLoading
            ? const MemberShimmer()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Active Members ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'ACTIVE MEMBERS',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.4),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final member = memberVm.members[index];
                      final isCurrentUser = member.userId == authVm.currentUser?.uid;
                      final memberColor = AppColors.fromHex(member.color);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            BoxShadow(color: memberColor.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            children: [
                              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: memberColor)),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                                child: Row(
                                  children: [
                                    UserAvatar(
                                      name: member.name,
                                      colorHex: member.color,
                                      photoUrl: member.photoUrl,
                                      size: 40,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  member.name,
                                                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 15),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.06),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text('YOU', style: AppTextStyles.label.copyWith(
                                                    color: AppColors.primary, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          RoleBadge(role: member.role),
                                        ],
                                      ),
                                    ),
                                    if (isSuperAdmin && !isCurrentUser)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        onSelected: (value) => _handleAction(value, member),
                                        itemBuilder: (_) => [
                                          _buildMenuItem('make_admin', 'Make Admin', Icons.admin_panel_settings_outlined),
                                          _buildMenuItem('make_editor', 'Make Editor', Icons.edit_outlined),
                                          _buildMenuItem('make_viewer', 'Make Viewer', Icons.visibility_outlined),
                                          const PopupMenuDivider(),
                                          _buildMenuItem('remove', 'Remove Member', Icons.person_remove_outlined, isDestructive: true),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (50 * index).ms).scale(curve: Curves.easeOutBack);
                    },
                    childCount: memberVm.members.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String title, IconData icon, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? AppColors.error : AppColors.textPrimary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(title, style: AppTextStyles.bodyMedium.copyWith(
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
            fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w500,
          )),
        ],
      ),
    );
  }

  void _handleAction(String action, MemberModel member) async {
    final authVm = context.read<AuthViewModel>();
    final groupVm = context.read<GroupViewModel>();
    if (authVm.currentUser == null) return;

    switch (action) {
      case 'make_admin':
        await groupVm.changeMemberRole(
          groupId: widget.groupId, memberId: member.userId,
          memberName: member.name, newRole: AppConstants.roleAdmin, changedBy: authVm.currentUser!);
        if (mounted) SnackbarHelper.showSuccess(context, '${member.name} is now an Admin');
      case 'make_editor':
        await groupVm.changeMemberRole(
          groupId: widget.groupId, memberId: member.userId,
          memberName: member.name, newRole: AppConstants.roleEditor, changedBy: authVm.currentUser!);
        if (mounted) SnackbarHelper.showSuccess(context, '${member.name} is now an Editor');
      case 'make_viewer':
        await groupVm.changeMemberRole(
          groupId: widget.groupId, memberId: member.userId,
          memberName: member.name, newRole: AppConstants.roleViewer, changedBy: authVm.currentUser!);
        if (mounted) SnackbarHelper.showSuccess(context, '${member.name} is now a Viewer');
      case 'remove':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text('Remove ${member.name} from this group?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppStrings.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.remove, style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await groupVm.removeMember(
            groupId: widget.groupId, memberId: member.userId,
            memberName: member.name, removedBy: authVm.currentUser!);
          if (mounted) SnackbarHelper.showInfo(context, '${member.name} has been removed');
        }
    }
  }
}
