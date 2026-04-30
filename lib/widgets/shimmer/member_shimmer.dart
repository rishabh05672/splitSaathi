import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer placeholder matching the shape of member cards.
class MemberShimmer extends StatelessWidget {
  final int itemCount;
  const MemberShimmer({super.key, this.itemCount = 4});

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
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Container(width: 100, height: 14, color: Colors.white)),
                  Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
