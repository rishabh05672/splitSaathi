import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Role badge chip with color coding and icon.
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (role) {
      'superAdmin' => (AppColors.roleSuperAdmin, 'Super Admin', '👑'),
      'admin' => (AppColors.roleAdmin, 'Admin', '🔑'),
      'editor' => (AppColors.roleEditor, 'Editor', '✏️'),
      _ => (AppColors.roleViewer, 'Viewer', '👁️'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
