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
  final DateTime dateTime;
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
    required this.dateTime,
    this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final isDifferentYear = dt.year != DateTime.now().year;
    if (isDifferentYear) {
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$minute $period';
    } else {
      return '${dt.day} ${months[dt.month - 1]} • $hour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount =
        '${isOwed ? '+' : '-'}₹${amount.toStringAsFixed(2)}';
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: AppTextStyles.expenseSubtitle,
                      children: [
                        TextSpan(
                          text: groupName,
                          style: const TextStyle(
                            color: Color(
                              0xFF334155,
                            ), // Darker slate color for trip name
                          ),
                        ),
                        const TextSpan(text: ' • '),
                        TextSpan(text: '$payerName paid'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formattedAmount, style: amountStyle),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(dateTime),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8), // Nice soft grey color
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
