import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:split_saathi/core/utils/snackbar_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import 'package:split_saathi/viewmodels/group_viewmodel.dart';
import 'package:split_saathi/viewmodels/auth_viewmodel.dart';
import 'package:split_saathi/viewmodels/expense_viewmodel.dart';
import 'package:split_saathi/viewmodels/member_viewmodel.dart';
import '../../widgets/role_badge.dart';
import '../expenses/expense_list_tab.dart';
import '../members/members_tab.dart';
import '../settlement/settlement_tab.dart';
import '../activity/activity_log_tab.dart';
import 'dashboard_tab.dart';

/// Group detail screen with 5 tabs at the top: Stats, Expenses, Members, Settlement, Activity.
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.index = 0; // Default to Expenses

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authVm = context.read<AuthViewModel>();
        context.read<ExpenseViewModel>().loadExpenses(widget.groupId);
        context.read<MemberViewModel>().loadMembers(widget.groupId);
        if (authVm.currentUser != null) {
          context.read<GroupViewModel>().fetchGroup(widget.groupId, authVm.currentUser!.uid);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupVm = context.watch<GroupViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final group = groupVm.selectedGroup;
    final accentColor = AppColors.fromHex(authVm.currentUser?.color ?? '#6C63FF');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group?.iconEmoji ?? '👥',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group?.name ?? 'Group',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (groupVm.currentMember != null && groupVm.currentMember!.isAdmin)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.person_add_outlined, color: accentColor, size: 20),
              ),
              onPressed: () => context.push('/groups/${widget.groupId}/invite'),
            ),
          if (groupVm.currentMember != null && groupVm.currentMember!.isAdmin)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.textPrimary.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 20),
              ),
              onPressed: () => context.push('/groups/${widget.groupId}/members'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primaryDark.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w900, 
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700, 
                fontSize: 10,
              ),
              tabs: [
                _buildTab(Icons.receipt_long_rounded, 'EXPENSES', const Color(0xFFFF8C69)),
                _buildTab(Icons.people_alt_rounded, 'MEMBERS', const Color(0xFF64B5F6)),
                _buildTab(Icons.account_balance_wallet_rounded, 'SETTLE', const Color(0xFF81C784)),
                _buildTab(Icons.history_rounded, 'ACTIVITY', const Color(0xFFBA68C8)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Month Selector & Role Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMonthNavButton(Icons.chevron_left_rounded, () => groupVm.changeMonth(-1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            DateHelper.settlementLabel(groupVm.selectedMonth).toUpperCase(),
                            key: ValueKey(groupVm.selectedMonth),
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      _buildMonthNavButton(Icons.chevron_right_rounded, () {
                        final now = DateTime.now();
                        final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
                        if (groupVm.selectedMonth == currentMonthStr) {
                          SnackbarHelper.showInfo(context, 'Future months will be available once they start! 🗓️');
                        } else {
                          groupVm.changeMonth(1);
                        }
                      }),
                    ],
                  ),
                ),
                if (groupVm.currentMember != null)
                  RoleBadge(role: groupVm.currentMember!.role)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .shimmer(delay: 1.seconds, duration: 2.seconds),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ExpenseListTab(groupId: widget.groupId),
                MembersTab(groupId: widget.groupId),
                SettlementTab(groupId: widget.groupId),
                ActivityLogTab(groupId: widget.groupId),
              ],
            ),
          ),
        ],
      ),


      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: ValueNotifier(_tabController.index),
        builder: (context, index, _) {
          return groupVm.currentMember != null && groupVm.currentMember!.isEditor
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/groups/${widget.groupId}/expense/add'),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text('ADD EXPENSE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack)
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, Color iconColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildMonthNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: AppColors.textPrimary.withValues(alpha: 0.7)),
      ),
    );
  }
}
