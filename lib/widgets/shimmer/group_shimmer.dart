import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer placeholder matching the shape of group cards.
class GroupShimmer extends StatelessWidget {
  final int itemCount;
  const GroupShimmer({super.key, this.itemCount = 5});

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
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Emoji placeholder
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(width: 12),
                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 140, height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 10, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(width: 20, height: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
