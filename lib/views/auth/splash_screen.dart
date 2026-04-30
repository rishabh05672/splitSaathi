import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Splash screen with animated logo and auth check.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(Duration(milliseconds: AppConstants.splashDuration));
    if (!mounted) return;
    final authVm = context.read<AuthViewModel>();
    final isLoggedIn = await authVm.checkAuthState();
    if (!mounted) return;
    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 50, color: Colors.white),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            // App Name (Staggered Letter Animation)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: AppStrings.appName.split('').asMap().entries.map((entry) {
                return Text(
                  entry.value,
                  style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
                ).animate()
                 .fadeIn(delay: Duration(milliseconds: 300 + (entry.key * 100)))
                 .slideX(begin: -0.5, end: 0, delay: Duration(milliseconds: 300 + (entry.key * 100)), duration: 400.ms, curve: Curves.easeOutBack);
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Tagline (Staggered Character Animation)
            Wrap(
              alignment: WrapAlignment.center,
              children: AppStrings.appTagline.split('').asMap().entries.map((entry) {
                return Text(
                  entry.value,
                  style: AppTextStyles.bodyMedium,
                ).animate()
                 .fadeIn(delay: Duration(milliseconds: 1000 + (entry.key * 30)))
                 .slideX(begin: -0.2, end: 0, delay: Duration(milliseconds: 1000 + (entry.key * 30)), duration: 300.ms);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
