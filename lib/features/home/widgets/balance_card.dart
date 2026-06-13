import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/text_styles.dart';

class BalanceCard extends StatelessWidget {
  final double youOwe;
  final double owedToYou;
  final double netBalance;

  const BalanceCard({
    super.key,
    required this.youOwe,
    required this.owedToYou,
    required this.netBalance,
  });

  @override
  Widget build(BuildContext context) {
    final netPrefix = netBalance >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.xxl,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL + 4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Column 1: You owe
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You owe', style: AppTextStyles.balanceLabel),
                  const SizedBox(height: AppSizes.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${youOwe.toStringAsFixed(0)}',
                      style: AppTextStyles.oweAmount,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
              thickness: 1,
            ),
            // Column 2: Owed to you
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Owed to you', style: AppTextStyles.balanceLabel),
                  const SizedBox(height: AppSizes.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${owedToYou.toStringAsFixed(0)}',
                      style: AppTextStyles.owedAmount,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
              thickness: 1,
            ),
            // Column 3: Net balance
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Net balance', style: AppTextStyles.balanceLabel),
                  const SizedBox(height: AppSizes.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$netPrefix₹${netBalance.toStringAsFixed(0)}',
                      style: AppTextStyles.netBalance,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
