import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/group.dart';
import '../../../core/models/expense.dart';
import '../../../core/services/upi_payment_service.dart';

class SettlementDetailPage extends StatefulWidget {
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

  @override
  State<SettlementDetailPage> createState() => _SettlementDetailPageState();
}

class _SettlementDetailPageState extends State<SettlementDetailPage> {
  bool _isSettled = false;

  String? get _memberUpiId {
    for (final group in widget.groups) {
      for (final m in group.members) {
        if (m['name'].toString().toLowerCase() ==
            widget.memberName.toLowerCase()) {
          final upi = m['upiId']?.toString().trim();
          if (upi != null && upi.isNotEmpty) {
            return upi;
          }
        }
      }
    }
    return null;
  }

  // Calculate dynamic expense details involving both the user and this member
  List<Map<String, dynamic>> _calculateBreakdown() {
    final List<Map<String, dynamic>> breakdown = [];
    for (var group in widget.groups) {
      for (var expense in group.expenses) {
        final splitMembers =
            expense.splitBetween.where((m) => m['selected'] == true).toList();
        if (splitMembers.isEmpty) continue;

        final individualShare = expense.amount / splitMembers.length;
        final payer = expense.paidBy;
        final isPayerMe =
            payer.toLowerCase() == 'you' ||
            payer.toLowerCase() == widget.currentUserDisplayName.toLowerCase();

        if (isPayerMe) {
          final isMemberInSplit = splitMembers.any(
            (m) =>
                m['name'].toString().toLowerCase() ==
                widget.memberName.toLowerCase(),
          );
          if (isMemberInSplit) {
            breakdown.add({
              'expense': expense,
              'groupName': group.name,
              'isYouPaid': true,
              'shareAmount': individualShare,
            });
          }
        } else if (payer.toLowerCase() == widget.memberName.toLowerCase()) {
          final isMeInSplit = splitMembers.any(
            (m) =>
                m['name'].toString().toLowerCase() == 'you' ||
                m['name'].toString().toLowerCase() ==
                    widget.currentUserDisplayName.toLowerCase(),
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

  Future<void> _shareViaWhatsApp(String primaryGroup) async {
    final amount = widget.netBalance.abs().toStringAsFixed(0);
    final text =
        'Hi ${widget.memberName}, friendly reminder to settle the pending balance of ₹$amount for $primaryGroup on Splitico. Thanks!';
    final encoded = Uri.encodeComponent(text);

    final appUri = Uri.parse('whatsapp://send?text=$encoded');
    final webUri = Uri.parse('https://wa.me/?text=$encoded');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        _copyReminderText(primaryGroup);
      }
    } catch (_) {
      _copyReminderText(primaryGroup);
    }
  }

  Future<void> _shareViaEmail(String primaryGroup) async {
    final amount = widget.netBalance.abs().toStringAsFixed(0);
    final subject = 'Splitico: Payment reminder for $primaryGroup';
    final body =
        'Hi ${widget.memberName},\n\nThis is a friendly reminder to settle your pending share of ₹$amount for $primaryGroup on Splitico.\n\nThank you!';

    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyReminderText(primaryGroup);
      }
    } catch (_) {
      _copyReminderText(primaryGroup);
    }
  }

  Future<void> _shareViaSms(String primaryGroup) async {
    final amount = widget.netBalance.abs().toStringAsFixed(0);
    final body =
        'Hi ${widget.memberName}, friendly reminder to settle the balance of ₹$amount for $primaryGroup on Splitico. Thanks!';

    final uri = Uri(
      scheme: 'sms',
      queryParameters: {'body': body},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyReminderText(primaryGroup);
      }
    } catch (_) {
      _copyReminderText(primaryGroup);
    }
  }

