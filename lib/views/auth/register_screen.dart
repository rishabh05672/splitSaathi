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

/// Register screen with name, email, password, confirm password.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final success = await vm.registerWithEmail(name: _nameCtrl.text.trim(), email: _emailCtrl.text, password: _passwordCtrl.text);
    if (!mounted) return;
    if (success) { context.go('/home'); }
    else if (vm.error != null) { SnackbarHelper.showError(context, vm.error!); }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(builder: (context, vm, _) {
      return LoadingOverlay(isLoading: vm.isLoading, child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text('Create Account', style: AppTextStyles.heading1, textAlign: TextAlign.center).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text('Join SplitSaathi today', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),
            CustomTextField(controller: _nameCtrl, label: AppStrings.name, hint: 'Enter your name', prefixIcon: Icons.person_outline, validator: Validators.name)
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 16),
            CustomTextField(controller: _emailCtrl, label: AppStrings.email, hint: 'Enter your email', keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined, validator: Validators.email)
                .animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, delay: 300.ms, duration: 300.ms),
            const SizedBox(height: 16),
            CustomTextField(controller: _passwordCtrl, label: AppStrings.password, hint: 'Create a password', isPassword: true, prefixIcon: Icons.lock_outline, validator: Validators.password)
                .animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, delay: 400.ms, duration: 300.ms),
            const SizedBox(height: 16),
            CustomTextField(controller: _confirmCtrl, label: AppStrings.confirmPassword, hint: 'Confirm your password', isPassword: true, prefixIcon: Icons.lock_outline,
              validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text))
                .animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, delay: 500.ms, duration: 300.ms),
            const SizedBox(height: 24),
            CustomButton(text: AppStrings.signUp, onPressed: _register).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, delay: 600.ms, duration: 300.ms),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(AppStrings.alreadyHaveAccount, style: AppTextStyles.bodyMedium),
              GestureDetector(onTap: () => context.go('/login'),
                child: Text(AppStrings.signIn, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold))),
            ]).animate().fadeIn(delay: 700.ms),
          ],
        )))),
      ));
    });
  }
}
