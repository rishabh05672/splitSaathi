import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/invite_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_overlay.dart';

/// Screen for generating and sharing invite links.
class InviteScreen extends StatefulWidget {
  final String groupId;
  const InviteScreen({super.key, required this.groupId});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inviteVm = context.watch<InviteViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return LoadingOverlay(isLoading: inviteVm.isLoading, child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Members')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, size: 48, color: AppColors.primary)),
            const SizedBox(height: 24),
            Text('Add Group Members', style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Enter the email address of the person you want to add to this group.', 
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            
            // Email Invite Section
            TextField(
              controller: _emailCtrl,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'User Email Address',
                hintText: 'example@mail.com',
                prefixIcon: const Icon(Icons.email_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add Member Now',
              icon: Icons.add_circle_rounded,
              onPressed: () async {
                if (authVm.currentUser == null) return;
                final email = _emailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  SnackbarHelper.showError(context, 'Please enter a valid email');
                  return;
                }
                final success = await inviteVm.addMemberByEmail(
                  groupId: widget.groupId,
                  email: email,
                  addedBy: authVm.currentUser!,
                );
                if (context.mounted) {
                  if (success) {
                    SnackbarHelper.showSuccess(context, inviteVm.successMessage ?? 'Member added!');
                    _emailCtrl.clear();
                  } else {
                    SnackbarHelper.showError(context, inviteVm.error ?? 'Failed to add member');
                  }
                }
              },
            ),
          ],
        ),
      ),
    ));
  }
}
