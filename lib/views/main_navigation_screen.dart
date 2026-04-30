import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'dashboard/global_dashboard_screen.dart';

/// Main shell for the app with a liquid-style bottom navigation bar.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _pageIndex = 1; // Default to Home (Group List)
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final accentColor = AppColors.fromHex(authVm.currentUser?.color ?? '#6C63FF');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Only nav through bar
        children: const [
          GlobalDashboardScreen(),
          HomeScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _pageIndex,
        height: 65.0,
        items: <Widget>[
          Icon(Icons.dashboard_rounded, size: 28, color: _pageIndex == 0 ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.5)),
          Icon(Icons.grid_view_rounded, size: 28, color: _pageIndex == 1 ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.5)),
          Icon(Icons.person_rounded, size: 28, color: _pageIndex == 2 ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.5)),
        ],
        color: AppColors.surface,
        buttonBackgroundColor: accentColor,
        backgroundColor: Colors.transparent, // Important for liquid look
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (index) {
          setState(() => _pageIndex = index);
          _pageController.animateToPage(
            index, 
            duration: const Duration(milliseconds: 500), 
            curve: Curves.easeOutCubic
          );
        },
      ),
    );
  }
}
