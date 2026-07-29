import 'package:flutter/material.dart';
import 'package:splitico/core/models/expense.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../expense/pages/add_expense_page.dart';
import '../../../core/models/group.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/group_bloc.dart';
import '../bloc/group_state.dart';
import '../bloc/group_event.dart';
import 'create_group_page.dart';

class GroupDetailsPage extends StatelessWidget {
  final GroupModel group;
  const GroupDetailsPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        GroupModel currentGroup = group;
        if (state is GroupsLoaded) {
          currentGroup = state.groups.firstWhere(
            (g) => g.id == group.id,
            orElse: () => group,
          );
        }

        final mediaQuery = MediaQuery.of(context);
        final topPadding = mediaQuery.padding.top;
        final bottomPadding = mediaQuery.padding.bottom;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context).pop({
              'action': 'edit',
              'oldName': group.name,
              'newName': currentGroup.name,
              'category': currentGroup.type,
              'membersCount': currentGroup.members.length,
            });
          },
          child: Scaffold(
            backgroundColor: const Color(
              0xFFF8FAFC,
            ), // soft off-white background
            body: Stack(
              children: [
                // Main scrollable content
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom:
                          100 +
                          bottomPadding, // space for floating bottom action buttons
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Purple Gradient Header
                        _buildGradientHeader(context, topPadding, currentGroup),

                        // 2. Member Chips Section
                        const SizedBox(height: AppSizes.xl),
                        _buildMembersRow(currentGroup),

                        // 3. Expenses Section Header
                        const SizedBox(height: AppSizes.xxl),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.xxl,
                          ),
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
                        _buildExpensesTimeline(currentGroup),
                      ],
                    ),
                  ),
                ),

                // 5. Floating Bottom Action Area
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomActionArea(
                    context,
                    bottomPadding,
                    currentGroup,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientHeader(
    BuildContext context,
    double topPadding,
    GroupModel currentGroup,
  ) {
    String displayName = 'Rahul Kumar';
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      displayName = authState.user!.resolvedDisplayName;
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }

    final totalSpent = currentGroup.expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    double totalYouOwe = 0.0;
    double totalOwedToYou = 0.0;
    double userShare = 0.0;

    for (var expense in currentGroup.expenses) {
      final splitMembers = expense.splitBetween
          .where((m) => m['selected'] == true)
          .toList();

      if (splitMembers.isEmpty) continue;
      final individualShare = expense.amount / splitMembers.length;
      final isPaidByMe = expense.paidBy.toLowerCase() == 'you' ||
          expense.paidBy.toLowerCase() == displayName.toLowerCase();

      final amIInSplit = splitMembers.any(
        (m) => m['name'].toString().toLowerCase() == 'you' ||
               m['name'].toString().toLowerCase() == displayName.toLowerCase(),
      );

      if (amIInSplit) {
        userShare += individualShare;
      }

      if (isPaidByMe) {
        if (amIInSplit) {
          totalOwedToYou += expense.amount - individualShare;
        } else {
          totalOwedToYou += expense.amount;
        }
      } else {
        if (amIInSplit) {
          totalYouOwe += individualShare;
        }
      }
    }

    final netDifference = totalOwedToYou - totalYouOwe;

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
          colors: [Color(0xFF5E5AFA), Color(0xFF4C49ED)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // const SizedBox(height: AppSizes.m),

          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop({
                    'action': 'edit',
                    'oldName': group.name,
                    'newName': currentGroup.name,
                    'category': currentGroup.type,
                    'membersCount': currentGroup.members.length,
                  });
                },
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
                  Text(
                    currentGroup.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CreateGroupPage(groupToEdit: currentGroup),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: Container(
                              padding: const EdgeInsets.all(AppSizes.xl),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF2F2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.l),
                                  const Text(
                                    'Delete Group',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.s),
                                  Text(
                                    'Are you sure you want to delete "${currentGroup.name}"? This action cannot be undone.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.xl),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF64748B,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.m),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            context.read<GroupBloc>().add(
                                              DeleteGroup(currentGroup.id),
                                            );
                                            Navigator.of(context).pop({
                                              'action': 'delete',
                                              'name': currentGroup.name,
                                            });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Group "${currentGroup.name}" deleted successfully',
                                                ),
                                                backgroundColor: const Color(
                                                  0xFFEF4444,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFEF4444,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          child: const Text(
                                            'Yes, Delete',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
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
                  amount: '₹ ${totalSpent.toStringAsFixed(2)}',
                  amountColor: Colors.white,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Your Share',
                  amount: '₹ ${userShare.toStringAsFixed(2)}',
                  amountColor: Colors.white,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: _buildSummaryCard(
                  title: netDifference >= 0 ? 'Owed to You' : 'You Owe',
                  amount: '₹ ${netDifference.abs().toStringAsFixed(2)}',
                  amountColor: netDifference >= 0 ? AppColors.owedAmount : AppColors.oweAmount,
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

  Widget _buildMembersRow(GroupModel currentGroup) {
    final members = currentGroup.members;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
      child: Row(
        children:
            members.map((member) {
              return Container(
                margin: const EdgeInsets.only(right: AppSizes.s + 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                      backgroundColor:
                          (member['avatarBgColor'] ??
                                  member['color'] ??
                                  Colors.deepPurple)
                              as Color,
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

  Widget _buildExpensesTimeline(GroupModel currentGroup) {
    final expenses = List<ExpenseModel>.from(currentGroup.expenses)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No expenses added yet! 💸',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

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
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddExpensePage(
                              isEditing: true,
                              group: currentGroup,
                              expenseToEdit: expense,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.l),
                    padding: const EdgeInsets.all(AppSizes.l),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji
                        Text(
                          expense.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: AppSizes.m),

                        // Title & Subtitle
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
                                '${expense.paidBy} paid • Split ${expense.splitType}',

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

                        // Amount & Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4C49ED),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(expense.dateTime),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionArea(
    BuildContext context,
    double bottomPadding,
    GroupModel currentGroup,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.xxl,
        12,
        AppSizes.xxl,
        bottomPadding > 0 ? bottomPadding : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF8FAFC,
        ).withValues(alpha: 0.9), // soft background blending
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
                    builder: (context) => AddExpensePage(group: currentGroup),
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
}

class _TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;

  _TimelinePainter({required this.isFirst, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
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
    final dotPaint =
        Paint()
          ..color = const Color(0xFF4C49ED)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 6.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
