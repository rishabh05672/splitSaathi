import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../models/group_model.dart';

import '../../core/utils/date_helper.dart';

/// Premium Dashboard tab using Syncfusion charts.
class DashboardTab extends StatefulWidget {
  final String groupId;
  const DashboardTab({super.key, required this.groupId});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    final expenseVm = context.watch<ExpenseViewModel>();
    final memberVm = context.watch<MemberViewModel>();
    final groupVm = context.watch<GroupViewModel>();
    final group = groupVm.selectedGroup;

    // 1. Filter expenses for the selected month
    final monthParts = groupVm.selectedMonth.split('-');
    final monthStart = DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]), 1);
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

    final expenses = expenseVm.activeExpenses.where((e) {
      return e.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
             e.timestamp.isBefore(monthEnd);
    }).toList();

    if (expenses.isEmpty) {
      return _buildEmptyState();
    }

    // 2. Calculate data
    final memberTotals = <String, double>{};
    for (var exp in expenses) {
      memberTotals[exp.addedById] = (memberTotals[exp.addedById] ?? 0) + exp.amount;
    }
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Premium Header Card ---
            _buildTotalCard(totalSpent, group).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 32),

            // --- Distribution Section ---
            _buildSectionHeader('Expense Distribution', 'Who spent how much'),
            const SizedBox(height: 16),
            _buildDonutChart(memberTotals, memberVm, totalSpent).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 32),

            // --- Member Breakdown Section ---
            _buildSectionHeader('Member Contribution', 'Individual spending levels'),
            const SizedBox(height: 16),
            ...memberTotals.entries.map((entry) {
              final member = memberVm.members.where((m) => m.userId == entry.key).firstOrNull;
              return _buildMemberStatCard(member?.name ?? 'Unknown', entry.value, totalSpent, member?.color ?? '#6C63FF')
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideX(begin: 0.1, end: 0);
            }),
          ],
        ),
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

  Widget _buildTotalCard(double total, GroupModel? group) {
    final creationDate = group != null ? DateHelper.groupLabel(group.createdAt) : 'Unknown';

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4B45CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.analytics_rounded, size: 180, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL EXPENSE', style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('LIVE', style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${AppStrings.currency}${total.toStringAsFixed(0)}',
                  style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Created on $creationDate',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> totals, MemberViewModel memberVm, double totalSpent) {
    final List<_ChartData> chartData = totals.entries.map((e) {
      final member = memberVm.members.where((m) => m.userId == e.key).firstOrNull;
      return _ChartData(member?.name ?? 'Unknown', e.value, AppColors.fromHex(member?.color ?? '#6C63FF'));
    }).toList();

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
                  '${AppStrings.currency}${totalSpent.toStringAsFixed(0)}',
                  style: AppTextStyles.heading3.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          )
        ],
        series: <CircularSeries>[
          DoughnutSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            pointColorMapper: (_ChartData data, _) => data.color,
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

  Widget _buildMemberStatCard(String name, double amount, double total, String colorHex) {
    final color = AppColors.fromHex(colorHex);
    final percentage = (amount / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(name.characters.first.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w900)),
                    Text('${AppStrings.currency}${amount.toStringAsFixed(0)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w900, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: amount / total,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('${percentage.toStringAsFixed(0)}%', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
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
          Text('Analyze Your Expenses', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Add group expenses to unlock deep insights.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

