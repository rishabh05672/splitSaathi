import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_helper.dart';
import '../../models/activity_log_model.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity log tab — real-time stream of group actions.
class ActivityLogTab extends StatelessWidget {
  final String groupId;
  const ActivityLogTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupVm = context.watch<GroupViewModel>();
    final memberVm = context.watch<MemberViewModel>();
    
    // Calculate month boundaries
    final monthParts = groupVm.selectedMonth.split('-');
    final monthStart = DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]), 1);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

    // Stream directly from Firestore for activity logs
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.groupsCollection)
          .doc(groupId)
          .collection(AppConstants.activityLogsSubcollection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('timestamp', isLessThan: Timestamp.fromDate(monthEnd))
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          );
        }

        final logs =
            snapshot.data?.docs.map((doc) {
              return ActivityLogModel.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              );
            }).toList() ??
            [];

        if (logs.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history,
            title: AppStrings.noActivity,
            subtitle: AppStrings.noActivitySubtitle,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: logs.length,
          itemBuilder: (_, i) {
            final log = logs[i];
            final actorColor = AppColors.fromHex(log.userColor);
            final showDate =
                i == 0 ||
                DateHelper.groupLabel(log.timestamp) !=
                    DateHelper.groupLabel(logs[i - 1].timestamp);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      DateHelper.groupLabel(log.timestamp),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: actorColor.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
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
                              color: actorColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                bottomLeft: Radius.circular(22),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final member = memberVm.members.where((m) => m.userId == log.userId).firstOrNull;
                                  return UserAvatar(
                                    name: log.userName,
                                    colorHex: log.userColor,
                                    photoUrl: member?.photoUrl,
                                    size: 40,
                                  );
                                }
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.description,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateHelper.relativeTime(log.timestamp),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate()
                  .fadeIn(delay: Duration(milliseconds: 40 * i))
                  .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), delay: Duration(milliseconds: 40 * i), duration: 400.ms, curve: Curves.easeOutBack),
              ],
            );
          },
        );
      },
    );
  }
}
