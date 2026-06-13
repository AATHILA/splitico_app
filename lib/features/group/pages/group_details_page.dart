import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../expense/pages/add_expense_page.dart';

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft off-white background
      body: Stack(
        children: [
          // Main scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 100 + bottomPadding, // space for floating bottom action buttons
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Purple Gradient Header
                  _buildGradientHeader(context, topPadding),

                  // 2. Member Chips Section
                  const SizedBox(height: AppSizes.xl),
                  _buildMembersRow(),

                  // 3. Expenses Section Header
                  const SizedBox(height: AppSizes.xxl),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                    child: Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.l),

                  // 4. Expenses Timeline List
                  _buildExpensesTimeline(),
                ],
              ),
            ),
          ),

          // 5. Floating Bottom Action Area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionArea(context, bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.xxl,
        topPadding + AppSizes.s,
        AppSizes.xxl,
        AppSizes.xxl + 4,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5E5AFA),
            Color(0xFF4C49ED),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone top indicators (9:41, Actions)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '9:41',
                style: TextStyle(
                  color: Colors.white,
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 14,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.m),

          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Title with icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.upload_rounded, // Matches the reference design icon
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppSizes.s),
                  const Text(
                    'Goa Trip 2024',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Menu Icon (...)
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                color: Colors.white,
                iconSize: 24,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Spent',
                  amount: '₹14,800',
                  amountColor: Colors.white,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Your Share',
                  amount: '₹3,700',
                  amountColor: Colors.white,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: _buildSummaryCard(
                  title: 'You Owe',
                  amount: '₹1,240',
                  amountColor: const Color(0xFFFFA726), // warm orange/peach
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersRow() {
    final members = [
      {'name': 'Athila', 'initial': 'A', 'color': const Color(0xFF7C3AED)},
      {'name': 'Riya', 'initial': 'R', 'color': const Color(0xFFEC4899)},
      {'name': 'Kiran', 'initial': 'K', 'color': const Color(0xFF10B981)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
      child: Row(
        children: members.map((member) {
          return Container(
            margin: const EdgeInsets.only(right: AppSizes.s + 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: member['color'] as Color,
                  child: Text(
                    member['initial'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.s),
                Text(
                  member['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpensesTimeline() {
    final expenses = [
      {
        'title': 'Dinner at Spice Garden',
        'subtitle': 'Arjun paid • Split equally',
        'emoji': '🍽️',
        'amount': '₹2,400',
      },
      {
        'title': 'Hotel Checkout',
        'subtitle': 'Rahul paid • Split equally',
        'emoji': '🏨',
        'amount': '₹4,200',
      },
      {
        'title': 'Ferry Tickets',
        'subtitle': 'Kiran paid • Custom',
        'emoji': '🚢',
        'amount': '₹800',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final isFirst = index == 0;
        final isLast = index == expenses.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline vertical line & dot
              CustomPaint(
                size: const Size(24, double.infinity),
                painter: _TimelinePainter(isFirst: isFirst, isLast: isLast),
              ),
              const SizedBox(width: AppSizes.s),

              // Expense Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.l),
                  padding: const EdgeInsets.all(AppSizes.l),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji
                      Text(
                        expense['emoji']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: AppSizes.m),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['title']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expense['subtitle']!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.s),

                      // Amount
                      Text(
                        expense['amount']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4C49ED),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionArea(BuildContext context, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.xxl,
        12,
        AppSizes.xxl,
        bottomPadding > 0 ? bottomPadding : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withValues(alpha: 0.9), // soft background blending
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8FAFC).withValues(alpha: 0.0),
            const Color(0xFFF8FAFC).withValues(alpha: 0.95),
            const Color(0xFFF8FAFC),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Row(
        children: [
          // "+ Add Expense" Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpensePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '+ Add Expense',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.m),

          // "Settle Up ✓" Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settle Up clicked!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCFCE7), // light green
                foregroundColor: const Color(0xFF065F46), // dark green text
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Settle Up ✓',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;

  _TimelinePainter({required this.isFirst, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    // Align dot center to roughly match the emoji/first line center inside the card
    // In our card design, the padding is 16 and text is size 20, so center aligns to roughly 26px down
    const dotCenterY = 26.0;

    final topPoint = Offset(centerX, 0);
    final bottomPoint = Offset(centerX, size.height);
    final centerPoint = Offset(centerX, dotCenterY);

    if (isFirst && isLast) {
      // No lines, just dot
    } else if (isFirst) {
      canvas.drawLine(centerPoint, bottomPoint, paint);
    } else if (isLast) {
      canvas.drawLine(topPoint, centerPoint, paint);
    } else {
      canvas.drawLine(topPoint, bottomPoint, paint);
    }

    // Draw the purple dot
    final dotPaint = Paint()
      ..color = const Color(0xFF4C49ED)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 6.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
