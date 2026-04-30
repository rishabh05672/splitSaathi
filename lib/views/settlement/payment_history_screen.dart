import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Payment history screen placeholder.
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment History')),
      body: const Center(child: Text('Payment history')));
  }
}
