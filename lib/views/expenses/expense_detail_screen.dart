import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/expense_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Expense detail screen — shows full expense info, edit history, and edit/delete.
class ExpenseDetailScreen extends StatefulWidget {
  final String groupId;
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.groupId, required this.expenseId});
  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _isEditing = false;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  ExpenseModel? _findExpense(ExpenseViewModel vm) {
    try {
      return vm.expenses.firstWhere((e) => e.expenseId == widget.expenseId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final groupVm = context.watch<GroupViewModel>();
    final expense = _findExpense(vm);

    if (expense == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Expense Details')),
        body: const Center(child: Text('Expense not found')),
      );
    }

    final canEdit = groupVm.currentMember?.isAdmin == true ||
        (groupVm.currentMember?.isEditor == true && expense.addedById == authVm.currentUser?.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          if (canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _nameCtrl.text = expense.itemName;
                  _amountCtrl.text = expense.amount.toStringAsFixed(0);
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Expense Info Card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isEditing
                  ? Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _nameCtrl,
                            label: AppStrings.itemName,
                            prefixIcon: Icons.shopping_bag_outlined,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _amountCtrl,
                            label: AppStrings.amount,
                            prefix: '${AppStrings.currency} ',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.currency_rupee,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: AppStrings.cancel,
                                  isOutlined: true,
                                  onPressed: () => setState(() => _isEditing = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: AppStrings.save,
                                  onPressed: () async {
                                    if (authVm.currentUser == null) return;
                                    final user = authVm.currentUser!;
                                    final success = await vm.editExpense(
                                      groupId: widget.groupId,
                                      expense: expense,
                                      newItemName: _nameCtrl.text.trim(),
                                      newAmount: double.tryParse(_amountCtrl.text.trim()) ?? expense.amount,
                                      editedById: user.uid,
                                      editedByName: user.name,
                                      editedByColor: user.color,
                                    );
                                    if (success && context.mounted) {
                                      SnackbarHelper.showSuccess(context, AppStrings.expenseUpdated);
                                      setState(() => _isEditing = false);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Amount
                        Text(
                          '${AppStrings.currency}${expense.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 36,
                            color: AppColors.primary,
                          ),
                        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), duration: 300.ms),
                        const SizedBox(height: 8),
                        Text(expense.itemName, style: AppTextStyles.heading3),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 12),
                        // Added by
                        Row(
                          children: [
                            UserAvatar(name: expense.addedByName, colorHex: expense.addedByColor, size: 36),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Added by ${expense.addedByName}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                                Text(DateHelper.relativeTime(expense.timestamp), style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        if (expense.isDeleted) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                                const SizedBox(width: 4),
                                Text('Deleted', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── Edit History ──────────────────────────────
            if (expense.editHistory.isNotEmpty) ...[
              Text('Edit History', style: AppTextStyles.heading3.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              ...expense.editHistory.reversed.toList().asMap().entries.map((entry) {
                final i = entry.key;
                final edit = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 6),
                            Text(
                              'Edited by ${edit.editedByName}',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              DateHelper.relativeTime(edit.editedAt),
                              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (edit.oldItemName != edit.newItemName)
                          _changeRow('Item', edit.oldItemName, edit.newItemName),
                        if (edit.oldAmount != edit.newAmount)
                          _changeRow(
                            'Amount',
                            '${AppStrings.currency}${edit.oldAmount.toStringAsFixed(0)}',
                            '${AppStrings.currency}${edit.newAmount.toStringAsFixed(0)}',
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * i));
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _changeRow(String label, String oldVal, String newVal) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ', style: AppTextStyles.bodySmall),
          Text(
            oldVal,
            style: AppTextStyles.bodySmall.copyWith(
              decoration: TextDecoration.lineThrough,
              color: AppColors.error,
            ),
          ),
          const Text(' → ', style: TextStyle(fontSize: 12)),
          Text(
            newVal,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
