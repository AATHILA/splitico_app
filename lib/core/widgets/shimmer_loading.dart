import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Modern slate tones look much smoother and softer than raw grey
    final defaultBase = isDark ? const Color(0xFF262D38) : const Color(0xFFE2E8F0);
    final defaultHighlight = isDark ? const Color(0xFF3B4454) : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBase,
      highlightColor: highlightColor ?? defaultHighlight,
      child: child,
    );
  }
}

/// Generic rounded placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
