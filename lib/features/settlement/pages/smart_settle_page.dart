import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SmartSettlePage extends StatelessWidget {
  const SmartSettlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.xxl,
            topPadding > 0 ? 0 : AppSizes.m,
            AppSizes.xxl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top status & Back Button bar
              _buildAppBar(context),
              const SizedBox(height: AppSizes.l),

              // 2. Optimization Banner
              _buildOptimizationBanner(context),
              const SizedBox(height: AppSizes.xxl),

              // 3. Section Title
              Text(
                'Settlement Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // 4. Settlement Cards Scroll View
              Expanded(
                child: _buildSettlementPlanList(context, bottomPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Back button in soft rounded box
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.m),
            // Title
            Text(
              'Smart Settle',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptimizationBanner(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.l, vertical: AppSizes.l + 2),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF312E81).withValues(alpha: 0.35)
            : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF4338CA).withValues(alpha: 0.4)
              : const Color(0xFFD3E0FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '✨ Optimized for fewer transactions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '3 payments instead of 6 • Saves everyone time',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementPlanList(BuildContext context, double bottomPadding) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24 + bottomPadding),
      children: [
        // Card 1: A pays R Rahul (with payment method chips)
        _buildPlanCard(
          context: context,
          fromInitial: 'A',
          fromColor: const Color(0xFF7C3AED), // purple
          toInitial: 'R',
          toColor: const Color(0xFF4C49ED), // blue/indigo
          toName: 'Rahul',
          amount: '₹500',
          showPaymentMethods: true,
        ),

        // Card 2: R pays K Kiran
        _buildPlanCard(
          context: context,
          fromInitial: 'R',
          fromColor: const Color(0xFF4C49ED), // blue/indigo
          toInitial: 'K',
          toColor: const Color(0xFF10B981), // green
          toName: 'Kiran',
          amount: '₹300',
          showPaymentMethods: false,
        ),

        // Card 3: S pays A Athila
        _buildPlanCard(
          context: context,
          fromInitial: 'S',
          fromColor: const Color(0xFFEC4899), // pink
          toInitial: 'A',
          toColor: const Color(0xFF7C3AED), // purple
          toName: 'Athila',
          amount: '₹750',
          showPaymentMethods: false,
        ),
        const SizedBox(height: AppSizes.m),

        // Bottom CTA Button: Mark All as Settled
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All balances marked as settled! 🎉'),
                backgroundColor: AppColors.expensePositive,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Mark All as Settled ✓',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String fromInitial,
    required Color fromColor,
    required String toInitial,
    required Color toColor,
    required String toName,
    required String amount,
    required bool showPaymentMethods,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.m),
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Sender Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: fromColor,
                child: Text(
                  fromInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s + 2),

              // "pays" Label
              Text(
                'pays',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: AppSizes.s + 2),

              // Receiver Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: toColor,
                child: Text(
                  toInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.s + 2),

              // Receiver Name
              Text(
                toName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),

              // Amount
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Render payment methods container if true
          if (showPaymentMethods) ...[
            const SizedBox(height: AppSizes.m),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PaymentMethodChip(icon: '💳', label: 'UPI'),
                  _PaymentMethodChip(icon: '🏛️', label: 'Bank'),
                  _PaymentMethodChip(icon: '📱', label: 'GPay'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String icon;
  final String label;

  const _PaymentMethodChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF065F46),
          ),
        ),
      ],
    );
  }
}
