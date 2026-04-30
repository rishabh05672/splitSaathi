import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/invite_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_overlay.dart';

/// Join request screen — validates invite token and lets user request to join.
class JoinRequestScreen extends StatefulWidget {
  final String groupId;
  final String? token;
  const JoinRequestScreen({super.key, required this.groupId, this.token});
  @override
  State<JoinRequestScreen> createState() => _JoinRequestScreenState();
}

class _JoinRequestScreenState extends State<JoinRequestScreen> {
  bool _validated = false;
  String? _groupName;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _validateToken();
    }
  }

  Future<void> _validateToken() async {
    final vm = context.read<InviteViewModel>();
    final invite = await vm.validateToken(widget.token!);
    if (invite != null && mounted) {
      setState(() {
        _validated = true;
        _groupName = invite.groupName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteVm = context.watch<InviteViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return LoadingOverlay(
      isLoading: inviteVm.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Join Group')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _validated ? Icons.group_add_rounded : Icons.link_rounded,
                    size: 44,
                    color: _validated ? AppColors.accent : AppColors.primary,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 24),

                // ── Status Messages ───────────────────────
                if (inviteVm.error != null) ...[
                  // Error state
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            inviteVm.error!,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Go Home',
                    onPressed: () => context.go('/home'),
                  ),
                ] else if (inviteVm.successMessage != null) ...[
                  // Success state
                  Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success)
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  Text(
                    inviteVm.successMessage!,
                    style: AppTextStyles.heading3.copyWith(color: AppColors.success),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Go Home',
                    onPressed: () => context.go('/home'),
                  ),
                ] else if (_validated && _groupName != null) ...[
                  // Validated — show group info and join button
                  Text(
                    'You\'ve been invited to',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  Text(
                    _groupName!,
                    style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Request to join this group?\nAn admin will review your request.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: AppStrings.sendJoinRequest,
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      if (authVm.currentUser == null) {
                        context.go('/login');
                        return;
                      }
                      final invite = inviteVm.currentInvite!;
                      await inviteVm.submitJoinRequest(
                        groupId: invite.groupId,
                        user: authVm.currentUser!,
                        token: invite.token,
                      );
                    },
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, duration: 300.ms),
                ] else ...[
                  // Validating or invalid token
                  Text(
                    'Validating invite...',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
