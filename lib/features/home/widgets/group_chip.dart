import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/text_styles.dart';

class GroupChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const GroupChip({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.l,
          vertical: AppSizes.s + 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconS + 2,
              color: iconColor,
            ),
            const SizedBox(width: AppSizes.s),
            Text(
              label,
              style: AppTextStyles.groupChipText.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
