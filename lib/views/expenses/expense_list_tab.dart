import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Expense list tab showing real-time expenses grouped by date, with a member filter.
class ExpenseListTab extends StatefulWidget {
  final String groupId;
  const ExpenseListTab({super.key, required this.groupId});

  @override
  State<ExpenseListTab> createState() => _ExpenseListTabState();
}

class _ExpenseListTabState extends State<ExpenseListTab> {
  String? _selectedMemberId; // null means 'All'

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final groupVm = context.watch<GroupViewModel>();
    final memberVm = context.watch<MemberViewModel>();

    if (vm.isLoading || memberVm.isLoading) return _shimmer();
    
    // 1. Filter by Selected Month (Global)
    final monthParts = groupVm.selectedMonth.split('-');
    final monthStart = DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]), 1);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

    final monthExpenses = vm.activeExpenses.where((e) {
      return e.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
             e.timestamp.isBefore(monthEnd);
    }).toList();

    // 2. Filter by Member (Local)
    final expenses = _selectedMemberId == null 
        ? monthExpenses 
        : monthExpenses.where((e) => e.addedById == _selectedMemberId).toList();

    return Column(
      children: [
        if (memberVm.members.isNotEmpty && vm.activeExpenses.isNotEmpty)
          _buildFilterBar(memberVm),
        
        // Expense List
        Expanded(
          child: expenses.isEmpty
              ? const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: AppStrings.noExpenses, subtitle: 'No expenses found for this filter.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    final showDate = index == 0 || DateHelper.groupLabel(exp.timestamp) != DateHelper.groupLabel(expenses[index - 1].timestamp);
                    
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (showDate) Padding(padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(DateHelper.groupLabel(exp.timestamp), style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600))),
                      Stack(
                        children: [
                          Dismissible(
                            key: Key(exp.expenseId),
                            direction: (groupVm.currentMember?.isAdmin == true || (groupVm.currentMember?.isEditor == true && exp.addedById == authVm.currentUser?.uid))
                                ? DismissDirection.endToStart : DismissDirection.none,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 25),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog(context: context, builder: (_) => AlertDialog(
                                title: const Text(AppStrings.deleteExpense),
                                content: const Text(AppStrings.deleteExpenseConfirm),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppStrings.cancel)),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(AppStrings.delete, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ));
                            },
                            onDismissed: (_) {
                              if (authVm.currentUser != null) {
                                vm.deleteExpense(
                                  groupId: widget.groupId,
                                  expense: exp,
                                  deletedById: authVm.currentUser!.uid,
                                  deletedByName: authVm.currentUser!.name,
                                  deletedByColor: authVm.currentUser!.color,
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: AppColors.fromHex(exp.addedByColor).withValues(alpha: 0.1),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
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
                                          color: AppColors.fromHex(exp.addedByColor),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            bottomLeft: Radius.circular(24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onLongPress: () {
                                        if (groupVm.currentMember?.isAdmin == true || (groupVm.currentMember?.isEditor == true && exp.addedById == authVm.currentUser?.uid)) {
                                          context.push('/groups/${widget.groupId}/expense/add', extra: exp);
                                        }
                                      },
                                      onTap: () {
                                        SnackbarHelper.showInfo(context, 'Long press to edit this expense');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                                        child: Row(
                                          children: [
                                            // Avatar with colored ring
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.fromHex(exp.addedByColor).withValues(alpha: 0.3), width: 1.5),
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  final member = memberVm.members.where((m) => m.userId == exp.addedById).firstOrNull;
                                                  return UserAvatar(
                                                    name: exp.addedByName, 
                                                    colorHex: exp.addedByColor, 
                                                    photoUrl: member?.photoUrl,
                                                    size: 46,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    exp.itemName,
                                                    style: AppTextStyles.bodyLarge.copyWith(
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.textPrimary,
                                                      fontSize: 16,
                                                      letterSpacing: -0.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'by ${exp.addedByName} • ${DateHelper.relativeTime(exp.timestamp)}',
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Next-Level Amount Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.06),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
                                              ),
                                              child: Text(
                                                '${AppStrings.currency}${exp.amount.toStringAsFixed(0)}',
                                                style: AppTextStyles.amount.copyWith(
                                                  color: AppColors.primary,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate()
                            .fadeIn(delay: Duration(milliseconds: 60 * index))
                            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: Duration(milliseconds: 60 * index), duration: 400.ms, curve: Curves.easeOutBack),
                        ],
                      ),
                    ]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(MemberViewModel memberVm) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _buildAnimatedChip(
            label: 'All',
            isSelected: _selectedMemberId == null,
            onTap: () => setState(() => _selectedMemberId = null),
            icon: Icons.done_all_rounded,
          ),
          ...memberVm.members.map((m) => _buildAnimatedChip(
            label: m.name,
            isSelected: _selectedMemberId == m.userId,
            onTap: () => setState(() => _selectedMemberId = m.userId),
            avatarColor: Color(int.parse(m.color.replaceAll('#', '0xFF'))),
          )),
        ],
      ),
    );
  }

  Widget _buildAnimatedChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? avatarColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 14, color: isSelected ? AppColors.primary : AppColors.textSecondary)
            else if (avatarColor != null)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? avatarColor : avatarColor.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label[0].toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(baseColor: AppColors.shimmerBase, highlightColor: AppColors.shimmerHighlight,
    child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: 6,
      itemBuilder: (_, _) => Card(child: SizedBox(height: 72))));
}
