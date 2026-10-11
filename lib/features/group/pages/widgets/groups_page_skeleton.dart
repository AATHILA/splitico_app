import 'package:flutter/material.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/widgets/shimmer_loading.dart';

class GroupsPageSkeleton extends StatelessWidget {
  const GroupsPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.l),
          // Top Row: Title + New Button
          const ShimmerLoading(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 140, height: 28, borderRadius: 6),
                SkeletonBox(width: 80, height: 36, borderRadius: 18),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.l),

          // Search Bar Placeholder
          const ShimmerLoading(
            child: SkeletonBox(height: 48, borderRadius: 24),
          ),
          const SizedBox(height: AppSizes.l),

          // Category Chips Row
          ShimmerLoading(
            child: Row(
              children: List.generate(
                4,
                (index) => const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SkeletonBox(width: 65, height: 32, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.l),

          // Group Cards
          Expanded(
            child: ShimmerLoading(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SkeletonBox(width: 48, height: 48, borderRadius: 14),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 130, height: 16, borderRadius: 4),
                            SizedBox(height: 8),
                            SkeletonBox(width: 80, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 60, height: 18, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
