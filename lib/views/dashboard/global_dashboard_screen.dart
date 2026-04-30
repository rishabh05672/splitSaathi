import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import '../../viewmodels/global_dashboard_viewmodel.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Premium Global Dashboard Screen.
/// Aggregates insights from all groups the user is part of.
class GlobalDashboardScreen extends StatefulWidget {
  const GlobalDashboardScreen({super.key});

  @override
  State<GlobalDashboardScreen> createState() => _GlobalDashboardScreenState();
}

class _GlobalDashboardScreenState extends State<GlobalDashboardScreen> with AutomaticKeepAliveClientMixin {
  bool _isInit = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final authVm = context.read<AuthViewModel>();
      if (authVm.currentUser != null) {
        // Use addPostFrameCallback to avoid calling notifyListeners() during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<GlobalDashboardViewModel>().loadGlobalData(authVm.currentUser!.uid);
          }
        });
      }
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final dashboardVm = context.watch<GlobalDashboardViewModel>();
    final authVm = context.watch<AuthViewModel>();

    if (dashboardVm.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (dashboardVm.memberTotals.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(authVm.currentUser?.uid),
        body: _buildEmptyState(),
      );
    }

    final memberSpendingData = dashboardVm.memberTotals.entries.map((e) {
      return _MemberSpending(
        dashboardVm.memberNames[e.key] ?? 'Unknown',
        e.value,
        AppColors.fromHex(dashboardVm.memberColors[e.key] ?? '#6C63FF'),
      );
    }).toList();

    final groupSpendingData = dashboardVm.groupTotals.entries.map((e) {
      // Find a stable color for the group
      final groupName = dashboardVm.groupNames[e.key] ?? 'Unknown';
      return _GroupSpending(
        groupName,
        e.value,
        _getGroupColor(groupName),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(authVm.currentUser?.uid),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Global Month Selector ---
            _buildMonthSelector(dashboardVm, authVm.currentUser?.uid),
            const SizedBox(height: 32),

            // --- Group Distribution Section ---
            _buildSectionHeader('Group Insights', 'Spending breakdown across groups'),
            const SizedBox(height: 16),
            _buildGroupDonutChart(groupSpendingData, dashboardVm.totalSpending)
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 40),

            // --- Distribution Section ---
            _buildSectionHeader('Member Distribution', 'Total spending across all groups'),
            const SizedBox(height: 16),
            _buildMemberDonutChart(memberSpendingData, dashboardVm.totalSpending)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 40),

            // --- Member Breakdown Section ---
            _buildSectionHeader('Member Expenses', 'Individual contribution levels'),
            const SizedBox(height: 16),
            ...memberSpendingData.map((data) {
              return _buildMemberStatCard(data.name, data.amount, dashboardVm.totalSpending, data.color)
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideX(begin: 0.1, end: 0);
            }),
          ],
        ),
      ),
    );
  }

  Color _getGroupColor(String name) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF98BFFF),
      const Color(0xFFA9FF95),
      const Color(0xFFFFADFF),
      const Color(0xFF88F5FF),
    ];
    return colors[name.length % colors.length];
  }

  Widget _buildGroupDonutChart(List<_GroupSpending> data, double total) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        ),
        series: <CircularSeries>[
          PieSeries<_GroupSpending, String>(
            dataSource: data,
            xValueMapper: (_GroupSpending d, _) => d.name,
            yValueMapper: (_GroupSpending d, _) => d.amount,
            pointColorMapper: (_GroupSpending d, _) => d.color,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.inside,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white),
            ),
            enableTooltip: true,
            animationDuration: 1500,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String? userId) {
    return AppBar(
      title: const Text('GLOBAL INSIGHTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            if (userId != null) {
              context.read<GlobalDashboardViewModel>().loadGlobalData(userId);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonthSelector(GlobalDashboardViewModel vm, String? userId) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMonthNavButton(Icons.chevron_left_rounded, () {
            if (userId != null) vm.changeMonth(-1, userId);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                DateHelper.settlementLabel(vm.selectedMonth).toUpperCase(),
                key: ValueKey(vm.selectedMonth),
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          _buildMonthNavButton(Icons.chevron_right_rounded, () {
            final now = DateTime.now();
            final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
            if (vm.selectedMonth == currentMonthStr) {
              SnackbarHelper.showInfo(context, 'Future months will be available once they start! 🗓️');
            } else {
              if (userId != null) vm.changeMonth(1, userId);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildMonthNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.textPrimary.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3.copyWith(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
      ],
    );
  }


  Widget _buildMemberDonutChart(List<_MemberSpending> data, double total) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: SfCircularChart(
        annotations: <CircularChartAnnotation>[
          CircularChartAnnotation(
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TOTAL', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
                Text(
                  '${AppStrings.currency}${total.toStringAsFixed(0)}',
                  style: AppTextStyles.heading3.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          )
        ],
        series: <CircularSeries>[
          DoughnutSeries<_MemberSpending, String>(
            dataSource: data,
            xValueMapper: (_MemberSpending d, _) => d.name,
            yValueMapper: (_MemberSpending d, _) => d.amount,
            pointColorMapper: (_MemberSpending d, _) => d.color,
            innerRadius: '75%',
            radius: '90%',
            enableTooltip: true,
            animationDuration: 1500,
            cornerStyle: CornerStyle.bothCurve,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStatCard(String name, double amount, double total, Color color) {
    final percentage = (amount / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- Avatar Group ---
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.characters.first.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // --- Info Group ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${AppStrings.currency}${amount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 5,
                      width: (percentage / 100) * 160, // Compact width
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // --- Percentage ---
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w900,
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 80, color: AppColors.textHint.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Global Analytics', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Add expenses to your groups to see insights here.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _MemberSpending {
  final String name;
  final double amount;
  final Color color;
  _MemberSpending(this.name, this.amount, this.color);
}

class _GroupSpending {
  final String name;
  final double amount;
  final Color color;
  _GroupSpending(this.name, this.amount, this.color);
}
