import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:split_saathi/viewmodels/group_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../viewmodels/settlement_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/shimmer/settlement_shimmer.dart';

/// Settlement tab — calculate, view, and manage monthly settlements.
class SettlementTab extends StatefulWidget {
  final String groupId;
  const SettlementTab({super.key, required this.groupId});
  @override
  State<SettlementTab> createState() => _SettlementTabState();
}

class _SettlementTabState extends State<SettlementTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = context.read<SettlementViewModel>();
        vm.loadSettlement(widget.groupId, vm.selectedMonth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettlementViewModel>();
    final groupVm = context.watch<GroupViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final memberVm = context.watch<MemberViewModel>();
    final expenseVm = context.watch<ExpenseViewModel>();

    // Sync local VM month with global Group month
    if (vm.selectedMonth != groupVm.selectedMonth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.loadSettlement(widget.groupId, groupVm.selectedMonth);
      });
    }

    if (vm.isLoading) return const SettlementShimmer();

    final isCurrentMonth =
        groupVm.selectedMonth == DateHelper.currentSettlementKey;

    // For the current month, we prioritize the real-time total from ExpenseViewModel
    // For past months, we use the settled amount from the official document
    final displayTotal = isCurrentMonth
        ? expenseVm.currentMonthTotal
        : (vm.settlement?.totalAmount ?? 0.0);

    // Calculate per-person based on the displayTotal to keep it consistent
    final memberCount = vm.settlement?.memberCount ?? memberVm.members.length;
    final displayFairShare = memberCount > 0 ? displayTotal / memberCount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // ── Elegant Compact Summary ────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'GROUP SUMMARY',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${AppStrings.currency}${displayTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.06), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryStat(
                        'Per Person', 
                        '${AppStrings.currency}${displayFairShare.toStringAsFixed(0)}',
                        Icons.person_outline_rounded
                      ),
                      Container(width: 1, height: 24, color: AppColors.primary.withValues(alpha: 0.1)),
                      _buildSummaryStat(
                        'Members', 
                        '$memberCount',
                        Icons.group_outlined
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),

          const SizedBox(height: 24),

          // ── Action or Breakdown ──────────────────────────
          if (vm.settlement == null) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'Calculate Monthly Settlement',
              icon: Icons.auto_awesome_rounded,
              onPressed: () async {
                if (authVm.currentUser == null) return;
                final user = authVm.currentUser!;
                final monthParts = vm.selectedMonth.split('-');
                final monthDate = DateTime(
                  int.parse(monthParts[0]),
                  int.parse(monthParts[1]),
                );
                final success = await vm.calculateSettlement(
                  groupId: widget.groupId,
                  monthDate: monthDate,
                  members: memberVm.members,
                  userId: user.uid,
                  userName: user.name,
                  userColor: user.color,
                );
                if (success && context.mounted) {
                  SnackbarHelper.showSuccess(context, 'Settlement calculated!');
                }
              },
            ).animate().fadeIn(delay: 200.ms).scale(curve: Curves.easeOutBack),
          ] else ...[
            // ── Member Breakdown ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Individual Breakdown',
                style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.textPrimary.withValues(alpha: 0.7)),
              ),
            ),
            ...vm.settlement!.balances.entries.map((entry) {
              final memberId = entry.key;
              final balance = entry.value;
              final member = memberVm.getMemberById(memberId);
              final name = member?.name ?? memberId;
              final color = AppColors.fromHex(member?.color ?? '#D6E6FF');
              final totalSpent = vm.settlement!.memberTotals[memberId] ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Left Accent Bar
                      Positioned(
                        left: 0, top: 0, bottom: 0,
                        child: Container(
                          width: 5,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
                        child: Row(
                          children: [
                            UserAvatar(name: name, colorHex: member?.color ?? '#D6E6FF', photoUrl: member?.photoUrl, size: 44),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  Text('Spent: ${AppStrings.currency}${totalSpent.toStringAsFixed(0)}', 
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  balance >= 0
                                      ? '+${AppStrings.currency}${balance.toStringAsFixed(0)}'
                                      : '-${AppStrings.currency}${balance.abs().toStringAsFixed(0)}',
                                  style: AppTextStyles.label.copyWith(
                                    color: balance >= 0 ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  balance >= 0 ? 'gets back' : 'owes',
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).scale(curve: Curves.easeOutBack);
            }),

            const SizedBox(height: 24),

            // ── Transactions ──────────────────────────────
            if (vm.settlement!.transactions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Suggested Payments',
                  style: AppTextStyles.heading3.copyWith(fontSize: 16, color: AppColors.textPrimary.withValues(alpha: 0.7)),
                ),
              ),
              ...vm.settlement!.transactions.asMap().entries.map((entry) {
                final i = entry.key;
                final txn = entry.value;
                final fromMember = memberVm.getMemberById(txn.fromUserId);
                final toMember = memberVm.getMemberById(txn.toUserId);
                final fromColor = AppColors.fromHex(fromMember?.color ?? '#FF6B6B');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      BoxShadow(color: fromColor.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 5, color: fromColor)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
                          child: Row(
                            children: [
                              UserAvatar(name: fromMember?.name ?? 'User', colorHex: fromMember?.color ?? '#FF6B6B', size: 36),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textHint),
                              ),
                              UserAvatar(name: toMember?.name ?? 'User', colorHex: toMember?.color ?? '#4ECDC4', size: 36),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '${fromMember?.name ?? 'U'} to ${toMember?.name ?? 'U'}',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                                ),
                                child: Text(
                                  '${AppStrings.currency}${txn.amount.toStringAsFixed(0)}',
                                  style: AppTextStyles.amount.copyWith(fontSize: 15, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (150 + 50 * i).ms).scale(curve: Curves.easeOutBack);
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 18)),
      ],
    );
  }
}
