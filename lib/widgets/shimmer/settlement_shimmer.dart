import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer placeholder matching the shape of settlement cards.
class SettlementShimmer extends StatelessWidget {
  const SettlementShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Summary card placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              ),
            ),
            const SizedBox(height: 16),
            // Member breakdown placeholders
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                ),
              ),
            )),
            const SizedBox(height: 16),
            // Transaction card placeholders
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
