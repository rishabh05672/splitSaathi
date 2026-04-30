import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:split_saathi/core/utils/snackbar_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helper.dart';
import 'package:split_saathi/widgets/common/loading_overlay.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/common/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';

/// Profile screen showing user info with edit options.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();

  Future<void> _changePhoto(AuthViewModel vm) async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (status.isDenied) status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      if (mounted) SnackbarHelper.showWarning(context, 'Please enable gallery access in settings');
      openAppSettings();
      return;
    }

    if (!status.isGranted) {
      if (mounted) SnackbarHelper.showError(context, 'Permission denied');
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image != null) {
      await vm.uploadProfileImage(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    if (user == null) return const SizedBox.shrink();

    final userColor = AppColors.fromHex(user.color);

    return LoadingOverlay(
      isLoading: authVm.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Premium Header ---
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: userColor,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            userColor,
                            userColor.withValues(alpha: 0.8),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                    // Decorative Circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.1)),
                    ),
                    // Profile Info Overlay
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        _buildProfileAvatar(user, authVm, userColor),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Profile Content ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // --- Stats Row ---
                    _buildStatsRow(user).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                    
                    const SizedBox(height: 32),
                    
                    // --- Account Settings Section ---
                    _buildSectionHeader('ACCOUNT SETTINGS'),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Display Name',
                        subtitle: 'Change how others see you',
                        color: userColor,
                        onTap: () => _showEditNameDialog(context, authVm, user.name),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // --- Security & Privacy ---
                    _buildSectionHeader('SECURITY'),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        subtitle: 'Safely exit your account',
                        color: AppColors.error,
                        onTap: () => _handleLogout(context, authVm),
                      ),
                      _buildSettingsTile(
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account',
                        subtitle: 'Permanently remove all data',
                        color: Colors.grey,
                        onTap: () => _handleDeleteAccount(context, authVm),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel user, AuthViewModel vm, Color color) {
    return Stack(
      children: [
        // Glow Effect
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          child: UserAvatar(
            name: user.name,
            colorHex: user.color,
            photoUrl: user.photoUrl,
            size: 110,
          ),
        ),
        // Edit Button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _changePhoto(vm),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.camera_alt_rounded, color: color, size: 20),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      children: [
        Expanded(child: _buildStatItem('MEMBER SINCE', DateHelper.memberSince(user.createdAt))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('YOUR COLOR', user.color.toUpperCase(), color: AppColors.fromHex(user.color))),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (color != null) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.label.copyWith(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textHint.withValues(alpha: 0.5)),
    );
  }


  Future<void> _handleLogout(BuildContext context, AuthViewModel vm) async {
    final confirmed = await showCustomDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to exit? We will miss you!',
      confirmText: 'Sign Out',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      await vm.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, AuthViewModel vm) async {
    final confirmed = await showCustomDialog(
      context: context,
      title: 'Delete Account',
      message: 'This action is permanent and will remove all your data. Are you absolutely sure?',
      confirmText: 'Delete Forever',
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      final success = await vm.deleteAccount();
      if (success && context.mounted) {
        context.go('/login');
        SnackbarHelper.showSuccess(context, 'Account deleted successfully');
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context, AuthViewModel vm, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final userColor = AppColors.fromHex(vm.currentUser?.color ?? '#6C63FF');

    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: userColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.edit_rounded, color: userColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Update Name', style: AppTextStyles.heading3.copyWith(fontSize: 20)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose how you want to be seen by your group members.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: Icon(Icons.person_rounded, color: userColor.withValues(alpha: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: userColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    final success = await vm.updateName(controller.text.trim());
                    if (success && ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: userColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> showCustomDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text(title, style: AppTextStyles.heading3.copyWith(fontSize: 22)),
        content: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
