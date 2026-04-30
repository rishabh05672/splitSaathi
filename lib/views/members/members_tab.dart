import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/role_badge.dart';

/// Members tab showing all active members of the group.
class MembersTab extends StatelessWidget {
  final String groupId;
  const MembersTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemberViewModel>();
    if (vm.isLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, _) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: vm.members.length,
      itemBuilder: (_, index) {
        final m = vm.members[index];
        final memberColor = AppColors.fromHex(m.color);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: memberColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Left Accent Bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: memberColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: m.name,
                        colorHex: m.color,
                        photoUrl: m.photoUrl,
                        size: 48,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          m.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      RoleBadge(role: m.role),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(delay: Duration(milliseconds: 60 * index))
          .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 60 * index), duration: 400.ms, curve: Curves.easeOutCubic);
      },
    );
  }
}
