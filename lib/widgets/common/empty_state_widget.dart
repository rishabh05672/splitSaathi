import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Empty state widget with icon, title, and subtitle.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: AppColors.primary.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 20),
        Text(title, style: AppTextStyles.heading3, textAlign: TextAlign.center),
        if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    )));
  }
}
