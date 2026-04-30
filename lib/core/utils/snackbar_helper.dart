import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Helper class for showing styled notifications at the TOP of the app.
/// Provides success, error, warning, and info variants using the root Overlay.
class SnackbarHelper {
  SnackbarHelper._();

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    _showTopNotification(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    _showTopNotification(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    _showTopNotification(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: AppColors.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    _showTopNotification(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.primary,
    );
  }

  /// Internal method to show a top-floating notification.
  static void _showTopNotification(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    // Use rootOverlay: true to ensure it shows above everything (loaders, bottom sheets, etc.)
    final overlay = Overlay.of(context, rootOverlay: true);
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -2.0), // Start further up
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller, 
      curve: Curves.elasticOut, // More "premium" bouncy effect
    ));

    _controller.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted || _isDismissing) return;
    setState(() => _isDismissing = true);
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.backgroundColor.computeLuminance() < 0.5;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: _dismiss,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

