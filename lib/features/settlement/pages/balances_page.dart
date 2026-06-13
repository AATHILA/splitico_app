import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'smart_settle_page.dart';

class BalancesPage extends StatelessWidget {
  const BalancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft off-white background
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
              // 1. Top status & Title header
              _buildHeader(),
              const SizedBox(height: AppSizes.l),

              // 2. Net Balance Gradient Card
              _buildNetBalanceCard(),
              const SizedBox(height: AppSizes.xxl),

              // 3. Section Title
              const Text(
                'Who owes whom',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // 4. Balances List
              Expanded(
                child: _buildBalancesList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone top indicators (9:41, Actions)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.m),
        const Text(
          'Balances',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNetBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5E5AFA),
            Color(0xFF4C49ED),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C49ED).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Net Balance Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 0.8,
                ),
              ),
              const Text(
                '₹2,360',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Right side: Group & Settlement Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Across 3 groups',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '6 pending\nsettlements',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesList(BuildContext context) {
    final balanceData = [
      {
        'name': 'Riya',
        'status': 'owes you',
        'initial': 'R',
        'avatarColor': const Color(0xFFEC4899), // pink
        'badgeBg': const Color(0xFFECFDF5), // light green
        'badgeText': const Color(0xFF059669), // dark green
        'amount': '₹1,200 →',
      },
      {
        'name': 'Athila',
        'status': 'owes you',
        'initial': 'A',
        'avatarColor': const Color(0xFF7C3AED), // purple
        'badgeBg': const Color(0xFFECFDF5), // light green
        'badgeText': const Color(0xFF059669), // dark green
        'amount': '₹800 →',
      },
      {
        'name': 'Kiran',
        'status': 'you owe',
        'initial': 'K',
        'avatarColor': const Color(0xFF10B981), // green
        'badgeBg': const Color(0xFFFEF2F2), // light red
        'badgeText': const Color(0xFFEF4444), // red
        'amount': '₹640 ←',
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...balanceData.map((data) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSizes.m),
            padding: const EdgeInsets.all(AppSizes.l),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
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
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: data['avatarColor'] as Color,
                  child: Text(
                    data['initial'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.m),

                // Name & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['status'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: data['badgeBg'] as Color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    data['amount'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: data['badgeText'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSizes.m),

        // Settle All Button
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmartSettlePage()),
            );
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✨ Settle All with Smart Split',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
