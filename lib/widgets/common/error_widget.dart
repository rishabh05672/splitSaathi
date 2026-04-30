import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Reusable error display widget.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
        const SizedBox(height: 16),
        Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        if (onRetry != null) ...[const SizedBox(height: 16), TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))],
      ],
    )));
  }
}
