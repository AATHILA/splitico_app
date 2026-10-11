import 'package:flutter/material.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/widgets/shimmer_loading.dart';

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // 1. INDIGO HEADER WITH TRANSLUCENT GLOW
          // ==========================================
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSizes.xxl,
              topPadding + AppSizes.m,
              AppSizes.xxl,
              AppSizes.xxxl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSizes.radiusXXL),
                bottomRight: Radius.circular(AppSizes.radiusXXL),
              ),
            ),
            child: ShimmerLoading(
              // Translucent glowing white shimmer on blue
              baseColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Action Buttons (My QR, Scanner)
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 60, height: 14, borderRadius: 4),
                          SizedBox(height: 8),
                          SkeletonBox(width: 130, height: 22, borderRadius: 6),
                        ],
                      ),
                      const Spacer(),
                      const SkeletonBox(width: 72, height: 32, borderRadius: 12),
                      const SizedBox(width: 8),
                      const SkeletonBox(width: 34, height: 34, borderRadius: 17),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Glassmorphic 3-Column Balance Card Skeleton
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: AppSizes.xxl,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL + 4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBalanceColSkeleton(),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        _buildBalanceColSkeleton(),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        _buildBalanceColSkeleton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // 2. MAIN BODY (GROUPS + RECENT ACTIVITY)
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xxl,
              vertical: AppSizes.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Groups Section Title
                const ShimmerLoading(
                  child: SkeletonBox(width: 120, height: 18, borderRadius: 4),
                ),
                const SizedBox(height: AppSizes.m),

                // Group Chips Carousel
                ShimmerLoading(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SkeletonBox(width: 20, height: 20, borderRadius: 10),
                              SizedBox(width: 8),
                              SkeletonBox(width: 60, height: 12, borderRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Recent Activity Title
                const ShimmerLoading(
                  child: SkeletonBox(width: 140, height: 18, borderRadius: 4),
                ),
                const SizedBox(height: AppSizes.m),

                // Real Card-Style Expense Items
                ...List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.m),
                    padding: const EdgeInsets.all(AppSizes.xl),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF334155)
                            : AppColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ShimmerLoading(
                      child: Row(
                        children: [
                          // Category Icon box
                          const SkeletonBox(width: 52, height: 52, borderRadius: 14),
                          const SizedBox(width: 14),

                          // Title and details
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                                SizedBox(height: 8),
                                SkeletonBox(width: 75, height: 10, borderRadius: 4),
                              ],
                            ),
                          ),

                          // Amount and Date
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SkeletonBox(width: 55, height: 14, borderRadius: 4),
                              SizedBox(height: 8),
                              SkeletonBox(width: 40, height: 10, borderRadius: 4),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBalanceColSkeleton() {
    return const Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: 55, height: 11, borderRadius: 3),
          SizedBox(height: 6),
          SkeletonBox(width: 70, height: 18, borderRadius: 4),
        ],
      ),
    );
  }
}
