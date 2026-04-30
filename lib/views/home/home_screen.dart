import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../core/utils/date_helper.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/snackbar_helper.dart';

/// Home screen showing the user's groups with FAB to create new group.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authVm = context.read<AuthViewModel>();
        if (authVm.currentUser != null) {
          context.read<GroupViewModel>().loadUserGroups(authVm.currentUser!.uid);
        }
      }
    });
  }
  
  void _showDeleteConfirmation(BuildContext context, GroupModel group, GroupViewModel groupVm, UserModel? user) {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Remove Group?', style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w900)),
        content: Text(
          'Are you sure you want to remove "${group.name}" from your list? You can always join back later.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: AppColors.textHint, letterSpacing: 1)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await groupVm.leaveGroup(group.groupId, user);
              if (success) {
                if (context.mounted) SnackbarHelper.showSuccess(context, 'Group removed successfully');
              } else {
                if (context.mounted) SnackbarHelper.showError(context, 'Failed to remove group');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              foregroundColor: AppColors.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final groupVm = context.watch<GroupViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          AppStrings.appName,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w900,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
      body: groupVm.isLoading
          ? _buildShimmer()
          : groupVm.groups.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.group_add_rounded,
                  title: AppStrings.noGroups,
                  subtitle: AppStrings.noGroupsSubtitle,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    if (authVm.currentUser != null) groupVm.loadUserGroups(authVm.currentUser!.uid);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: groupVm.groups.length,
                    itemBuilder: (context, index) {
                      final group = groupVm.groups[index];
                      final accentColor = AppColors.userColors[index % AppColors.userColors.length];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              if (authVm.currentUser != null) {
                                groupVm.selectGroup(group, authVm.currentUser!.uid);
                              }
                              context.push('/groups/${group.groupId}');
                            },
                            onLongPress: () => _showDeleteConfirmation(context, group, groupVm, authVm.currentUser),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Center(
                                      child: Text(
                                        group.iconEmoji ?? '💰',
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: AppTextStyles.heading3.copyWith(
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.people_alt_rounded, size: 12, color: accentColor),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${group.memberCount} members',
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DateHelper.relativeTime(group.createdAt),
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.textHint.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate()
                        .fadeIn(delay: Duration(milliseconds: 80 * index))
                        .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 80 * index), duration: 400.ms, curve: Curves.easeOutCubic);
                    },
                  ),
                ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase, highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: 5,
        itemBuilder: (_, _) => const Card(child: SizedBox(height: 80)),
      ),
    );
  }
}
