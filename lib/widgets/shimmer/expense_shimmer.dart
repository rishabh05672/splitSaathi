import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer placeholder matching the shape of expense cards.
class ExpenseShimmer extends StatelessWidget {
  final int itemCount;
  const ExpenseShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar placeholder
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 120, height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 10, color: Colors.white),
                      ],
                    ),
                  ),
                  // Amount placeholder
                  Container(width: 60, height: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
