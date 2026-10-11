import 'package:flutter/material.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/widgets/shimmer_loading.dart';

class GroupDetailsSkeleton extends StatelessWidget {
  const GroupDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Purple Gradient Header
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSizes.xxl,
                topPadding + AppSizes.m,
                AppSizes.xxl,
                AppSizes.xxl,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5E5AFA), Color(0xFF4C49ED)],
                ),
              ),
              child: ShimmerLoading(
                baseColor: Colors.white.withValues(alpha: 0.15),
                highlightColor: Colors.white.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar (Back button and Actions)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        SkeletonBox(width: 36, height: 36, borderRadius: 18),
                        SkeletonBox(width: 36, height: 36, borderRadius: 18),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Group Name & Category Chip
                    const SkeletonBox(width: 170, height: 26, borderRadius: 6),
                    const SizedBox(height: 10),
                    const SkeletonBox(width: 80, height: 22, borderRadius: 11),
                    const SizedBox(height: 24),

                    // Two Stats Cards (Total Spent & Your Share)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 75,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 75,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // 2. Members Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
              child: ShimmerLoading(
                child: Row(
                  children: List.generate(
                    4,
                    (index) => const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          SkeletonBox(width: 48, height: 48, borderRadius: 24),
                          SizedBox(height: 6),
                          SkeletonBox(width: 42, height: 10, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.xxl),

            // 3. Expenses Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.xxl),
              child: ShimmerLoading(
                child: SkeletonBox(width: 110, height: 20, borderRadius: 4),
              ),
            ),
            const SizedBox(height: AppSizes.l),

            // 4. Expenses Timeline Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
              child: ShimmerLoading(
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SkeletonBox(width: 44, height: 44, borderRadius: 12),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                                SizedBox(height: 6),
                                SkeletonBox(width: 70, height: 10, borderRadius: 4),
                              ],
                            ),
                          ),
                          SkeletonBox(width: 60, height: 16, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