  void _copyReminderText(String primaryGroup) {
    final amount = widget.netBalance.abs().toStringAsFixed(0);
    final text =
        'Hi ${widget.memberName}, friendly reminder to settle the pending balance of ₹$amount for $primaryGroup on Splitico. Thanks!';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder message copied to clipboard! 📋'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final breakdown = _calculateBreakdown();
    final isOwed = widget.netBalance > 0.01;
    final primaryGroup =
        breakdown.isNotEmpty ? breakdown.first['groupName'] : 'Group';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top custom header
            _buildAppBar(context, isDarkMode),

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
                  _buildVisualizerCard(context, isOwed, isDarkMode),
                  const SizedBox(height: AppSizes.xl),

                  // 4. Expense Breakdown List
                  if (breakdown.isNotEmpty) ...[
                    Text(
                      'EXPENSE BREAKDOWN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                            isDarkMode
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.m),
                    ...breakdown.map(
                      (item) => _buildBreakdownItem(context, item, isDarkMode),
                    ),
                    const SizedBox(height: AppSizes.m),

                    // Total Card
                    _buildTotalCard(isOwed, isDarkMode),
                    const SizedBox(height: AppSizes.l),
                  ],

                  // 5. Request via section (ONLY if member owes the user)
                  if (isOwed && !_isSettled) ...[
                    _buildRequestSection(context, isDarkMode, primaryGroup),
                    const SizedBox(height: AppSizes.l),
                  ],

                  // 6. Settlement Info Banner
                  _buildSettlementBanner(isDarkMode, isOwed),
                  const SizedBox(height: AppSizes.l),

                  // 7. Settlement Action Buttons (Pay / Mark as Settled)
                  _buildActionButtons(context, isOwed),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
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
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.m),
          Text(
            'Settlement detail',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
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
              _isSettled
                  ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                  : isOwed
                  ? [const Color(0xFF5E5AFA), const Color(0xFF4C49ED)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
      ),
      child: Column(
        children: [
          Text(
            _isSettled
                ? 'ALL SETTLED'
                : (isOwed ? 'AMOUNT TO RECEIVE' : 'AMOUNT TO PAY'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.netBalance.abs().toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSettled
                ? 'Settlement completed with ${widget.memberName} ✓'
                : (isOwed
                    ? '${widget.memberName} owes you · $groupName'
                    : 'You owe ${widget.memberName} · $groupName'),
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

  Widget _buildVisualizerCard(
    BuildContext context,
    bool isOwed,
    bool isDarkMode,
  ) {
    final payerName = isOwed ? widget.memberName : 'You';
    final payerInitial = isOwed ? widget.initial : 'Y';
    final payerColor = isOwed ? widget.avatarColor : AppColors.primary;

    final receiverName = isOwed ? 'You' : widget.memberName;
    final receiverInitial = isOwed ? 'Y' : widget.initial;
    final receiverColor = isOwed ? AppColors.primary : widget.avatarColor;

    final arrowBgColor =
        _isSettled
            ? (isDarkMode
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                : const Color(0xFFEFF6FF))
            : isOwed
            ? (isDarkMode
                ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                : const Color(0xFFECFDF5))
            : (isDarkMode
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
                : const Color(0xFFFEF2F2));

    final arrowMarkColor =
        _isSettled
            ? AppColors.primary
            : isOwed
            ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
            : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                'pays',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                'receive',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDarkMode,
  ) {
    final ExpenseModel expense = item['expense'];
    final bool isYouPaid = item['isYouPaid'];
    final double shareAmount = item['shareAmount'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.m),
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.m),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(expense.dateTime)} · ${isYouPaid ? 'you paid' : '${widget.memberName} paid'} · split ${expense.splitType.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        isDarkMode
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
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
                          ? (isDarkMode
                              ? const Color(0xFF34D399)
                              : AppColors.expensePositive)
                          : (isDarkMode
                              ? const Color(0xFFF87171)
                              : AppColors.expenseNegative),
                ),
              ),
              Text(
                isYouPaid ? 'her share' : 'your share',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(bool isOwed, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.l),
      decoration: BoxDecoration(
        color:
            isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkMode ? const Color(0xFF334155) : const Color(0xFFD3E0FF),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isOwed
                ? 'Total ${widget.memberName} owes you'
                : 'Total you owe ${widget.memberName}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? const Color(0xFF818CF8) : AppColors.primary,
            ),
          ),
          Text(
            '₹${widget.netBalance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? const Color(0xFF818CF8) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Request via WhatsApp / Email / SMS / Copy Note
  /// ONLY displayed when a member owes the current user
  Widget _buildRequestSection(
    BuildContext context,
    bool isDarkMode,
    String primaryGroup,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REQUEST VIA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color:
                isDarkMode
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShareOption(
              context: context,
              icon: const _WhatsAppIcon(size: 26),
              label: 'WhatsApp',
              isDarkMode: isDarkMode,
              onTap: () => _shareViaWhatsApp(primaryGroup),
            ),
            _buildShareOption(
              context: context,
              icon: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA4335),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              label: 'Email',
              isDarkMode: isDarkMode,
              onTap: () => _shareViaEmail(primaryGroup),
            ),
            _buildShareOption(
              context: context,
              icon: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF0284C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              label: 'Text / SMS',
              isDarkMode: isDarkMode,
              onTap: () => _shareViaSms(primaryGroup),
            ),
            _buildShareOption(
              context: context,
              icon: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              label: 'Copy Note',
              isDarkMode: isDarkMode,
              onTap: () => _copyReminderText(primaryGroup),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required Widget icon,
    required String label,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 28,
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color:
                    isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementBanner(bool isDarkMode, bool isOwed) {
    if (_isSettled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                  : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDarkMode
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFBFDBFE),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This settlement has been recorded as paid and settled! 🎉',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bannerBg =
        isOwed
            ? (isDarkMode
                ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                : const Color(0xFFECFDF5))
            : (isDarkMode
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                : const Color(0xFFFEF2F2));
    final bannerBorder =
        isOwed
            ? (isDarkMode ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
            : (isDarkMode ? const Color(0xFF991B1B) : const Color(0xFFFECACA));
    final iconColor =
        isOwed
            ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
            : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444));
    final textColor =
        isOwed
            ? (isDarkMode ? const Color(0xFFA7F3D0) : const Color(0xFF065F46))
            : (isDarkMode ? const Color(0xFFFECACA) : const Color(0xFF991B1B));
    final bannerText =
        isOwed
            ? 'Once ${widget.memberName} pays, tap below to mark as settled.'
            : 'After paying, mark as settled, so ${widget.memberName} is notified.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: iconColor, size: 20),
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

  Widget _buildActionButtons(BuildContext context, bool isOwed) {
    if (_isSettled) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        label: const Text(
          'Paid ✓',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    final amount = widget.netBalance.abs();

    if (!isOwed) {
      // User owes this member -> Provide Pay and Mark Paid actions
      return Row(
        children: [
          // Pay Button (UPI / Bank / GPay)
          Expanded(
            flex: 6,
            child: ElevatedButton.icon(
              onPressed: () {
                UpiPaymentService.showPaymentMethodBottomSheet(
                  context: context,
                  name: widget.memberName,
                  amount: amount,
                  upiId: _memberUpiId ?? 'splitico@upi',
                  onSettled: () {
                    setState(() {
                      _isSettled = true;
                    });
                  },
                );
              },
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: Text(
                'Pay ₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Mark Paid Button
          Expanded(
            flex: 5,
            child: OutlinedButton(
              onPressed: () {
                UpiPaymentService.showMarkPaidBottomSheet(
                  context: context,
                  name: widget.memberName,
                  amount: amount,
                  onSettled: () {
                    setState(() {
                      _isSettled = true;
                    });
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Mark Paid',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    // Member owes user -> Mark as Settled button
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isSettled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settlement with ${widget.memberName} marked as settled! 🎉',
            ),
            backgroundColor: AppColors.expensePositive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'Mark as Settled ✓',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Authentic WhatsApp Icon with official green bubble tail & telephone handset
class _WhatsAppIcon extends StatelessWidget {
  final double size;
  const _WhatsAppIcon({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _WhatsAppBubblePainter(),
          ),
          Transform.rotate(
            angle: -0.15,
            child: Icon(
              Icons.phone,
              color: Colors.white,
              size: size * 0.52,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw main circular speech bubble
    final path = Path();
    final center = Offset(w * 0.5, h * 0.48);
    final radius = w * 0.44;

    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Speech bubble tail pointing bottom-left
    path.moveTo(w * 0.22, h * 0.68);
    path.lineTo(w * 0.08, h * 0.90);
    path.lineTo(w * 0.38, h * 0.82);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
