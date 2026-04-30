import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/group_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../core/utils/validators.dart';

/// Screen for creating a new group with name and emoji picker.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '💰';

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();
    final groupVm = context.read<GroupViewModel>();
    if (authVm.currentUser == null) return;

    final group = await groupVm.createGroup(name: _nameCtrl.text.trim(), iconEmoji: _selectedEmoji, creator: authVm.currentUser!);
    if (!mounted) return;
    if (group != null) {
      SnackbarHelper.showSuccess(context, 'Group created!');
      context.go('/groups/${group.groupId}');
    } else if (groupVm.error != null) {
      SnackbarHelper.showError(context, groupVm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupVm = context.watch<GroupViewModel>();
    return LoadingOverlay(isLoading: groupVm.isLoading, child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.createGroup)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emoji selector
          Center(child: GestureDetector(
            onTap: () => _showEmojiPicker(),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
              child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 36))),
            ),
          )).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8), duration: 300.ms),
          const SizedBox(height: 8),
          Text('Tap to change icon', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          CustomTextField(controller: _nameCtrl, label: AppStrings.groupName, hint: 'e.g., Roommates, Trip to Goa', prefixIcon: Icons.group_outlined,
            validator: Validators.groupName).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 32),
          CustomButton(text: AppStrings.create, onPressed: _create, icon: Icons.add).animate().fadeIn(delay: 400.ms),
        ],
      ))),
    ));
  }

  void _showEmojiPicker() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(AppStrings.pickEmoji, style: AppTextStyles.heading3),
        const SizedBox(height: 16),
        GridView.builder(shrinkWrap: true, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
          itemCount: AppConstants.groupEmojis.length,
          itemBuilder: (_, i) {
            final emoji = AppConstants.groupEmojis[i];
            return GestureDetector(
              onTap: () { setState(() => _selectedEmoji = emoji); Navigator.pop(context); },
              child: Container(
                decoration: BoxDecoration(color: emoji == _selectedEmoji ? AppColors.primaryLight.withValues(alpha: 0.3) : null, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
              ),
            );
          }),
      ])));
  }
}
