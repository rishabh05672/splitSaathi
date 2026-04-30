import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// Login screen with email/password and Google Sign-In.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final success = await vm.signInWithEmail(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else if (vm.error != null) {
      SnackbarHelper.showError(context, vm.error!);
    }
  }

  Future<void> _signInWithGoogle() async {
    final vm = context.read<AuthViewModel>();
    final success = await vm.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else if (vm.error != null) {
      SnackbarHelper.showError(context, vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return LoadingOverlay(
          isLoading: vm.isLoading,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      // Logo
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.receipt_long_rounded, size: 36, color: Colors.white),
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
                      const SizedBox(height: 24),
                      Text(AppStrings.appName, style: AppTextStyles.heading1.copyWith(color: AppColors.primary), textAlign: TextAlign.center)
                          .animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 8),
                      Text('Welcome back!', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)
                          .animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      const SizedBox(height: 40),
                      // Email
                      CustomTextField(
                        controller: _emailCtrl,
                        label: AppStrings.email,
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: Validators.email,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, delay: 300.ms, duration: 300.ms),
                      const SizedBox(height: 16),
                      // Password
                      CustomTextField(
                        controller: _passwordCtrl,
                        label: AppStrings.password,
                        hint: 'Enter your password',
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        validator: Validators.password,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, delay: 400.ms, duration: 300.ms),
                      const SizedBox(height: 24),
                      // Sign In Button
                      CustomButton(
                        text: AppStrings.signIn,
                        onPressed: _signIn,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, delay: 500.ms, duration: 300.ms),
                      const SizedBox(height: 16),
                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.divider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: AppTextStyles.bodySmall),
                          ),
                          const Expanded(child: Divider(color: AppColors.divider)),
                        ],
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 16),
                      // Google Sign In
                      OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                        label: Text(AppStrings.signInWithGoogle, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(height: 24),
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppStrings.dontHaveAccount, style: AppTextStyles.bodyMedium),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(AppStrings.signUp, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
