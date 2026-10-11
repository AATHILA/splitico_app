import 'dart:math' as math;
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
enum CategoryChartType { donut, bar, list }

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.allTime;
  CategoryChartType _chartType = CategoryChartType.donut;
  String? _selectedCategory;

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        style: TextStyle(
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 14,
                        ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Simple overview of your shared spending',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.primary.withValues(alpha: 0.15)
                : const Color(0xFFEEF2FF),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
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
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryOverview(List<ExpenseModel> expenses, String displayName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final mutedText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
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
                    Text(
                      'YOUR SHARE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${yourShare.toStringAsFixed(yourShare % 1 == 0 ? 0 : 2)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: borderColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL GROUP BILLS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
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
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Bottom status summary badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isNetPositive
                  ? (isDarkMode ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                  : (isDarkMode ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEF2F2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isNetPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 18,
                  color: isNetPositive
                      ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                      : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
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
                      color: isNetPositive
                          ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                          : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final Map<String, double> categoryTotals = {};
    double totalSpend = 0.0;

    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      totalSpend += expense.amount;
    }

    final sortedList = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build chart data items with angles
    final double totalGap = sortedList.length > 1 ? sortedList.length * 0.04 : 0.0;
    final double availableSweep = (2 * math.pi) - totalGap;
    double currentAngle = -math.pi / 2;

    final List<_CategoryChartData> chartItems = [];
    for (var entry in sortedList) {
      final category = entry.key;
      final amount = entry.value;
      final percent = totalSpend > 0 ? (amount / totalSpend) : 0.0;
      final sweep = percent * availableSweep;
      chartItems.add(_CategoryChartData(
        category: category,
        amount: amount,
        percentage: percent,
        color: _getCategoryColor(category),
        emoji: _getCategoryEmoji(category),
        startAngle: currentAngle,
        sweepAngle: sweep,
      ));
      currentAngle += sweep + (sortedList.length > 1 ? 0.04 : 0.0);
    }

    final topCategory = sortedList.first;
    final topPercent = totalSpend > 0 ? (topCategory.value / totalSpend * 100).toStringAsFixed(0) : '0';
    final topEmoji = _getCategoryEmoji(topCategory.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with View Mode Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Where your money went',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            _buildChartTypeToggle(),
          ],
        ),
        const SizedBox(height: AppSizes.s),
        // Top highlight banner
        Container(
          margin: const EdgeInsets.only(bottom: AppSizes.m),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getCategoryColor(topCategory.key).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _getCategoryColor(topCategory.key).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Text(topEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Largest spend: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                    children: [
                      TextSpan(
                        text: '${topCategory.key} ($topPercent% of total)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _getCategoryColor(topCategory.key),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Chart / Visual Content Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.l),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildSelectedChartView(chartItems, sortedList, totalSpend),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeToggle() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartTypeOption(
            type: CategoryChartType.donut,
            icon: Icons.pie_chart_rounded,
            tooltip: 'Donut Chart',
          ),
          _buildChartTypeOption(
            type: CategoryChartType.bar,
            icon: Icons.bar_chart_rounded,
            tooltip: 'Bar Diagram',
          ),
          _buildChartTypeOption(
            type: CategoryChartType.list,
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'List View',
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeOption({
    required CategoryChartType type,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = _chartType == type;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _chartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 17,
          color: isSelected
              ? AppColors.primary
              : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildSelectedChartView(
    List<_CategoryChartData> chartItems,
    List<MapEntry<String, double>> sortedList,
    double totalSpend,
  ) {
    switch (_chartType) {
      case CategoryChartType.donut:
        return _buildDonutChartView(chartItems, totalSpend);
      case CategoryChartType.bar:
        return _buildBarChartView(chartItems, totalSpend);
      case CategoryChartType.list:
        return _buildListBreakdownView(sortedList, totalSpend);
    }
  }

  Widget _buildDonutChartView(List<_CategoryChartData> chartItems, double totalSpend) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    _CategoryChartData? selectedItem;
    if (_selectedCategory != null) {
      try {
        selectedItem = chartItems.firstWhere((e) => e.category == _selectedCategory);
      } catch (_) {
        selectedItem = null;
      }
    }

    return Column(
      key: const ValueKey('donut_view'),
      children: [
        // Donut Chart with Interactive Tap & Center Info
        Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: GestureDetector(
              onTapUp: (details) => _handleDonutTap(details.localPosition, const Size(190, 190), chartItems),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(190, 190),
                    painter: _DonutChartPainter(
                      items: chartItems,
                      selectedCategory: _selectedCategory,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  // Center Info Hole
                  GestureDetector(
                    onTap: () {
                      if (_selectedCategory != null) {
                        setState(() => _selectedCategory = null);
                      }
                    },
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (selectedItem?.color ?? AppColors.primary).withValues(alpha: isDarkMode ? 0.2 : 0.08),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selectedItem != null) ...[
                            Text(selectedItem.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(
                              selectedItem.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: mutedText,
                              ),
                            ),
                            Text(
                              '₹${selectedItem.amount.toStringAsFixed(selectedItem.amount % 1 == 0 ? 0 : 2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${(selectedItem.percentage * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: selectedItem.color,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'TOTAL SPEND',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${totalSpend.toStringAsFixed(totalSpend % 1 == 0 ? 0 : 2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${chartItems.length} categories',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Tap any slice or category below to inspect details',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: borderColor),
        const SizedBox(height: 12),
        // Interactive Category Legend List
        ...chartItems.map((item) {
          final isSelected = _selectedCategory == item.category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : item.category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? item.color.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? item.color.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(item.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(item.percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₹${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _handleDonutTap(Offset localPosition, Size size, List<_CategoryChartData> chartItems) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final baseRadius = math.min(size.width, size.height) / 2 * 0.88;
    const strokeWidth = 26.0;
    final innerRadius = baseRadius - (strokeWidth / 2);
    final outerRadius = baseRadius + (strokeWidth / 2);

    if (dist < innerRadius - 10) {
      if (_selectedCategory != null) {
        setState(() => _selectedCategory = null);
      }
      return;
    }

    if (dist >= innerRadius - 15 && dist <= outerRadius + 20) {
      final rawAngle = math.atan2(dy, dx);
      double angle = rawAngle - (-math.pi / 2);
      while (angle < 0) {
        angle += 2 * math.pi;
      }
      while (angle >= 2 * math.pi) {
        angle -= 2 * math.pi;
      }

      double currentNormalizedStart = 0.0;
      for (var item in chartItems) {
        final sweepWithGap = item.sweepAngle + (chartItems.length > 1 ? 0.04 : 0.0);
        if (angle >= currentNormalizedStart && angle <= currentNormalizedStart + sweepWithGap) {
          setState(() {
            if (_selectedCategory == item.category) {
              _selectedCategory = null;
            } else {
              _selectedCategory = item.category;
            }
          });
          return;
        }
        currentNormalizedStart += sweepWithGap;
      }
    }
  }

  Widget _buildBarChartView(List<_CategoryChartData> chartItems, double totalSpend) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double maxAmount = chartItems.map((e) => e.amount).fold(0.0, math.max);

    _CategoryChartData? selectedItem;
    if (_selectedCategory != null) {
      try {
        selectedItem = chartItems.firstWhere((e) => e.category == _selectedCategory);
      } catch (_) {
        selectedItem = null;
      }
    }

    final barWidgets = chartItems.map((item) {
      final isSelected = _selectedCategory == item.category;
      final heightFraction = maxAmount > 0 ? (item.amount / maxAmount) : 0.0;
      final barHeight = (heightFraction * 85).clamp(10.0, 85.0);

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = isSelected ? null : item.category;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Percentage / Amount on top of bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color
                      : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(item.percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Bar Column Track
              Container(
                width: 38,
                height: 85,
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 38,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        item.color,
                        item.color.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                      bottom: Radius.circular(4),
                    ),
                    border: isSelected
                        ? Border.all(color: isDarkMode ? const Color(0xFF334155) : Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Category Emoji
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 4),
              // Category Name
              SizedBox(
                width: 56,
                child: Text(
                  item.category,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? item.color
                        : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Column(
      key: const ValueKey('bar_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar diagram container with horizontal scroll support and zero vertical overflow
        SizedBox(
          height: 180,
          child: chartItems.length <= 4
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: barWidgets,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barWidgets,
                  ),
                ),
        ),
        const SizedBox(height: 14),
        // Selected Bar details card or guide
        if (selectedItem != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selectedItem.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedItem.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Text(selectedItem.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedItem.category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${(selectedItem.percentage * 100).toStringAsFixed(1)}% of total spend',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selectedItem.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${selectedItem.amount.toStringAsFixed(selectedItem.amount % 1 == 0 ? 0 : 2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          )
        else
          Center(
            child: Text(
              'Tap any bar to inspect amount and details',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListBreakdownView(
    List<MapEntry<String, double>> sortedList,
    double totalSpend,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('list_view'),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
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
                  Text(
                    '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupSpendingSection(List<Map<String, dynamic>> items, String displayName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

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
        Text(
          'Spending by Group',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Container(
          padding: const EdgeInsets.all(AppSizes.l),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
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
                        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getGroupIcon(type),
                        size: 18,
                        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

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
        Text(
          'Who Paid',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSizes.m),
        Container(
          padding: const EdgeInsets.all(AppSizes.l),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
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
                      backgroundColor: isMe
                          ? AppColors.primary
                          : (isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 36,
            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'No expenses recorded for this month',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Switch to "All Time" to view your total analytics.',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                color: isDarkMode
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: AppSizes.l),
            Text(
              'No Expenses Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add expenses in your groups to see your spending breakdown here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
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

class _CategoryChartData {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final String emoji;
  final double startAngle;
  final double sweepAngle;

  const _CategoryChartData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.emoji,
    required this.startAngle,
    required this.sweepAngle,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_CategoryChartData> items;
  final String? selectedCategory;
  final bool isDarkMode;

  _DonutChartPainter({
    required this.items,
    this.selectedCategory,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 * 0.88;
    const strokeWidth = 24.0;

    // Subtle background track ring
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, baseRadius, bgPaint);

    for (var item in items) {
      final isSelected = item.category == selectedCategory;
      final radius = isSelected ? baseRadius + 4 : baseRadius;
      final itemStrokeWidth = isSelected ? strokeWidth + 6 : strokeWidth;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = itemStrokeWidth
        ..strokeCap = StrokeCap.round;

      if (isSelected) {
        // Draw glowing effect behind selected slice
        final glowPaint = Paint()
          ..color = item.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = itemStrokeWidth + 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          item.startAngle,
          math.max(0.01, item.sweepAngle),
          false,
          glowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        item.startAngle,
        math.max(0.01, item.sweepAngle),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.items != items ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
