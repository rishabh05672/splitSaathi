import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

import '../../models/expense_model.dart';

/// Screen for adding or editing an expense.
class AddExpenseScreen extends StatefulWidget {
  final String groupId;
  final ExpenseModel? expense;
  const AddExpenseScreen({super.key, required this.groupId, this.expense});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_ExpenseItem> _items = [];
  bool _isSaving = false;
  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _items.add(_ExpenseItem(
        nameCtrl: TextEditingController(text: widget.expense!.itemName),
        amountCtrl: TextEditingController(text: widget.expense!.amount.toStringAsFixed(0)),
      ));
    } else {
      _addItem(); // Start with one item
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_ExpenseItem(
        nameCtrl: TextEditingController(),
        amountCtrl: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        final item = _items.removeAt(index);
        item.nameCtrl.dispose();
        item.amountCtrl.dispose();
      });
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.nameCtrl.dispose();
      item.amountCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (_isEditing) {
      await _edit();
    } else {
      await _add();
    }
  }

  Future<void> _edit() async {
    final authVm = context.read<AuthViewModel>();
    final vm = context.read<ExpenseViewModel>();
    if (!_formKey.currentState!.validate()) return;
    if (authVm.currentUser == null) return;

    setState(() => _isSaving = true);
    try {
      final success = await vm.editExpense(
        groupId: widget.groupId,
        expense: widget.expense!,
        newItemName: _items[0].nameCtrl.text.trim(),
        newAmount: double.parse(_items[0].amountCtrl.text.trim()),
        editedById: authVm.currentUser!.uid,
        editedByName: authVm.currentUser!.name,
        editedByColor: authVm.currentUser!.color,
      );

      if (success && mounted) {
        SnackbarHelper.showSuccess(context, 'Expense updated successfully!');
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _add() async {
    final authVm = context.read<AuthViewModel>();
    final vm = context.read<ExpenseViewModel>();
    
    if (!_formKey.currentState!.validate()) return;
    if (authVm.currentUser == null) return;
    
    final user = authVm.currentUser!;
    setState(() => _isSaving = true);
    
    int successCount = 0;
    try {
      // Process sequentially to avoid ViewModel race conditions and flickering
      for (var item in _items) {
        final success = await vm.addExpense(
          groupId: widget.groupId,
          itemName: item.nameCtrl.text.trim(),
          amount: double.parse(item.amountCtrl.text.trim()),
          addedById: user.uid,
          addedByName: user.name,
          addedByColor: user.color,
        );
        if (success) successCount++;
      }

      if (!mounted) return;
      if (successCount == _items.length) {
        SnackbarHelper.showSuccess(context, 'Successfully added all expenses!');
        context.pop();
      } else if (successCount > 0) {
        SnackbarHelper.showWarning(context, 'Added $successCount out of ${_items.length} expenses.');
        context.pop();
      } else if (vm.error != null) {
        SnackbarHelper.showError(context, vm.error!);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final accentColor = AppColors.fromHex(authVm.currentUser?.color ?? '#6C63FF');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : AppStrings.addExpense),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Hero Section
            Container(
              margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: accentColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(_isEditing ? Icons.edit_note_rounded : Icons.receipt_long_rounded, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Modify Details' : 'New Transaction',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 18),
                        ),
                        Text(
                          _isEditing ? 'Update the amount or item name' : 'Add one or more items to the group',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 5, color: accentColor)),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                      child: Text(
                                        'ITEM ${index + 1}',
                                        style: AppTextStyles.label.copyWith(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_items.length > 1 && !_isEditing)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 22),
                                        onPressed: () => _removeItem(index),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  controller: item.nameCtrl,
                                  label: 'Description',
                                  hint: 'e.g., Dinner, Groceries',
                                  prefixIcon: Icons.shopping_bag_outlined,
                                  validator: Validators.itemName,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: item.amountCtrl,
                                  label: 'Amount',
                                  hint: '0.00',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  prefixIcon: Icons.currency_rupee_rounded,
                                  validator: Validators.amount,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 80).ms).scale(curve: Curves.easeOutBack);
                },
              ),
            ),

            // Bottom Dashboard
            Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isEditing) ...[
                    CustomButton(
                      text: 'Add Another Item',
                      onPressed: _isSaving ? null : _addItem,
                      icon: Icons.add_circle_outline_rounded,
                      isOutlined: true,
                      color: accentColor,
                    ),
                    const SizedBox(height: 12),
                  ],
                  CustomButton(
                    text: _isEditing ? 'Update Expense' : 'Save All Expenses',
                    onPressed: _handleSave,
                    icon: _isEditing ? Icons.published_with_changes_rounded : Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    isLoading: _isSaving || vm.isLoading,
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class _ExpenseItem {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  _ExpenseItem({required this.nameCtrl, required this.amountCtrl});
}
