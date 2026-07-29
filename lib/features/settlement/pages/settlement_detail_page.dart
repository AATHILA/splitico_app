import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/group.dart';
import '../../../core/models/expense.dart';

class SettlementDetailPage extends StatelessWidget {
  final String memberName;
  final double netBalance;
  final String initial;
  final Color avatarColor;
  final List<GroupModel> groups;
  final String currentUserDisplayName;

  const SettlementDetailPage({
    super.key,
    required this.memberName,
    required this.netBalance,
    required this.initial,
    required this.avatarColor,
    required this.groups,
    required this.currentUserDisplayName,
  });

  // Calculate dynamic expense details involving both the user and this member
  List<Map<String, dynamic>> _calculateBreakdown() {
    final List<Map<String, dynamic>> breakdown = [];
    for (var group in groups) {
      for (var expense in group.expenses) {
        final splitMembers =
            expense.splitBetween.where((m) => m['selected'] == true).toList();
        if (splitMembers.isEmpty) continue;

        final individualShare = expense.amount / splitMembers.length;
        final payer = expense.paidBy;
        final isPayerMe =
            payer.toLowerCase() == 'you' ||
            payer.toLowerCase() == currentUserDisplayName.toLowerCase();

        if (isPayerMe) {
          final isMemberInSplit = splitMembers.any(
            (m) =>
                m['name'].toString().toLowerCase() == memberName.toLowerCase(),
          );
          if (isMemberInSplit) {
            breakdown.add({
              'expense': expense,
              'groupName': group.name,
              'isYouPaid': true,
              'shareAmount': individualShare,
            });
          }
        } else if (payer.toLowerCase() == memberName.toLowerCase()) {
          final isMeInSplit = splitMembers.any(
            (m) =>
                m['name'].toString().toLowerCase() == 'you' ||
                m['name'].toString().toLowerCase() ==
                    currentUserDisplayName.toLowerCase(),
          );
          if (isMeInSplit) {
            breakdown.add({
              'expense': expense,
              'groupName': group.name,
              'isYouPaid': false,
              'shareAmount': individualShare,
            });
          }
        }
      }
    }
    return breakdown;
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _calculateBreakdown();
    final isOwed = netBalance > 0.01;
    final primaryGroup =
        breakdown.isNotEmpty ? breakdown.first['groupName'] : 'Group';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top custom header
            _buildAppBar(context),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                children: [
                  const SizedBox(height: AppSizes.m),

                  // 2. Amount Gradient Card
                  _buildAmountCard(isOwed, primaryGroup),
                  const SizedBox(height: AppSizes.l),

                  // 3. Payer-Receiver Visualizer
                  _buildVisualizerCard(isOwed),
                  const SizedBox(height: AppSizes.xl),

                  // 4. Expense Breakdown List
                  if (breakdown.isNotEmpty) ...[
                    const Text(
                      'EXPENSE BREAKDOWN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.m),
                    ...breakdown.map((item) => _buildBreakdownItem(item)),
                    const SizedBox(height: AppSizes.m),

                    // Total Card
                    _buildTotalCard(isOwed),
                    const SizedBox(height: AppSizes.l),
                  ],

                  // 5. Request via section
                  _buildRequestSection(),
                  const SizedBox(height: AppSizes.l),

                  // 6. Safe Area Settlement Banner
                  _buildSettlementBanner(),
                  const SizedBox(height: AppSizes.l),

                  // 7. Mark as Settled Button
                  _buildSettledButton(context),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xxl,
        vertical: AppSizes.m,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1E293B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.m),
          const Text(
            'Settlement detail',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isOwed, String groupName) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.xxl,
        horizontal: AppSizes.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isOwed
                  ? [const Color(0xFF5E5AFA), const Color(0xFF4C49ED)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
      ),
      child: Column(
        children: [
          Text(
            isOwed ? 'AMOUNT TO RECEIVE' : 'AMOUNT TO PAY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${netBalance.abs().toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOwed
                ? '$memberName owes you · $groupName'
                : 'You owe $memberName · $groupName',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerCard(bool isOwed) {
    final payerName = isOwed ? memberName : 'You';
    final payerInitial = isOwed ? initial : 'Y';
    final payerColor = isOwed ? avatarColor : AppColors.primary;

    final receiverName = isOwed ? 'You' : memberName;
    final receiverInitial = isOwed ? 'Y' : initial;
    final receiverColor = isOwed ? AppColors.primary : avatarColor;

    final arrowBgColor = isOwed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final arrowMarkColor = isOwed ? const Color(0xFF059669) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Payer Avatar
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: payerColor,
                child: Text(
                  payerInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                payerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'pays',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Direction Arrow
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: arrowBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: arrowMarkColor,
              size: 20,
            ),
          ),

          // Receiver Avatar
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: receiverColor,
                child: Text(
                  receiverInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                receiverName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'receive',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(Map<String, dynamic> item) {
    final ExpenseModel expense = item['expense'];
    final bool isYouPaid = item['isYouPaid'];
    final double shareAmount = item['shareAmount'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.m),
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.m),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(expense.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: AppSizes.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(expense.dateTime)} · ${isYouPaid ? 'you paid' : '$memberName paid'} · split ${expense.splitType.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${shareAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color:
                      isYouPaid
                          ? AppColors.expensePositive
                          : AppColors.expenseNegative,
                ),
              ),
              Text(
                isYouPaid ? 'her share' : 'your share',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(bool isOwed) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E0FF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOwed ? 'Total $memberName owes you' : 'Total you owe $memberName',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            '₹${netBalance.abs().toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REQUEST VIA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShareOption('🟢', 'WhatsApp'),
            _buildShareOption('✉️', 'Email'),
            _buildShareOption('🔗', 'Copy link'),
            _buildShareOption('📤', 'More'),
          ],
        ),
      ],
    );
  }

  Widget _buildShareOption(String icon, String label) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementBanner() {
    final isOwed = netBalance > 0.01;
    final bannerBg = isOwed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final bannerBorder = isOwed ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);
    final iconColor = isOwed ? const Color(0xFF059669) : const Color(0xFFEF4444);
    final textColor = isOwed ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    final bannerText = isOwed
        ? 'Once $memberName pays, tap below to mark as settled.'
        : 'After paying, mark as settled, so $memberName is notified.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettledButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settlement with $memberName marked as settled! 🎉'),
            backgroundColor: AppColors.expensePositive,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 2,
        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'Mark as settled',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
