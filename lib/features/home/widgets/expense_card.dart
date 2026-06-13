import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/text_styles.dart';

class ExpenseCard extends StatelessWidget {
  final String title;
  final String groupName;
  final String payerName;
  final double amount;
  final bool
  isOwed; // True if "You paid" (shows +₹amount in green), False if others paid (shows -₹amount in red)
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.title,
    required this.groupName,
    required this.payerName,
    required this.amount,
    required this.isOwed,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount =
        '${isOwed ? '+' : '-'}₹${amount.toStringAsFixed(0)}';
    final amountStyle =
        isOwed ? AppTextStyles.expensePositive : AppTextStyles.expenseNegative;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.m),
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon Container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusM + 2),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: AppSizes.iconM),
              ),
            ),
            const SizedBox(width: AppSizes.l),
            // Title & Subtitle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.expenseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '$groupName • $payerName paid',
                    style: AppTextStyles.expenseSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s),
            // Amount
            Text(formattedAmount, style: amountStyle),
          ],
        ),
      ),
    );
  }
}
