import 'package:flutter/material.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/widgets/shimmer_loading.dart';

class AnalyticsPageSkeleton extends StatelessWidget {
  const AnalyticsPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl, vertical: AppSizes.l),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header (Title + Period Selector)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 130, height: 26, borderRadius: 6),
                SkeletonBox(width: 100, height: 32, borderRadius: 16),
              ],
            ),
            const SizedBox(height: AppSizes.l),

            // Metrics Summary Card
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 70, height: 12, borderRadius: 4),
                        SizedBox(height: 8),
                        SkeletonBox(width: 90, height: 20, borderRadius: 4),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 70, height: 12, borderRadius: 4),
                        SizedBox(height: 8),
                        SkeletonBox(width: 90, height: 20, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Category Chart Placeholder Box
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 16, borderRadius: 4),
                  Spacer(),
                  Center(
                    child: SkeletonBox(width: 130, height: 130, borderRadius: 65),
                  ),
                  Spacer(),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Top Spenders Placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 16, borderRadius: 4),
                  SizedBox(height: 16),
                  SkeletonBox(height: 16, borderRadius: 4),
                  SizedBox(height: 12),
                  SkeletonBox(height: 16, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
