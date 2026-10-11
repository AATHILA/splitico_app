import 'package:flutter/material.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/widgets/shimmer_loading.dart';

class BalancesPageSkeleton extends StatelessWidget {
  const BalancesPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indigo Header with Net Balance Card
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
              baseColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.35),
              child: Column(
                children: [
                  const SkeletonBox(width: 100, height: 14, borderRadius: 4),
                  const SizedBox(height: 10),
                  const SkeletonBox(width: 160, height: 34, borderRadius: 8),
                  const SizedBox(height: 20),
                  // Summary stats row
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Settlement List Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
            child: ShimmerLoading(
              child: Column(
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SkeletonBox(width: 46, height: 46, borderRadius: 23),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 120, height: 16, borderRadius: 4),
                              SizedBox(height: 6),
                              SkeletonBox(width: 70, height: 11, borderRadius: 4),
                            ],
                          ),
                        ),
                        SkeletonBox(width: 75, height: 32, borderRadius: 16),
                      ],
                    ),
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
