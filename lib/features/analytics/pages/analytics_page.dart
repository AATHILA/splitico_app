import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/group.dart';
import '../../../core/models/expense.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../group/bloc/group_bloc.dart';
import '../../group/bloc/group_state.dart';

enum AnalyticsPeriod { thisMonth, allTime }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.allTime;

  List<ExpenseModel> _filterExpensesByPeriod(List<ExpenseModel> allExpenses) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case AnalyticsPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return allExpenses.where((e) => e.dateTime.isAfter(startOfMonth)).toList();
      case AnalyticsPeriod.allTime:
        return allExpenses;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFEF4444);
      case 'transport':
        return const Color(0xFF3B82F6);
      case 'stay':
        return const Color(0xFFF59E0B);
      case 'activity':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍽️';
      case 'transport':
        return '🚗';
      case 'stay':
        return '🏨';
      case 'activity':
        return '🎯';
      default:
        return '💸';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String displayName = 'You';
            if (authState is AuthAuthenticated && authState.user != null) {
              displayName = authState.user!.resolvedDisplayName;
              if (displayName.isNotEmpty) {
                displayName = displayName[0].toUpperCase() + displayName.substring(1);
              }
            }

            return BlocBuilder<GroupBloc, GroupState>(
              builder: (context, groupState) {
                if (groupState is GroupsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (groupState is GroupsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xxl),
                      child: Text(
                        'Unable to load analytics: ${groupState.message}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ),
                  );
                }

                List<GroupModel> groups = [];
                if (groupState is GroupsLoaded) {
                  groups = groupState.groups;
                }

                final List<Map<String, dynamic>> allExpenseItems = [];
                for (var group in groups) {
                  for (var expense in group.expenses) {
                    allExpenseItems.add({'group': group, 'expense': expense});
                  }
                }

                final filteredItems = allExpenseItems.where((item) {
                  final expense = item['expense'] as ExpenseModel;
                  return _filterExpensesByPeriod([expense]).isNotEmpty;
                }).toList();

                final filteredExpenses = filteredItems.map((e) => e['expense'] as ExpenseModel).toList();

                if (allExpenseItems.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSizes.xxl, AppSizes.l, AppSizes.xxl, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSizes.l),
                      _buildPeriodToggle(),
                      const SizedBox(height: AppSizes.xl),
                      if (filteredExpenses.isEmpty)
                        _buildNoDataForPeriod()
                      else ...[
                        _buildSummaryOverview(filteredExpenses, displayName),
                        const SizedBox(height: AppSizes.xxl),
                        _buildCategorySection(filteredExpenses),
                        const SizedBox(height: AppSizes.xxl),
                        _buildGroupSpendingSection(filteredItems, displayName),
                        const SizedBox(height: AppSizes.xxl),
                        _buildWhoPaidSection(filteredExpenses, displayName),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Simple overview of your shared spending',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.pie_chart_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildToggleItem('All Time', AnalyticsPeriod.allTime),
          _buildToggleItem('This Month', AnalyticsPeriod.thisMonth),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, AnalyticsPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryOverview(List<ExpenseModel> expenses, String displayName) {
    double totalGroupVolume = 0.0;
    double youPaid = 0.0;
    double yourShare = 0.0;

    for (var expense in expenses) {
      totalGroupVolume += expense.amount;

      final isPaidByMe = expense.paidBy.toLowerCase() == 'you' ||
          expense.paidBy.toLowerCase() == displayName.toLowerCase();

      if (isPaidByMe) {
        youPaid += expense.amount;
      }

      final splitMembers = expense.splitBetween.where((m) => m['selected'] == true).toList();
      if (splitMembers.isNotEmpty) {
        final share = expense.amount / splitMembers.length;
        final amIInSplit = splitMembers.any(
          (m) =>
              m['name'].toString().toLowerCase() == 'you' ||
              m['name'].toString().toLowerCase() == displayName.toLowerCase(),
        );
        if (amIInSplit) {
          yourShare += share;
        }
      }
    }

    final netDifference = youPaid - yourShare;
    final isNetPositive = netDifference >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Your Share vs Total Group Spend
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR SHARE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${yourShare.toStringAsFixed(yourShare % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL GROUP BILLS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalGroupVolume.toStringAsFixed(totalGroupVolume % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Bottom status summary badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isNetPositive
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isNetPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 18,
                  color: isNetPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNetPositive
                        ? 'You paid ₹${youPaid.toStringAsFixed(0)} (You get back ₹${netDifference.toStringAsFixed(0)})'
                        : 'You paid ₹${youPaid.toStringAsFixed(0)} (You owe ₹${netDifference.abs().toStringAsFixed(0)})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isNetPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(List<ExpenseModel> expenses) {
    final Map<String, double> categoryTotals = {};
    double totalSpend = 0.0;

    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      totalSpend += expense.amount;
    }

    final sortedList = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where your money went',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Container(
          padding: const EdgeInsets.all(AppSizes.l),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: sortedList.map((entry) {
              final category = entry.key;
              final amount = entry.value;
              final percent = totalSpend > 0 ? (amount / totalSpend) : 0.0;
              final color = _getCategoryColor(category);
              final emoji = _getCategoryEmoji(category);
              final isLast = sortedList.indexOf(entry) == sortedList.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        // Name and percentage
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(percent * 100).toStringAsFixed(0)}% of total',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Total Amount
                        Text(
                          '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Visual progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSpendingSection(List<Map<String, dynamic>> items, String displayName) {
    final Map<String, double> groupTotals = {};
    final Map<String, String> groupTypes = {};
    for (var item in items) {
      final group = item['group'] as GroupModel;
      final expense = item['expense'] as ExpenseModel;
      groupTotals[group.name] = (groupTotals[group.name] ?? 0) + expense.amount;
      groupTypes[group.name] = group.type;
    }

    final sortedGroups = groupTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedGroups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Group',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Container(
          padding: const EdgeInsets.all(AppSizes.l),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: sortedGroups.map((entry) {
              final groupName = entry.key;
              final amount = entry.value;
              final type = groupTypes[groupName] ?? 'Friends';
              final isLast = sortedGroups.indexOf(entry) == sortedGroups.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getGroupIcon(type), size: 18, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWhoPaidSection(List<ExpenseModel> expenses, String displayName) {
    final Map<String, double> payerTotals = {};

    for (var expense in expenses) {
      final payer = expense.paidBy;
      payerTotals[payer] = (payerTotals[payer] ?? 0) + expense.amount;
    }

    final sortedPayers = payerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who Paid',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Container(
          padding: const EdgeInsets.all(AppSizes.l),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: sortedPayers.map((entry) {
              final name = entry.key;
              final amount = entry.value;
              final isMe = name.toLowerCase() == 'you' || name.toLowerCase() == displayName.toLowerCase();
              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
              final isLast = sortedPayers.indexOf(entry) == sortedPayers.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isMe ? AppColors.primary : const Color(0xFF94A3B8),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMe ? '$name (You)' : name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataForPeriod() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.calendar_today_rounded, size: 36, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No expenses recorded for this month',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Switch to "All Time" to view your total analytics.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: AppSizes.l),
            const Text(
              'No Expenses Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add expenses in your groups to see your spending breakdown here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Home':
        return Icons.home_rounded;
      case 'Friends':
        return Icons.people_rounded;
      case 'Family':
        return Icons.family_restroom_rounded;
      default:
        return Icons.group_rounded;
    }
  }
}
